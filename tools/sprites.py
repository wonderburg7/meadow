#!/usr/bin/env python3
"""The sprite exporter (SP-2). Standard library only.

Reads every `.aseprite` (and every plain single-image `.png`) under
assets/sprites/, plus the sprite table assets/sprites/SPRITES.md, then writes:

  * one PNG sheet per family beside its source, `<name>_sheet.png`, with a
    1-px transparent gutter around every frame (the sharp-pixel shader
    samples across texel edges), layer sprites flattened base plus state,
    and one extra sheet per recolour variant;
  * scripts/sprite_catalogue.gd (generated, do not edit): per family a
    preload, frame size, hframes/vframes, frame names, anchor, view and
    level bounds.

It validates each family against plans/design/pixel-art.md: equal frame
sizes, art inside its grid cell, hard pixels only, and a frame count that
matches the table.

    python tools/sprites.py           write everything that is stale
    python tools/sprites.py --check   change nothing; exit 1 on any stale
                                      sheet or catalogue, or any violation

Aseprite files are read as RGBA, frame 0 only. Recolour and layer rules are
documented in assets/sprites/SPRITES.md.
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SPRITES_DIR = Path("assets") / "sprites"
TABLE_NAME = "SPRITES.md"
CATALOGUE_PATH = Path("scripts") / "sprite_catalogue.gd"
SHEET_SUFFIX = "_sheet.png"
GUTTER = 1
VIEWS = ("hive", "meadow", "menu")
TABLE_COLUMNS = ("family", "file", "shows", "view", "layout", "frames", "levels", "anchor", "variants")


class SpriteError(Exception):
    """A violation the author must fix; the message names the family."""


# --- images -------------------------------------------------------------

@dataclass
class Image:
    width: int
    height: int
    pixels: bytearray  # RGBA, row-major

    @classmethod
    def blank(cls, width: int, height: int) -> "Image":
        return cls(width, height, bytearray(width * height * 4))

    def get(self, x: int, y: int) -> bytes:
        i = (y * self.width + x) * 4
        return bytes(self.pixels[i:i + 4])

    def blit(self, src: "Image", dx: int, dy: int) -> None:
        """Copy src over this image at (dx, dy), pixel for pixel."""
        for y in range(src.height):
            s = y * src.width * 4
            d = ((dy + y) * self.width + dx) * 4
            self.pixels[d:d + src.width * 4] = src.pixels[s:s + src.width * 4]

    def overlay(self, src: "Image") -> None:
        """Draw src over this image: an opaque pixel replaces, a translucent
        one (Dave's honey, the thin middle of a wax cap) blends over."""
        for i in range(0, len(src.pixels), 4):
            sa = src.pixels[i + 3]
            if sa == 255:
                self.pixels[i:i + 4] = src.pixels[i:i + 4]
            elif sa:
                da = self.pixels[i + 3] * (255 - sa) / 255
                out_a = sa + da
                for c in range(3):
                    self.pixels[i + c] = round((src.pixels[i + c] * sa + self.pixels[i + c] * da) / out_a)
                self.pixels[i + 3] = round(out_a)

    def crop(self, x: int, y: int, w: int, h: int) -> "Image":
        out = Image.blank(w, h)
        for row in range(h):
            s = ((y + row) * self.width + x) * 4
            out.pixels[row * w * 4:(row + 1) * w * 4] = self.pixels[s:s + w * 4]
        return out

    def copy(self) -> "Image":
        return Image(self.width, self.height, bytearray(self.pixels))

    def is_empty(self) -> bool:
        return not any(self.pixels[i] for i in range(3, len(self.pixels), 4))

    def border_clear(self) -> bool:
        """True when the outermost ring of pixels is fully transparent."""
        w, h = self.width, self.height
        for x in range(w):
            if self.pixels[x * 4 + 3] or self.pixels[((h - 1) * w + x) * 4 + 3]:
                return False
        for y in range(h):
            if self.pixels[y * w * 4 + 3] or self.pixels[(y * w + w - 1) * 4 + 3]:
                return False
        return True


def decode_png(data: bytes) -> Image:
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos = 8
    header = None
    palette = b""
    trns = b""
    idat = bytearray()
    while pos < len(data):
        length, kind = struct.unpack_from(">I4s", data, pos)
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            palette = body
        elif kind == b"tRNS":
            trns = body
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
    if header is None:
        raise ValueError("PNG has no header")
    width, height, depth, ctype, _comp, _filt, interlace = header
    if depth != 8 or interlace != 0 or ctype not in (0, 2, 3, 4, 6):
        raise ValueError("only non-interlaced 8-bit PNGs are supported")
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[ctype]
    stride = width * channels
    raw = zlib.decompress(bytes(idat))
    rows = []
    prev = bytearray(stride)
    p = 0
    for _ in range(height):
        ftype = raw[p]
        line = bytearray(raw[p + 1:p + 1 + stride])
        p += 1 + stride
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            if ftype == 1:
                line[i] = (line[i] + a) & 255
            elif ftype == 2:
                line[i] = (line[i] + b) & 255
            elif ftype == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 255
            elif ftype == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 255
        rows.append(line)
        prev = line
    out = Image.blank(width, height)
    o = 0
    for line in rows:
        for x in range(width):
            if ctype == 6:
                px = line[x * 4:x * 4 + 4]
            elif ctype == 2:
                px = bytes(line[x * 3:x * 3 + 3]) + b"\xff"
            elif ctype == 0:
                px = bytes([line[x]] * 3) + b"\xff"
            elif ctype == 4:
                px = bytes([line[x * 2]] * 3) + bytes([line[x * 2 + 1]])
            else:
                idx = line[x]
                alpha = trns[idx] if idx < len(trns) else 255
                px = bytes(palette[idx * 3:idx * 3 + 3]) + bytes([alpha])
            out.pixels[o:o + 4] = px
            o += 4
    return out


def encode_png(img: Image) -> bytes:
    def chunk(kind: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    stride = img.width * 4
    raw = bytearray()
    for y in range(img.height):
        raw.append(0)
        raw += img.pixels[y * stride:(y + 1) * stride]
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", img.width, img.height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b""))


# --- aseprite -----------------------------------------------------------

@dataclass
class AseLayer:
    name: str
    visible: bool
    kind: int  # 0 image, 1 group, 2 tilemap
    image: Image | None = None


def read_aseprite(data: bytes) -> tuple[int, int, list[AseLayer]]:
    """Return (width, height, layers bottom-first) for frame 0."""
    if len(data) < 128 or struct.unpack_from("<H", data, 4)[0] != 0xA5E0:
        raise ValueError("not an Aseprite file")
    frames, width, height, depth = struct.unpack_from("<HHHH", data, 6)
    if depth != 32:
        raise ValueError(f"colour depth {depth} is not supported; save as RGBA")
    if frames != 1:
        raise ValueError(f"{frames} animation frames; the exporter reads one frame (use layers or a sheet layer)")
    _size, magic, old_chunks, _dur = struct.unpack_from("<IHHH", data, 128)
    if magic != 0xF1FA:
        raise ValueError("bad frame header")
    new_chunks = struct.unpack_from("<I", data, 128 + 12)[0]
    count = new_chunks or old_chunks
    pos = 128 + 16
    layers: list[AseLayer] = []
    for _ in range(count):
        size, kind = struct.unpack_from("<IH", data, pos)
        body = data[pos + 6:pos + size]
        pos += size
        if kind == 0x2004:
            flags, ltype = struct.unpack_from("<HH", body, 0)
            (nlen,) = struct.unpack_from("<H", body, 16)
            name = body[18:18 + nlen].decode("utf-8")
            layers.append(AseLayer(name, bool(flags & 1), ltype))
        elif kind == 0x2005:
            index, x, y, _opacity, ctype = struct.unpack_from("<HhhBH", body, 0)
            if ctype not in (0, 2):
                continue
            w, h = struct.unpack_from("<HH", body, 16)
            payload = body[20:]
            if ctype == 2:
                # Resprite leaves off the stream's closing checksum, so
                # zlib.decompress() reports it truncated; read what is there.
                payload = zlib.decompressobj().decompress(payload)
                if len(payload) < w * h * 4:
                    raise ValueError(f"layer {layers[index].name!r} has a short pixel stream")
            cel = Image(w, h, bytearray(payload[:w * h * 4]))
            if x < 0 or y < 0 or x + w > width or y + h > height:
                # Editors leave a cel's box hanging off the canvas after a
                # move; only drawn pixels out there are an error.
                for cy in range(h):
                    for cx in range(w):
                        if cel.pixels[(cy * w + cx) * 4 + 3] and not (0 <= x + cx < width and 0 <= y + cy < height):
                            raise ValueError(f"layer {layers[index].name!r} has art outside the {width}x{height} canvas")
                left, top = max(0, -x), max(0, -y)
                cel = cel.crop(left, top, min(w, width - x) - left, min(h, height - y) - top)
                x, y = x + left, y + top
            full = Image.blank(width, height)
            full.blit(cel, x, y)
            layers[index].image = full
    return width, height, layers


# --- the table ----------------------------------------------------------

@dataclass
class Row:
    family: str
    file: str
    shows: str
    view: str
    layout: str
    frames: int
    levels: list[int]
    anchor: tuple[int, int] | None
    variants: dict[str, dict[tuple[int, int, int], tuple[int, int, int]]] = field(default_factory=dict)


def _hex_colour(text: str, family: str) -> tuple[int, int, int]:
    text = text.strip().lstrip("#")
    if len(text) != 6:
        raise SpriteError(f"{family}: colour {text!r} is not RRGGBB")
    return int(text[0:2], 16), int(text[2:4], 16), int(text[4:6], 16)


def parse_table(text: str) -> list[Row]:
    rows: list[Row] = []
    seen_header = False
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip().strip("`") for c in line.strip("|").split("|")]
        if not seen_header:
            if [c.lower() for c in cells] == list(TABLE_COLUMNS):
                seen_header = True
            continue
        if set("".join(cells)) <= set("-: "):
            continue
        if len(cells) != len(TABLE_COLUMNS):
            raise SpriteError(f"table row {cells[0]!r} has {len(cells)} cells, expected {len(TABLE_COLUMNS)}")
        family, file, shows, view, layout, frames, levels, anchor, variants = cells
        if view not in VIEWS:
            raise SpriteError(f"{family}: view {view!r} is not one of {VIEWS}")
        try:
            nframes = int(frames)
        except ValueError:
            raise SpriteError(f"{family}: frames {frames!r} is not a whole number") from None
        bounds = [] if levels in ("-", "") else [int(v) for v in levels.split("/")]
        anchor_xy = None
        if anchor not in ("-", ""):
            ax, ay = anchor.split(",")
            anchor_xy = (int(ax), int(ay))
        row = Row(family, file, shows, view, layout, nframes, bounds, anchor_xy)
        if variants not in ("-", ""):
            for part in variants.split(";"):
                name, _, swaps = part.partition(":")
                name = name.strip()
                mapping = {}
                for pair in swaps.split(","):
                    src, _, dst = pair.partition(">")
                    mapping[_hex_colour(src, family)] = _hex_colour(dst, family)
                if not name or not mapping:
                    raise SpriteError(f"{family}: variant {part!r} needs name: RRGGBB>RRGGBB")
                row.variants[name] = mapping
        rows.append(row)
    if not seen_header:
        raise SpriteError(f"{TABLE_NAME} has no table with the header {' | '.join(TABLE_COLUMNS)}")
    return rows


# --- building a family --------------------------------------------------

@dataclass
class Built:
    row: Row
    frame_size: tuple[int, int]
    hframes: int
    vframes: int
    frame_names: list[str]
    gutter: int
    sheets: dict[str, Image]  # output file name -> image


def _parse_grid(layout: str, family: str) -> tuple[int, int, list[str]]:
    # "grid 16x16 rows=left,right"
    parts = layout.split()
    try:
        fw, fh = (int(v) for v in parts[1].split("x"))
        names = parts[2].split("=", 1)[1].split(",")
    except (IndexError, ValueError):
        raise SpriteError(f"{family}: layout must read 'grid WxH rows=name,name,...', got {layout!r}") from None
    return fw, fh, names


def _compose_sheet(frames: list[Image], hframes: int, gutter: int) -> Image:
    fw, fh = frames[0].width, frames[0].height
    vframes = (len(frames) + hframes - 1) // hframes
    cw, ch = fw + 2 * gutter, fh + 2 * gutter
    sheet = Image.blank(cw * hframes, ch * vframes)
    for i, frame in enumerate(frames):
        sheet.blit(frame, (i % hframes) * cw + gutter, (i // hframes) * ch + gutter)
    return sheet


def _state_name(layer_name: str) -> str:
    return layer_name.rsplit(".", 1)[-1]


def build_family(row: Row, source: Path, sheet_name: str) -> Built | None:
    fam = row.family
    layout = row.layout.split()[0] if row.layout else ""
    if layout == "unexported":
        return None
    data = source.read_bytes()
    frames: list[Image]
    names: list[str]
    hframes = 1
    gutter = GUTTER
    if source.suffix == ".png":
        if layout not in ("single", "tile"):
            raise SpriteError(f"{fam}: a plain .png must use layout 'single' or 'tile', not {layout!r}")
        img = decode_png(data)
        frames, names = [img], ["frame"]
        if layout == "tile":
            gutter = 0
    else:
        try:
            width, height, layers = read_aseprite(data)
        except ValueError as err:
            raise SpriteError(f"{fam}: {err}") from None
        usable = [l for l in layers if l.kind == 0 and not l.name.startswith("_")]
        if not usable:
            raise SpriteError(f"{fam}: no image layers")
        for l in usable:
            if l.image is None:
                l.image = Image.blank(width, height)
        if layout == "layers":
            if len(usable) < 2:
                raise SpriteError(f"{fam}: layers layout needs a base layer and at least one state layer")
            base = usable[0].image
            frames, names = [base.copy()], [_state_name(usable[0].name)]
            for l in usable[1:]:
                f = base.copy()
                f.overlay(l.image)
                frames.append(f)
                names.append(_state_name(l.name))
            hframes = len(frames)
            if len(set(names)) != len(names):
                raise SpriteError(f"{fam}: two layers share the state name {names}")
        elif layout == "frames":
            # Every layer is a whole frame on its own, with no base under
            # it: the wax caps drawn over another cell, or the stages of a
            # soil block crumbling away.
            frames = [l.image.copy() for l in usable]
            names = [_state_name(l.name) for l in usable]
            hframes = len(frames)
            if len(set(names)) != len(names):
                raise SpriteError(f"{fam}: two layers share the state name {names}")
        elif layout == "single":
            # What the editor shows: hidden layers are offcuts and spares.
            shown = [l for l in usable if l.visible]
            if not shown:
                raise SpriteError(f"{fam}: a single sprite needs at least one visible layer")
            frames, names = [shown[0].image.copy()], ["frame"]
            for l in shown[1:]:
                frames[0].overlay(l.image)
        elif layout == "grid":
            sheet_layers = [l for l in usable if l.name == "sheet"]
            if len(sheet_layers) != 1:
                raise SpriteError(f"{fam}: a grid sprite needs exactly one layer named 'sheet'")
            fw, fh, rows_ = _parse_grid(row.layout, fam)
            if width % fw or height % fh:
                raise SpriteError(f"{fam}: canvas {width}x{height} is not a whole number of {fw}x{fh} frames")
            cols = width // fw
            if height // fh != len(rows_):
                raise SpriteError(f"{fam}: {height // fh} rows on the sheet but {len(rows_)} row names in the table")
            frames, names = [], []
            for r, rname in enumerate(rows_):
                for c in range(cols):
                    frames.append(sheet_layers[0].image.crop(c * fw, r * fh, fw, fh))
                    names.append(f"{rname}.{c}")
            hframes = cols
        else:
            raise SpriteError(f"{fam}: unknown layout {row.layout!r}")

    if len({(f.width, f.height) for f in frames}) != 1:
        raise SpriteError(f"{fam}: frame sizes differ")
    if len(frames) != row.frames:
        raise SpriteError(f"{fam}: the file gives {len(frames)} frames but the table says {row.frames}")
    for name, f in zip(names, frames):
        if layout == "grid" and not f.is_empty() and not f.border_clear():
            raise SpriteError(f"{fam}: frame {name!r} has art on the edge of its grid cell (leave 1 px clear)")
    if layout == "layers":
        if row.levels and len(row.levels) != len(frames) - 1:
            raise SpriteError(f"{fam}: {len(row.levels)} level bounds for {len(frames) - 1} state layers")
        if row.levels != sorted(row.levels):
            raise SpriteError(f"{fam}: level bounds must rise")
    elif row.levels:
        raise SpriteError(f"{fam}: level bounds only apply to layer sprites")
    fw, fh = frames[0].width, frames[0].height
    if row.anchor and not (0 <= row.anchor[0] <= fw and 0 <= row.anchor[1] <= fh):
        raise SpriteError(f"{fam}: anchor {row.anchor} is outside the {fw}x{fh} frame")

    vframes = (len(frames) + hframes - 1) // hframes
    base_sheet = _compose_sheet(frames, hframes, gutter)
    sheets = {sheet_name: base_sheet}
    for vname, mapping in row.variants.items():
        present = {tuple(base_sheet.pixels[i:i + 3]) for i in range(0, len(base_sheet.pixels), 4) if base_sheet.pixels[i + 3]}
        missing = [c for c in mapping if c not in present]
        if missing:
            raise SpriteError(f"{fam}: variant {vname!r} swaps colour {missing[0]} which the art does not use")
        out = base_sheet.copy()
        for i in range(0, len(out.pixels), 4):
            if out.pixels[i + 3]:
                key = tuple(out.pixels[i:i + 3])
                if key in mapping:
                    out.pixels[i:i + 3] = bytes(mapping[key])
        sheets[sheet_name[:-len(SHEET_SUFFIX)] + f"_{vname}" + SHEET_SUFFIX] = out
    return Built(row, (fw, fh), hframes, vframes, names, gutter, sheets)


# --- catalogue ----------------------------------------------------------

def _res_path(relative: Path) -> str:
    return "res://" + relative.as_posix()


def catalogue_text(built: list[Built], sheet_dirs: dict[str, Path]) -> str:
    out = [
        "extends RefCounted",
        "## GENERATED by tools/sprites.py from assets/sprites/SPRITES.md and the",
        "## art files beside it. Do not edit: run `python tools/sprites.py`.",
        "## Frame sizes and anchors are in art pixels. A sheet cell is the frame",
        "## plus CELL_GUTTER on every side, so hframes/vframes slice it exactly.",
        "",
    ]
    for b in built:
        r = b.row
        up = r.family.upper()
        fw, fh = b.frame_size
        cell = (fw + 2 * b.gutter, fh + 2 * b.gutter)
        anchor = r.anchor if r.anchor else (fw / 2, fh / 2)
        out.append(f"# {r.family}: {r.shows}")
        for sheet_name in b.sheets:
            suffix = sheet_name[len(r.family):-len(SHEET_SUFFIX)].upper()  # "" or "_VARIANT"
            path = _res_path(sheet_dirs[r.family] / sheet_name)
            out.append(f'const {up}{suffix}_SHEET := preload("{path}")')
        out.append(f"const {up}_FRAME_SIZE := Vector2i({fw}, {fh})")
        out.append(f"const {up}_CELL_GUTTER := {b.gutter}")
        out.append(f"const {up}_CELL_SIZE := Vector2i({cell[0]}, {cell[1]})")
        out.append(f"const {up}_HFRAMES := {b.hframes}")
        out.append(f"const {up}_VFRAMES := {b.vframes}")
        names = ", ".join(f'"{n}"' for n in b.frame_names)
        out.append(f"const {up}_FRAMES: Array[String] = [{names}]")
        out.append(f"const {up}_ANCHOR := Vector2({float(anchor[0])}, {float(anchor[1])})")
        out.append(f'const {up}_VIEW := "{r.view}"')
        if r.levels:
            out.append(f"const {up}_LEVELS: Array[int] = [{', '.join(str(v) for v in r.levels)}]")
        out.append("")
    return "\n".join(out).rstrip("\n") + "\n"


# --- driver -------------------------------------------------------------

def discover_sources(sprites: Path) -> list[Path]:
    found = []
    for p in sorted(sprites.rglob("*")):
        if p.suffix == ".aseprite" or (p.suffix == ".png" and not p.name.endswith(SHEET_SUFFIX)):
            found.append(p)
    return found


def _same_pixels(path: Path, img: Image) -> bool:
    if not path.exists():
        return False
    try:
        old = decode_png(path.read_bytes())
    except (ValueError, zlib.error):
        return False
    return old.width == img.width and old.height == img.height and old.pixels == img.pixels


def run(root: Path, check: bool, out=print) -> int:
    sprites = root / SPRITES_DIR
    try:
        rows = parse_table((sprites / TABLE_NAME).read_text(encoding="utf-8"))
    except FileNotFoundError:
        out(f"sprites: {SPRITES_DIR / TABLE_NAME} is missing")
        return 1
    except SpriteError as err:
        out(f"sprites: {err}")
        return 1

    problems: list[str] = []
    by_file = {}
    for row in rows:
        if row.file in by_file:
            problems.append(f"{row.family}: {row.file} already has a row")
        by_file[row.file] = row
    for src in discover_sources(sprites):
        rel = src.relative_to(sprites).as_posix()
        if rel not in by_file:
            problems.append(f"{rel}: no row in {TABLE_NAME} (add one line to the table)")
    built: list[Built] = []
    sheet_dirs: dict[str, Path] = {}
    stale: list[str] = []
    for row in rows:
        src = sprites / row.file
        if not src.exists():
            problems.append(f"{row.family}: {row.file} does not exist")
            continue
        if src.stem != row.family:
            problems.append(f"{row.family}: file name {src.name} must be {row.family}{src.suffix}")
            continue
        sheet_name = src.stem + SHEET_SUFFIX
        try:
            b = build_family(row, src, sheet_name)
        except SpriteError as err:
            problems.append(str(err))
            continue
        except (ValueError, zlib.error, struct.error) as err:
            problems.append(f"{row.family}: cannot read {row.file}: {err}")
            continue
        if b is None:
            out(f"{row.family}: unexported")
            continue
        built.append(b)
        sheet_dirs[row.family] = (SPRITES_DIR / row.file).parent
        state = "ok"
        for name, img in b.sheets.items():
            target = src.parent / name
            if not _same_pixels(target, img):
                stale.append(target.relative_to(root).as_posix())
                state = "stale" if check else "written"
                if not check:
                    target.write_bytes(encode_png(img))
        fw, fh = b.frame_size
        out(f"{row.family}: {len(b.frame_names)} frames of {fw}x{fh} ({b.hframes}x{b.vframes} sheet"
            f"{', ' + str(len(b.sheets) - 1) + ' variants' if len(b.sheets) > 1 else ''}) {state}")

    for p in problems:
        out(f"sprites: {p}")
    if problems:
        return 1
    text = catalogue_text(built, sheet_dirs)
    cat = root / CATALOGUE_PATH
    current = cat.read_text(encoding="utf-8").replace("\r\n", "\n") if cat.exists() else None
    if current != text:
        stale.append(CATALOGUE_PATH.as_posix())
        if not check:
            cat.write_text(text, encoding="utf-8", newline="\n")
            out(f"sprites: wrote {CATALOGUE_PATH.as_posix()}")
    if check and stale:
        out("sprites: stale (run python tools/sprites.py): " + ", ".join(stale))
        return 1
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--check", action="store_true", help="change nothing; fail on stale output")
    parser.add_argument("--root", type=Path, default=ROOT, help="repository root (tests use a temporary one)")
    args = parser.parse_args(argv)
    return run(args.root, args.check)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
