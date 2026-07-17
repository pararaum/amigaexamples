#! /usr/bin/env python3

# This was vibe coded and adjusted -- I just needed it fast.

"""
master_disk.py - Amiga trackloader disk mastering tool

Takes a list of assets (demo parts, music, graphics), compresses each with
the external 'salvador' LZSA packer, lays them out sector-by-sector on a
raw 880K disk image, writes a fixed-size manifest table describing where
everything is, and produces a bootable .adf.

Layout produced:
    Track 0, sector 0-1   : bootblock (1024 bytes, checksum patched in)
    Track 0, sector 2-10  : resident loader binary (raw binary, up to 4608 bytes)
    Track 1               : manifest table (up to MANIFEST_MAX_ENTRIES entries)
    Track 2 onward        : compressed assets, back to back, sector-aligned

Requires: 'salvador' binary on PATH (https://github.com/emmanuel-marty/salvador)
Requires: python3-arpeggio (apt install python3-arpeggio, or pip install arpeggio)
"""

import argparse
import os
import struct
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field

# ---------------------------------------------------------------------------
# Disk geometry constants (standard Amiga DD floppy)
# ---------------------------------------------------------------------------

SECTOR_SIZE      = 512
SECTORS_PER_TRACK = 11
TRACKS           = 80 * 2                     # 80 cylinders * 2 heads
DISK_SIZE        = SECTOR_SIZE * SECTORS_PER_TRACK * TRACKS   # 901120 bytes

BOOTBLOCK_SECTORS  = 2                        # fixed by Kickstart
LOADER_START_SECTOR = BOOTBLOCK_SECTORS       # track 0, sector 2
LOADER_MAX_SECTORS  = SECTORS_PER_TRACK - BOOTBLOCK_SECTORS
MANIFEST_START_SECTOR = SECTORS_PER_TRACK     # track 1, sector 0
MANIFEST_SECTORS   = SECTORS_PER_TRACK        # one whole track reserved for manifest
ASSET_START_SECTOR = MANIFEST_START_SECTOR + MANIFEST_SECTORS   # track 2, sector 0

# ---------------------------------------------------------------------------
# Manifest record format
#   4s  name        4 bytes, not null-terminated, purely for debugging
#   I   start_sector
#   H   num_sectors  (sectors to read from disk, i.e. packed data size / 512, rounded up)
#   I   packed_size  (exact byte length of compressed data)
#   I   unpacked_size(size to allocate before depacking)
#   H   mem_flags    (0 = fast/any, 1 = chip)
#   H   type         (0 = part, 1 = music, 2 = gfx, ... up to you)
# Big-endian, matches 68k / C struct layout with no padding (24 bytes total).
# ---------------------------------------------------------------------------

MANIFEST_FORMAT = ">4sIHIIHH"
MANIFEST_ENTRY_SIZE = struct.calcsize(MANIFEST_FORMAT)
assert MANIFEST_ENTRY_SIZE == 22, MANIFEST_ENTRY_SIZE

MANIFEST_MAX_ENTRIES = (MANIFEST_SECTORS * SECTOR_SIZE) // MANIFEST_ENTRY_SIZE

MEM_ANY  = 0
MEM_CHIP = 1

TYPE_PART  = 0
TYPE_MUSIC = 1
TYPE_GFX   = 2


@dataclass
class Asset:
    name: str            # up to 4 chars, for debugging only
    path: str            # path to the uncompressed source file
    mem_flags: int = MEM_ANY
    type_: int = TYPE_PART
    # filled in during mastering:
    packed_path: str = field(default="", init=False)
    start_sector: int = field(default=0, init=False)
    num_sectors: int = field(default=0, init=False)
    packed_size: int = field(default=0, init=False)
    unpacked_size: int = field(default=0, init=False)

# ---------------------------------------------------------------------------
# Asset description file parser (Arpeggio-based PEG/packrat parser)
#
# Text format, one declaration per line:
#
#     # comment
#     asset PT01 "parts/intro.bin"   type=part  mem=any
#     asset MUS1 "assets/track1.mod" type=music mem=chip
#
# Arpeggio (apt install python3-arpeggio) builds a memoizing recursive
# descent PEG parser from the grammar functions below - this is what
# Arpeggio itself documents as its packrat parsing mode. Grammar rules are
# plain Python functions returning Arpeggio combinators; the PTNodeVisitor
# subclass below turns the resulting parse tree into (name, path, attrs)
# tuples, mirroring the hand-written version's output shape exactly.
# ---------------------------------------------------------------------------

from arpeggio import (
    ZeroOrMore, RegExMatch, EOF, ParserPython, PTNodeVisitor, visit_parse_tree, NoMatch,
)


def name():    return RegExMatch(r"[A-Za-z0-9_]+")
def path():    return RegExMatch(r'"[^"]*"')
def key():     return RegExMatch(r"[A-Za-z_]+")
def value():   return RegExMatch(r"[A-Za-z0-9_./-]+")
def attr():    return key, "=", value
def asset_decl(): return "asset", name, path, ZeroOrMore(attr)
def comment(): return RegExMatch(r"#.*")
def asset_file(): return ZeroOrMore(asset_decl), EOF


class AssetVisitor(PTNodeVisitor):
    def visit_path(self, node, children):
        return str(node.value)[1:-1]           # strip surrounding quotes

    def visit_attr(self, node, children):
        return (children[0], children[1])       # (key, value)

    def visit_asset_decl(self, node, children):
        asset_name = children[0]
        asset_path = children[1]
        attrs = dict(children[2:])
        return (asset_name, asset_path, attrs)

    def visit_asset_file(self, node, children):
        # filter out EOF and anything else that isn't one of our tuples
        return [c for c in children if isinstance(c, tuple)]


_MEM_NAMES  = {"any": MEM_ANY, "chip": MEM_CHIP}
_TYPE_NAMES = {"part": TYPE_PART, "music": TYPE_MUSIC, "gfx": TYPE_GFX}


def parse_asset_file(path_: str) -> list[Asset]:
    """Read an asset description file (see grammar above) and return
    a list of Asset objects, ready to hand to master_disk()."""
    with open(path_, "r") as f:
        text = f.read()

    parser = ParserPython(asset_file, comment_def=comment)
    try:
        tree = parser.parse(text)
    except NoMatch as e:
        raise ValueError(f"asset file parse error in {path_}: {e}") from e

    raw_entries = visit_parse_tree(tree, AssetVisitor())

    assets = []
    seen_names = set()
    for asset_name, file_path, attrs in raw_entries:
        if len(asset_name) > 4:
            raise ValueError(f"asset name {asset_name!r} longer than 4 characters")
        if asset_name in seen_names:
            raise ValueError(f"duplicate asset name {asset_name!r}")
        seen_names.add(asset_name)

        mem_str = attrs.get("mem", "any")
        type_str = attrs.get("type", "part")
        if mem_str not in _MEM_NAMES:
            raise ValueError(f"asset {asset_name!r}: unknown mem={mem_str!r} "
                              f"(expected one of {sorted(_MEM_NAMES)})")
        if type_str not in _TYPE_NAMES:
            raise ValueError(f"asset {asset_name!r}: unknown type={type_str!r} "
                              f"(expected one of {sorted(_TYPE_NAMES)})")

        assets.append(Asset(
            name=asset_name,
            path=file_path,
            mem_flags=_MEM_NAMES[mem_str],
            type_=_TYPE_NAMES[type_str],
        ))
    return assets




# ---------------------------------------------------------------------------
# Compression via external salvador binary
# ---------------------------------------------------------------------------

def compress_with_salvador(src_path: str, salvador_bin: str = "salvador") -> bytes:
    """Compress src_path with salvador, return the packed bytes.

    """
    out_path = src_path + ".zx0"
    try:
        cmd = [salvador_bin, src_path, out_path]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(
                f"salvador failed on {src_path}:\n{result.stdout}\n{result.stderr}"
            )
        with open(out_path, "rb") as f:
            return f.read()
    finally:
        if os.path.exists(out_path):
            os.remove(out_path)


def sectors_needed(byte_len: int) -> int:
    return (byte_len + SECTOR_SIZE - 1) // SECTOR_SIZE


def pad_to_sector(data: bytes) -> bytes:
    remainder = len(data) % SECTOR_SIZE
    if remainder == 0:
        return data
    return data + bytes(SECTOR_SIZE - remainder)


# ---------------------------------------------------------------------------
# Bootblock checksum (standard Amiga algorithm: sum of all longwords with
# carry wraparound must equal 0xFFFFFFFF; checksum field itself is zeroed
# during the sum, then patched with the value that makes this true)
# ---------------------------------------------------------------------------

def patch_bootblock_checksum(bootblock: bytearray) -> None:
    assert len(bootblock) == 1024, "bootblock must be exactly 1024 bytes"
    bootblock[4:8] = b"\x00\x00\x00\x00"

    total = 0
    for i in range(0, 1024, 4):
        word = struct.unpack_from(">I", bootblock, i)[0]
        total += word
        if total > 0xFFFFFFFF:
            total = (total & 0xFFFFFFFF) + 1   # carry wraparound

    checksum = (0xFFFFFFFF - total) & 0xFFFFFFFF
    struct.pack_into(">I", bootblock, 4, checksum)


# ---------------------------------------------------------------------------
# Manifest assembly
# ---------------------------------------------------------------------------

def build_manifest(assets: list[Asset]) -> bytes:
    if len(assets) > MANIFEST_MAX_ENTRIES:
        raise ValueError(
            f"too many assets ({len(assets)}), manifest track only holds "
            f"{MANIFEST_MAX_ENTRIES} entries at {MANIFEST_ENTRY_SIZE} bytes each"
        )

    out = bytearray()
    # The first longword of the manifest track is the entry count, so
    # the resident loader knows how far to iterate without a sentinel
    # scan. We add three more longwords for further expansion.
    out += struct.pack(">IIII", len(assets), 0, 0, 0)

    for a in assets:
        name_bytes = a.name.encode("ascii")[:4].ljust(4, b"\x00")
        out += struct.pack(
            MANIFEST_FORMAT,
            name_bytes,
            a.start_sector,
            a.num_sectors,
            a.packed_size,
            a.unpacked_size,
            a.mem_flags,
            a.type_,
        )

    return pad_to_sector(bytes(out)).ljust(MANIFEST_SECTORS * SECTOR_SIZE, b"\x00")


# ---------------------------------------------------------------------------
# Main assembly
# ---------------------------------------------------------------------------

def master_disk(
    bootblock_bin: str,
    loader_bin: str,
    assets: list[Asset],
    out_adf: str,
    salvador_bin: str = "salvador",
):
    # --- bootblock ---
    with open(bootblock_bin, "rb") as f:
        bootblock_code = f.read()
    if len(bootblock_code) > 1024 - 12:
        print("Warning! Bootblock code too large $%08X, extracting code." % len(bootblock_code), file=sys.stderr)
        bootblock_code = bootblock_code[12:1024 - 2]

    bootblock = bytearray(1024)
    bootblock[0:4] = b"DOS\x00"
    struct.pack_into(">I", bootblock, 8, 0)     # rootblock field, unused
    bootblock[12:12 + len(bootblock_code)] = bootblock_code
    patch_bootblock_checksum(bootblock)

    # --- resident loader ---
    with open(loader_bin, "rb") as f:
        loader_code = f.read()
    max_loader_bytes = LOADER_MAX_SECTORS * SECTOR_SIZE
    if len(loader_code) > max_loader_bytes:
        raise ValueError(
            f"loader binary too large ({len(loader_code)} bytes), "
            f"only {max_loader_bytes} bytes reserved on track 0"
        )
    loader_padded = loader_code.ljust(max_loader_bytes, b"\x00")

    # --- compress + place each asset ---
    next_sector = ASSET_START_SECTOR
    packed_blobs = []

    for a in assets:
        packed = compress_with_salvador(a.path, salvador_bin)
        a.packed_size = len(packed)
        a.unpacked_size = os.path.getsize(a.path)
        a.start_sector = next_sector
        a.num_sectors = sectors_needed(a.packed_size)
        next_sector += a.num_sectors
        packed_blobs.append(pad_to_sector(packed))
        print(
            f"  {a.name:<4} {a.path:<30} "
            f"{a.unpacked_size:>7} -> {a.packed_size:>7} bytes  "
            f"sectors {a.start_sector}..{a.start_sector + a.num_sectors - 1}"
        )

    total_disk_sectors = next_sector
    max_sectors = SECTORS_PER_TRACK * TRACKS
    if total_disk_sectors > max_sectors:
        raise ValueError(
            f"image too large: needs {total_disk_sectors} sectors, "
            f"disk only holds {max_sectors}"
        )

    manifest = build_manifest(assets)

    # --- assemble final image ---
    image = bytearray()
    image += bootblock
    image += loader_padded
    image += manifest
    for blob in packed_blobs:
        image += blob
    image = image.ljust(DISK_SIZE, b"\x00")

    assert len(image) == DISK_SIZE, f"image size {len(image)} != {DISK_SIZE}"

    with open(out_adf, "wb") as f:
        f.write(image)

    print(f"\nWrote {out_adf}: {len(image)} bytes, {len(assets)} assets, "
          f"{total_disk_sectors} sectors used of {max_sectors}")


# ---------------------------------------------------------------------------
# Entry point - assets are now described in a text file, not edited here.
# Usage: python3 master_disk.py [assets.cfg]
# ---------------------------------------------------------------------------

def main():
    aparser = argparse.ArgumentParser(
        prog="DiskMaster",
        description="A progam to master ADF disks.")
    aparser.add_argument("bootblock", help="name of the bootblock")
    aparser.add_argument("boss", help="name of the boss system")
    aparser.add_argument("-c", "--config", type=str, help="path to configuration file, default assets.cfg", default="assets.cfg")
    aparser.add_argument("-o", "--output", type=str, help="output file name", default="demo.adf")
    args = aparser.parse_args()
    print(args)

    try:
        assets = parse_asset_file(args.config)
    except FileNotFoundError as e:
        print(f"Error reading {args.config}: {e}", file=sys.stderr)
        sys.exit(1)

    if not assets:
        print(f"error: {config_path} declared no assets", file=sys.stderr)
        sys.exit(1)

    master_disk(
        bootblock_bin=args.bootblock,
        loader_bin=args.boss,
        assets=assets,
        out_adf=args.output,
        salvador_bin="salvador",
    )

if __name__ == "__main__":
    main()
