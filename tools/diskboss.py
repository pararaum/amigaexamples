#! /usr/bin/env python3

# This was vibe coded and adjusted -- I just needed it fast.

"""
master_disk.py - Amiga trackloader disk mastering tool

Takes a list of assets (demo parts, music, graphics), compresses each with
the external 'salvador' ZX0 packer, lays them out sector-by-sector on a
raw 880K disk image, writes a fixed-size manifest table describing where
everything is, and produces a bootable .adf.

Layout produced:
    Track 0, sector 0   : bootblock (1024 bytes, checksum patched in)
    Track 0, sector 1-2 : manifest, first part is in bootblock!
    Track 0, sector 3-10: boss resident loader binary (raw binary, up to 4096 bytes)
    Track 1 onward        : compressed assets, back to back, sector-aligned

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

BOOTBLOCK_SECTORS  = 1                      # We only use the first sector!
MANIFEST_START_SECTOR = 2
MANIFEST_SECTORS   = 2 
BOSS_START_SECTOR = MANIFEST_START_SECTOR + MANIFEST_SECTORS
BOSS_MAX_SECTORS  = 8                   # TODO: trackloader should be able to load anything
ASSET_START_SECTOR = 11                 # Track 1, Sector 0

# ---------------------------------------------------------------------------
# Manifest record format
#   4s  name        4 bytes, not null-terminated, purely for debugging
#   H   start_sector
#   H   num_sectors  (sectors to read from disk, i.e. packed data size / 512, rounded up)
#   I   packed_size  (exact byte length of compressed data)
#   I   unpacked_size(size to allocate before depacking)
#   I   mem_flags    (0x00000000 = any memory, 0x80000000 = chip memory,
#                      anything else = explicit destination address)
# Big-endian, matches 68k / C struct layout with no padding (24 bytes total).
# ---------------------------------------------------------------------------

MANIFEST_FORMAT = ">4sHHIII"
MANIFEST_ENTRY_SIZE = struct.calcsize(MANIFEST_FORMAT)
assert MANIFEST_ENTRY_SIZE == 20, MANIFEST_ENTRY_SIZE

MANIFEST_MAX_ENTRIES = (MANIFEST_SECTORS * SECTOR_SIZE) // MANIFEST_ENTRY_SIZE

MEM_ANY  = 0x00000000
# 0x80000000 is used as a sentinel, not a real address: 68000-based Amigas
# only have a 24-bit address bus (max 16MB), so no real chip/fast memory
# address will ever have bit 31 set. That makes this value unambiguous
# against any hex destination address someone specifies explicitly.
MEM_CHIP = 0x80000000
# Bit 30, ORed into an explicit hex address, tells the loader the address
# is already reserved (e.g. a fixed hardware location) and must not be
# passed to the memory allocator. Also safe: real addresses only use
# bits 0-23.
NO_ALLOC_FLAG = 0x40000000


@dataclass
class Asset:
    name: str            # up to 4 chars, for debugging only
    path: str            # path to the uncompressed source file
    mem_flags: int = MEM_ANY
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
#     asset PT01 "parts/intro.bin"   mem=any
#     asset MUS1 "assets/track1.mod" mem=chip
#     asset LOGO "assets/logo.raw"   mem=0x40000
#     asset COPL "parts/copper.bin"  mem=0x40 alloc=no
#
# mem= accepts 'any' (loader picks the address), 'chip' (must be chip
# RAM, loader picks the address), or a hex address (asset must land at
# that exact destination address - see MEM_ANY/MEM_CHIP sentinels below).
# alloc=no (only valid with an explicit hex mem= address) marks that
# address as already reserved, so the loader must not allocate it -
# signaled to the loader by setting bit 30 of mem_flags (NO_ALLOC_FLAG).
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
        mem_key = mem_str.lower()
        if mem_key in _MEM_NAMES:
            mem_flags = _MEM_NAMES[mem_key]
        else:
            # not 'any' or 'chip' - must be a hex destination address,
            # e.g. mem=0x40000 or mem=40000 (int(..., 16) accepts both)
            try:
                mem_flags = int(mem_str, 16)
            except ValueError:
                raise ValueError(
                    f"asset {asset_name!r}: mem={mem_str!r} is not 'any', "
                    f"'chip', or a valid hex address"
                )
            if mem_flags & 0xFF000000:
                raise ValueError(
                    f"asset {asset_name!r}: mem=0x{mem_flags:X} has bits set "
                    f"above the 24-bit Amiga address range"
                )

        # alloc=no means "the given mem= address is already reserved,
        # don't allocate it" - signaled to the loader by setting bit 30
        # (OR with 0x40000000). Only meaningful together with an explicit
        # hex address, since 'any'/'chip' don't name a real address to
        # skip allocation for.
        alloc_str = attrs.get("alloc", "yes").lower()
        if alloc_str in ("yes", "true", "1"):
            no_alloc = False
        elif alloc_str in ("no", "false", "0"):
            no_alloc = True
        else:
            raise ValueError(
                f"asset {asset_name!r}: alloc={alloc_str!r} is not "
                f"'yes' or 'no'"
            )

        if no_alloc:
            if mem_key in _MEM_NAMES:
                raise ValueError(
                    f"asset {asset_name!r}: alloc=no requires an explicit "
                    f"hex mem= address, not mem={mem_str!r}"
                )
            mem_flags |= NO_ALLOC_FLAG

        assets.append(Asset(
            name=asset_name,
            path=file_path,
            mem_flags=mem_flags,
        ))
    return assets




# ---------------------------------------------------------------------------
# Compression via external salvador binary
# ---------------------------------------------------------------------------

def compress_with_salvador(src_path: str, salvador_bin: str = "salvador") -> bytes:
    """Compress src_path with salvador, return the packed bytes.

    """
    rebuild = False
    out_path = src_path + ".zx0"
    src_stats = os.stat(src_path)
    try:
        stats = os.stat(out_path)
        #print(f"\tUsing file {out_path} with {stats.st_size} bytes.")
    except FileNotFoundError:
        rebuild = True
    if not rebuild and stats.st_mtime < src_stats.st_mtime:
        rebuild = True
    if rebuild:
        # I do know that make can do this but it is very convenient to
        # have the functionality in this tool as well...
        cmd = [salvador_bin, src_path, out_path]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(
                f"salvador failed on {src_path}:\n{result.stdout}\n{result.stderr}"
            )
    with open(out_path, "rb") as f:
        return f.read()


def sectors_needed(byte_len: int) -> int:
    """calculate number of sectors needed

    This function will take care of partially filled sectors so that a
    single byte will still occupy a whole sector.

    @param byte_len: bytes needed
    """
    return (byte_len + SECTOR_SIZE - 1) // SECTOR_SIZE


def pad_to_sector(data: bytes) -> bytes:
    remainder = len(data) % SECTOR_SIZE
    if remainder == 0:
        return data
    return data + bytes(SECTOR_SIZE - remainder)




def patch_bootblock_checksum(data: bytearray) -> None:
    """fix bb

    Bootblock checksum (standard Amiga algorithm: sum of all longwords
    with carry wraparound must equal 0xFFFFFFFF; checksum field itself
    is zeroed during the sum, then patched with the value that makes
    this true)

    @param data: bootblock data, 1024 bytes
    @return: fixed bootblock
    """
    assert len(data) >= 1024, "bootblock must be at least 1024 bytes"

    chksum = 0x444f5300
    for w in range(8, 1024, 4):
        chksum += struct.unpack('>I', data[w:w + 4])[0]
        if chksum > 0xffffffff:
            chksum = (chksum + 1) & 0xffffffff
    chksum = (~chksum) & 0xffffffff
    print("BB checksum is $%08X." % chksum)
    # Set checksum.
    struct.pack_into(">I", data, 4, chksum)


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
    # the resident boss knows how far to iterate without a sentinel
    # scan.
    out += struct.pack(">I", len(assets))
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
        )

    return pad_to_sector(bytes(out)).ljust(MANIFEST_SECTORS * SECTOR_SIZE, b"\x00")


# ---------------------------------------------------------------------------
# Main assembly
# ---------------------------------------------------------------------------

def master_disk(
    bootblock_bin: str,
    boss_bin: str,
    assets: list[Asset],
    out_adf: str,
    salvador_bin: str = "salvador",
):
    # Read bootblock code.
    with open(bootblock_bin, "rb") as f:
        bootblock_code = f.read()
    if len(bootblock_code) > 1024 - 12:
        print("Warning! Bootblock code too large $%08X, extracting code." % len(bootblock_code), file=sys.stderr)
        bootblock_code = bootblock_code[12:1024 - 2]
    # Prepare bootblock
    bootblock = bytearray(1024)
    bootblock[0:4] = b"DOS\x00"
    # Set root disk value to make Amigados recognise the disk.
    struct.pack_into(">I", bootblock, 8, 0x370)
    bootblock[12:12 + len(bootblock_code)] = bootblock_code

    # --- resident boss ---
    with open(boss_bin, "rb") as f:
        boss_code = f.read()
    max_boss_bytes = BOSS_MAX_SECTORS * SECTOR_SIZE
    if len(boss_code) > max_boss_bytes:
        raise ValueError(
            f"boss binary too large ({len(boss_code)} bytes), "
            f"only {max_boss_bytes} bytes reserved on track 0"
        )
    print("Boss binary is $%08X bytes, padded to $%08X." % (len(boss_code), max_boss_bytes))
    boss_padded = boss_code.ljust(max_boss_bytes, b"\x00")

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
        namehex = (ord(a.name[0]) << 24) | (ord(a.name[1]) << 16) | (ord(a.name[2]) << 8) | ord(a.name[3])
        print(
            f"  {a.name:<4} ${namehex:08X}"
            f"{a.unpacked_size:>7} ${a.unpacked_size:06x} -> {a.packed_size:>7} ${a.packed_size:06x} bytes, "
            f" sectors {a.start_sector:>5} ..{a.start_sector + a.num_sectors - 1:>5}"
            f": {a.path:<40} "
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
    # Bootblock only one sector in our case!
    bootblock = bootblock[0:512]
    image += bootblock
    image += manifest
    image += boss_padded
    for blob in packed_blobs:
        image += blob
    image = image.ljust(DISK_SIZE, b"\x00")

    assert len(image) == DISK_SIZE, f"image size {len(image)} != {DISK_SIZE}"
    # Fix the bootblock checksum in the image
    patch_bootblock_checksum(image)
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
        boss_bin=args.boss,
        assets=assets,
        out_adf=args.output,
        salvador_bin="salvador",
    )

if __name__ == "__main__":
    main()
