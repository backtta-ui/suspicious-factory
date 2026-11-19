#!/usr/bin/env python3
"""Finalise the CI build for installation on the user's phone.

The workflow compiles with a disposable CI key (no repository secret is set), then this
step used to strip every signature so the artifact was not installable. From 2.0.27 it
re-signs with the key stored at `.ci/pickle-debug.keystore` (alias `androiddebugkey`,
password `android`) when that file is present, verifies the result, and refreshes
`apk-verification.json`, `apk-verification.txt` and `SHA256SUMS.txt`.

Without that key it keeps the old behaviour: strip the disposable signature and publish
the unsigned intermediate for private signing.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile

BUILD_TOOLS_VERSION = "36.0.0"
REPO = Path(__file__).resolve().parents[1]
KEYSTORE = REPO / ".ci" / "pickle-debug.keystore"
KEY_ALIAS = "androiddebugkey"
STORE_PASS = "android"
KEY_PASS = "android"


def find_build_tools() -> Path:
    explicit = os.environ.get("WOO_BUILD_TOOLS")
    if explicit and Path(explicit).is_dir():
        return Path(explicit)
    sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT") or ""
    if sdk:
        candidates = sorted((Path(sdk) / "build-tools").glob("*"), reverse=True)
        for candidate in candidates:
            if (candidate / "apksigner").exists():
                return candidate
        preferred = Path(sdk) / "build-tools" / BUILD_TOOLS_VERSION
        if preferred.is_dir():
            return preferred
    for name in ["apksigner", "zipalign"]:
        found = shutil.which(name)
        if found:
            return Path(found).resolve().parent
    return Path("")


def strip_signatures(source: Path, target: Path) -> None:
    with zipfile.ZipFile(source) as src, zipfile.ZipFile(target, "w") as out:
        for item in src.infolist():
            if re.match(r"^META-INF/(MANIFEST\.MF|[^/]+\.(SF|RSA|DSA|EC))$", item.filename, re.I):
                continue
            # Rebuilding the ZIP also drops the v2/v3 APK Signing Block outside ZIP entries.
            out.writestr(item, src.read(item.filename))
    with zipfile.ZipFile(target) as check:
        if check.testzip() is not None:
            raise SystemExit("Unsigned intermediate ZIP corrupt")


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO / "builds"
    report_path = root / "apk-verification.json"
    if not report_path.exists():
        raise SystemExit("Missing apk-verification.json from the CI build")
    report = json.loads(report_path.read_text())
    if report.get("status") != "passed":
        raise SystemExit("CI staging build did not pass verification")
    source = Path(report["apk"])
    if not source.exists():
        raise SystemExit(f"Built APK not found: {source}")
    staging = dict(report)

    if not KEYSTORE.exists():
        # Legacy path: leave an unsigned intermediate for private signing.
        target = root / (source.stem + ".unsigned.apk")
        strip_signatures(source, target)
        (root / "ci-staging-verification.json").write_text(json.dumps(staging, indent=2))
        unsigned = {
            "status": "unsigned_intermediate_not_for_installation",
            "version": report["version"],
            "bytes": target.stat().st_size,
            "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
            "filename": target.name,
            "final_signing": "Existing persistent Cloud key; no repository secret needed for unsigned compilation",
        }
        (root / "unsigned-build.json").write_text(json.dumps(unsigned, indent=2))
        source.unlink()
        source.with_suffix(".apk.idsig").unlink(missing_ok=True)
        report_path.unlink()
        (root / "apk-verification.txt").unlink(missing_ok=True)
        (root / "SHA256SUMS.txt").unlink(missing_ok=True)
        print(json.dumps(unsigned, indent=2))
        return 0

    build_tools = find_build_tools()
    if not build_tools or not (build_tools / "apksigner").exists():
        raise SystemExit("apksigner not found; cannot sign with .ci/pickle-debug.keystore")

    unsigned_zip = root / "final-unsigned.zip"
    aligned = root / "final-aligned.apk"
    signed = root / "final-signed.apk"
    for stale in [unsigned_zip, aligned, signed, signed.with_suffix(".apk.idsig")]:
        stale.unlink(missing_ok=True)

    strip_signatures(source, unsigned_zip)
    subprocess.run([str(build_tools / "zipalign"), "-f", "-p", "4", str(unsigned_zip), str(aligned)], check=True)
    # .ci/pickle-debug.keystore는 PKCS12 형식이다(첫 바이트 0x30 0x82).
    store_type = "PKCS12" if KEYSTORE.read_bytes()[:2] == b"\x30\x82" else "JKS"
    subprocess.run([
        str(build_tools / "apksigner"), "sign",
        "--ks", str(KEYSTORE), "--ks-type", store_type, "--ks-key-alias", KEY_ALIAS,
        "--ks-pass", f"pass:{STORE_PASS}", "--key-pass", f"pass:{KEY_PASS}",
        "--v1-signing-enabled", "true", "--v2-signing-enabled", "true", "--v3-signing-enabled", "true",
        "--out", str(signed), str(aligned),
    ], check=True)
    verification = subprocess.run(
        [str(build_tools / "apksigner"), "verify", "--verbose", "--print-certs", str(signed)],
        capture_output=True, text=True, check=True).stdout
    if "Verifies" not in verification:
        raise SystemExit("Re-signed APK did not verify")
    certificate = re.search(r"certificate SHA-256 digest: ([0-9a-f]+)", verification)
    signer = certificate.group(1) if certificate else ""

    # Keep the game's file name, now installable.
    version = str(staging.get("version") or "2.0.27")
    final = root / f"jeon-woochi-{version}.apk"
    if final.exists():
        final.unlink()
    shutil.move(str(signed), str(final))
    unsigned_zip.unlink(missing_ok=True)
    aligned.unlink(missing_ok=True)
    source.unlink(missing_ok=True)
    source.with_suffix(".apk.idsig").unlink(missing_ok=True)

    # Re-run the full package verification against the signed file (reports + SHA256SUMS).
    verify = subprocess.run([
        sys.executable, str(REPO / "tools" / "verify_apk.py"), str(final),
        "--build-tools", str(build_tools), "--output-dir", str(root),
    ], capture_output=True, text=True)
    if verify.returncode != 0:
        sys.stdout.write(verify.stdout)
        sys.stderr.write(verify.stderr)
        raise SystemExit("Signed APK failed package verification")

    signed_report = json.loads((root / "apk-verification.json").read_text())
    signed_report["signer_sha256"] = signer or signed_report.get("signer_sha256", "")
    signed_report["signing_key"] = "repository .ci/pickle-debug.keystore (alias androiddebugkey)"
    signed_report["installable"] = True
    (root / "apk-verification.json").write_text(json.dumps(signed_report, ensure_ascii=False, indent=2) + "\n")
    (root / "SHA256SUMS.txt").write_text(f"{signed_report['sha256']}  {final.name}\n")
    (root / "ci-staging-verification.json").write_text(json.dumps(staging, indent=2))
    completed = {
        "status": "signed_and_verified_installable",
        "version": signed_report.get("version"),
        "bytes": final.stat().st_size,
        "sha256": signed_report["sha256"],
        "filename": final.name,
        "signer_sha256": signed_report.get("signer_sha256", ""),
        "signing_key": signed_report["signing_key"],
    }
    (root / "unsigned-build.json").write_text(json.dumps(completed, indent=2))
    print(json.dumps(completed, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
