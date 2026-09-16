#!/usr/bin/env python3
"""Subset Noto Sans SC into the bundled 'CanoKey CJK' font.

Downloads nothing; expects the variable font at the path given by --font
(get it from https://github.com/google/fonts/tree/main/ofl/notosanssc).

Character set: printable ASCII, Latin-1, general/CJK punctuation, full-width
forms, common arrows and symbols, every character used by the ARB
localizations in lib/l10n, and all CJK ideographs encodable in GB2312
(simplified) or Big5 (traditional). User-supplied content outside this set
falls back to the engine font fallback (web) or system fonts (native).

Usage:
    python3 tool/subset_cjk_font.py --font NotoSansSC[wght].ttf

Requires: pip install fonttools
"""

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "fonts"
WEIGHTS = {400: "Regular", 700: "Bold"}


def build_charset() -> str:
    chars = set()

    def add_range(start: int, end: int) -> None:
        chars.update(chr(c) for c in range(start, end + 1))

    add_range(0x20, 0x7E)    # printable ASCII
    add_range(0xA0, 0xFF)    # Latin-1 supplement
    add_range(0x2010, 0x205E)  # general punctuation (dashes, quotes, …)
    add_range(0x2190, 0x21FF)  # arrows
    add_range(0x25A0, 0x26FF)  # geometric shapes / misc symbols (⚠ ✓ etc.)
    add_range(0x3000, 0x303F)  # CJK symbols and punctuation
    add_range(0xFF00, 0xFF65)  # full-width forms

    for code in range(0x4E00, 0x9FFF + 1):
        ch = chr(code)
        try:
            ch.encode("gb2312")
            chars.add(ch)
            continue
        except UnicodeEncodeError:
            pass
        # Big5 level 1 (lead byte A4-C6): the ~5400 common traditional chars.
        try:
            encoded = ch.encode("big5")
        except UnicodeEncodeError:
            continue
        if len(encoded) == 2 and encoded[0] <= 0xC6:
            chars.add(ch)

    for arb in (ROOT / "lib" / "l10n").glob("*.arb"):
        chars.update(arb.read_text(encoding="utf-8"))

    chars.update("0123456789")  # be explicit about digits
    return "".join(sorted(chars))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--font", required=True, help="NotoSansSC[wght].ttf")
    args = parser.parse_args()

    charset = build_charset()
    print(f"charset: {len(charset)} characters")

    with tempfile.TemporaryDirectory() as tmp:
        charset_file = Path(tmp) / "charset.txt"
        charset_file.write_text(charset, encoding="utf-8")

        for weight, name in WEIGHTS.items():
            instanced = Path(tmp) / f"NotoSansSC-{name}.ttf"
            subprocess.run(
                [sys.executable, "-m", "fontTools.varLib.instancer",
                 args.font, f"wght={weight}", "-o", str(instanced)],
                check=True,
            )
            out = OUT_DIR / f"CanoKeyCJK-{name}.ttf"
            subprocess.run(
                ["pyftsubset", str(instanced),
                 f"--text-file={charset_file}",
                 f"--output-file={out}",
                 "--name-IDs=*", "--name-legacy", "--name-languages=*",
                 "--layout-features=*", "--no-hinting",
                 "--notdef-outline", "--recalc-bounds",
                 "--drop-tables+=FFTM"],
                check=True,
            )
            rename(out, name)
            print(f"{out}: {out.stat().st_size / 1024 / 1024:.2f} MB")

    return 0


def rename(path: Path, subfamily: str) -> None:
    from fontTools.ttLib import TTFont

    font = TTFont(path)
    for record in font["name"].names:
        if record.nameID in (1, 16):
            value = "CanoKey CJK"
        elif record.nameID in (2, 17):
            value = subfamily
        elif record.nameID == 4:
            value = f"CanoKey CJK {subfamily}"
        elif record.nameID == 6:
            value = f"CanoKeyCJK-{subfamily}"
        else:
            continue
        record.string = value.encode(record.getEncoding())
    font.save(path)


if __name__ == "__main__":
    sys.exit(main())
