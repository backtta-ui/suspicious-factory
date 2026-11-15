#!/usr/bin/env python3
"""Raise stock Godot APK template minSdk to Android 10 for non-Gradle exports.
Only the uses-sdk integer changes. Godot subsequently packages, aligns and signs.
"""
import argparse
import struct
import zipfile
from pathlib import Path


def raise_min_sdk(data: bytes) -> bytes:
    blob = bytearray(data)
    resource_ids = []
    offset = struct.unpack_from('<H', blob, 2)[0]
    patched = 0
    while offset < len(blob):
        kind, header, size = struct.unpack_from('<HHI', blob, offset)
        if size < header or offset + size > len(blob):
            raise ValueError('Invalid binary AndroidManifest chunk')
        if kind == 0x0180:  # RES_XML_RESOURCE_MAP_TYPE
            resource_ids = list(struct.unpack_from('<' + 'I' * ((size-header)//4), blob, offset+header))
        elif kind == 0x0102:  # RES_XML_START_ELEMENT_TYPE
            start, stride, count = struct.unpack_from('<HHH', blob, offset+24)
            for i in range(count):
                attr = offset + 16 + start + i * stride
                name = struct.unpack_from('<I', blob, attr+4)[0]
                if name < len(resource_ids) and resource_ids[name] == 0x0101020c:
                    if blob[attr+15] != 0x10:
                        raise ValueError('minSdkVersion must be TYPE_INT_DEC')
                    struct.pack_into('<I', blob, attr+8, 0xffffffff)  # no raw string
                    struct.pack_into('<I', blob, attr+16, 29)
                    patched += 1
        offset += size
    if patched != 1:
        raise ValueError(f'Expected exactly one minSdkVersion, got {patched}')
    return bytes(blob)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('stock_template', type=Path)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parents[1]/'.android-template/android_debug.apk')
    args = parser.parse_args()
    if args.output.exists() and args.output.stat().st_mtime >= max(args.stock_template.stat().st_mtime, Path(__file__).stat().st_mtime):
        print(f"Using prepared Android 10 template: {args.output}")
        return
    args.output.parent.mkdir(parents=True, exist_ok=True)
    (args.output.parent/'.gdignore').touch()
    with zipfile.ZipFile(args.stock_template) as src, zipfile.ZipFile(args.output, 'w') as dst:
        for entry in src.infolist():
            if entry.filename.startswith('META-INF/'):
                continue  # Old template signatures; exporter signs final APK.
            data = src.read(entry)
            if entry.filename == 'AndroidManifest.xml':
                data = raise_min_sdk(data)
            dst.writestr(entry, data)
    print(f'Prepared {args.output}: minSdk 29, stock targetSdk preserved')


if __name__ == '__main__':
    main()
