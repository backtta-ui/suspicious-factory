#!/usr/bin/env python3
"""Validate the actual signed APK; emit human and machine readable reports."""
import argparse
import hashlib
import json
import re
import subprocess
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--build-tools', type=Path, required=True)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    report = {'status': 'failed', 'apk': str(args.apk.resolve()),
              'checked_at': datetime.now(timezone.utc).isoformat(),
              'device_test': 'not_performed', 'checks': []}
    details = []

    def check(ok, message):
        if not ok:
            raise ValueError(message)
        report['checks'].append(message)

    def tool(name, *parameters):
        result = subprocess.run([str(args.build_tools / name), *map(str, parameters)],
                                capture_output=True, text=True, timeout=120)
        details.append(f'$ {name} ' + ' '.join(map(str, parameters)))
        details.append(result.stdout.strip())
        if result.returncode:
            raise ValueError(f'{name} failed: {result.stderr.strip()}')
        return result.stdout

    try:
        check(args.apk.is_file() and args.apk.stat().st_size > 0, 'APK exists and is nonempty')
        with zipfile.ZipFile(args.apk) as apk:
            check(apk.testzip() is None, 'ZIP integrity')
            entries = apk.namelist()
            check('AndroidManifest.xml' in entries and 'classes.dex' in entries,
                  'Android manifest and executable bytecode present')
            check('lib/arm64-v8a/libgodot_android.so' in entries, 'Godot ARM64 engine present')
            check('assets/assets/fonts/NOTICE.txt' in entries, 'Bundled font license present')
            check(any('splash' in entry for entry in entries), 'Splash image present')
            check(any('hero.png' in entry for entry in entries) and any('environment.png' in entry for entry in entries) and any('title.png' in entry for entry in entries), 'HD hero, environment atlas and title art packaged')
            check(not any('factory_session' in entry or 'factory_v2' in entry for entry in entries), 'Factory/network game resources removed')
            check(not any(entry.startswith(('assets/tests/', 'assets/tools/', 'assets/builds/'))
                          for entry in entries), 'Development files excluded')
        signature = tool('apksigner', 'verify', '--verbose', '--print-certs', args.apk)
        check('Verifies' in signature, 'APK cryptographic signature valid')
        certificate = re.search(r'certificate SHA-256 digest: ([0-9a-f]+)', signature)
        check(certificate is not None, 'Signing certificate fingerprint readable')
        report['signer_sha256'] = certificate.group(1)
        badging = tool('aapt', 'dump', 'badging', args.apk)
        manifest = tool('aapt', 'dump', 'xmltree', args.apk, 'AndroidManifest.xml')
        check("package: name='com.suspiciousfactory.game'" in badging, 'Expected package ID')
        check("sdkVersion:'29'" in badging, 'Minimum Android 10 / API 29')
        target = re.search(r"targetSdkVersion:'(\d+)'", badging)
        check(target is not None and int(target.group(1)) >= 35, 'Target API at least 35')
        check("native-code: 'arm64-v8a'" in badging, 'ARM64-only build')
        check('android:screenOrientation(0x0101001e)=(type 0x10)0x0' in manifest,
              'Landscape orientation')
        check('android:allowBackup(0x01010280)=(type 0x12)0x0' in manifest,
              'Android automatic data backup disabled')
        permissions = tool('aapt', 'dump', 'permissions', args.apk)
        declared = set(re.findall(r"uses-permission: name='([^']+)'", permissions))
        check(not declared, 'Offline single-player APK has no Android permissions')
        check("application-label:'도사: 전우치'" in badging, 'New game display title')
        tool('zipalign', '-c', '-P', '16', '4', args.apk)
        check(True, '4-byte ZIP / 16 KiB native library alignment')
        version = re.search(r"versionName='([^']+)'", badging)
        check(version is not None, 'Version name readable')
        report.update(status='passed', version=version.group(1), target_api=int(target.group(1)),
                      bytes=args.apk.stat().st_size,
                      sha256=hashlib.sha256(args.apk.read_bytes()).hexdigest())
        (args.output_dir / 'SHA256SUMS.txt').write_text(
            f"{report['sha256']}  {args.apk.name}\n", encoding='utf-8')
    except (ValueError, OSError, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        report['error'] = str(error)
        details.append('FAIL: ' + str(error))
    (args.output_dir / 'apk-verification.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (args.output_dir / 'apk-verification.txt').write_text(
        '\n'.join(details) + '\n\n' + json.dumps(report, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report['status'] == 'passed' else 1


if __name__ == '__main__':
    sys.exit(main())
