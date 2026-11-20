#!/usr/bin/env python3
import os
import struct
import sys

LC_BUILD_VERSION = 0x32
MH_MAGIC_64 = 0xFEEDFACF
FAT_MAGIC = 0xCAFEBABE
FAT_MAGIC_64 = 0xCAFEBABF


def patch_thin(buf, platform):
    if len(buf) < 32:
        return 0
    magic, _, _, _, ncmds, _, _ = struct.unpack_from("<IiiIIII", buf, 0)
    if magic != MH_MAGIC_64:
        return 0
    off = 32
    changed = 0
    for _ in range(ncmds):
        if off + 12 > len(buf):
            break
        cmd, size = struct.unpack_from("<II", buf, off)
        if size <= 0:
            break
        if cmd == LC_BUILD_VERSION:
            struct.pack_into("<I", buf, off + 8, platform)
            changed += 1
        off += size
    return changed


def patch_file(path, platform):
    with open(path, "rb") as fh:
        data = bytearray(fh.read())
    if len(data) < 8:
        return 0
    magic = struct.unpack_from(">I", data, 0)[0]
    total = 0
    if magic in (FAT_MAGIC, FAT_MAGIC_64):
        count = struct.unpack_from(">I", data, 4)[0]
        entry = 8 if magic == FAT_MAGIC else 8
        step = 20 if magic == FAT_MAGIC else 32
        for i in range(count):
            base = entry + i * step
            offset = struct.unpack_from(">I", data, base + 8)[0]
            size = struct.unpack_from(">I", data, base + 12)[0]
            chunk = bytearray(data[offset:offset + size])
            if patch_thin(chunk, platform):
                data[offset:offset + size] = chunk
                total += 1
    else:
        total = patch_thin(data, platform)
    if total:
        with open(path, "wb") as fh:
            fh.write(data)
    return total


def main():
    if len(sys.argv) < 3:
        print("usage: macho_platform.py <path> <platform>", file=sys.stderr)
        return 2
    target = sys.argv[1]
    platform = int(sys.argv[2])
    paths = []
    if os.path.isdir(target):
        for root, _, files in os.walk(target):
            for name in files:
                paths.append(os.path.join(root, name))
    else:
        paths.append(target)

    patched = 0
    for path in paths:
        try:
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            if patch_file(path, platform):
                patched += 1
        except (OSError, struct.error):
            continue
    print("patched %d binaries" % patched)
    return 0


if __name__ == "__main__":
    sys.exit(main())