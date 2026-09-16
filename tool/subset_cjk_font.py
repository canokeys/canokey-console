#!/usr/bin/env python3
"""Subset Noto Sans SC into the bundled 'CanoKey CJK' font.

This script is part of the build: it regenerates assets/fonts/CanoKeyCJK-*.ttf
whenever the source font, the character set, or this script changes, and skips
the work when everything is up to date. The generated fonts are gitignored —
run this script (directly or via CI) before `flutter pub get` / build / test.

Character set: printable ASCII, Latin-1, general/CJK punctuation, full-width
forms, common arrows and symbols, every character used by the ARB
localizations in lib/l10n, all CJK ideographs encodable in GB2312
(simplified), and Big5 level 1 (common traditional). User-supplied content
outside this set falls back to the engine font fallback (web) or system fonts
(native).

Usage: python3 tool/subset_cjk_font.py   (requires: pip install fonttools)
"""

import hashlib
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "fonts"
CACHE_DIR = ROOT / "build" / "font-cache"
STAMP_FILE = CACHE_DIR / "canockey-cjk.stamp.json"

SOURCE_URL = (
    "https://raw.githubusercontent.com/google/fonts/"
    "2894aab31764f10f29c421bdfd2340d3b382d384/"
    "ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf"
)
SOURCE_SHA256 = "a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da"

WEIGHTS = {400: "Regular", 700: "Bold"}
OUTPUTS = [OUT_DIR / f"CanoKeyCJK-{name}.ttf" for name in WEIGHTS.values()]


def build_charset() -> str:
    chars = set()

    def add_range(start: int, end: int) -> None:
        chars.update(chr(c) for c in range(start, end + 1))

    add_range(0x20, 0x7E)      # printable ASCII
    add_range(0xA0, 0xFF)      # Latin-1 supplement
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

    for arb in sorted((ROOT / "lib" / "l10n").glob("*.arb")):
        chars.update(arb.read_text(encoding="utf-8"))

    return "".join(sorted(chars))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fetch_source() -> Path:
    """Download the pinned Noto Sans SC variable font into the cache."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cached = CACHE_DIR / "NotoSansSC-wght.ttf"
    if cached.exists() and sha256(cached) == SOURCE_SHA256:
        return cached
    print(f"Downloading Noto Sans SC from {SOURCE_URL}")
    request = urllib.request.Request(
        SOURCE_URL, headers={"User-Agent": "canokey-console-build"})
    data = urllib.request.urlopen(request, timeout=120).read()
    digest = hashlib.sha256(data).hexdigest()
    if digest != SOURCE_SHA256:
        raise SystemExit(
            f"source font hash mismatch: got {digest}, want {SOURCE_SHA256}. "
            "The pinned upstream font changed; verify and update SOURCE_URL "
            "and SOURCE_SHA256 in this script.")
    cached.write_bytes(data)
    return cached


def compute_stamp(source: Path, charset: str) -> dict:
    return {
        "source": sha256(source),
        "script": sha256(Path(__file__)),
        "charset": hashlib.sha256(charset.encode("utf-8")).hexdigest(),
        "weights": [[w, n] for w, n in WEIGHTS.items()],
    }


def is_up_to_date(stamp: dict) -> bool:
    if not all(p.exists() for p in OUTPUTS) or not STAMP_FILE.exists():
        return False
    try:
        return json.loads(STAMP_FILE.read_text()) == stamp
    except (ValueError, OSError):
        return False


def rename_family(font, subfamily: str) -> None:
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


def main() -> int:
    try:
        import fontTools  # noqa: F401
    except ImportError:
        raise SystemExit("fonttools is required: python3 -m pip install fonttools")

    source = fetch_source()
    charset = build_charset()
    stamp = compute_stamp(source, charset)

    if is_up_to_date(stamp):
        print("CanoKey CJK fonts are up to date, skipping subsetting")
        return 0

    print(f"Subsetting {len(charset)} characters into "
          f"{len(WEIGHTS)} weight(s)")

    from fontTools import subset
    from fontTools.ttLib import TTFont
    from fontTools.varLib import instancer

    for weight, name in WEIGHTS.items():
        font = TTFont(source)
        instancer.instantiateVariableFont(font, {"wght": weight}, inplace=True)

        options = subset.Options()
        options.name_IDs = ["*"]
        options.name_legacy = True
        options.name_languages = ["*"]
        options.layout_features = ["*"]
        options.hinting = False
        options.notdef_outline = True
        options.recalc_bounds = True
        options.drop_tables += ["FFTM"]

        subsetter = subset.Subsetter(options)
        subsetter.populate(text=charset)
        subsetter.subset(font)

        out = OUT_DIR / f"CanoKeyCJK-{name}.ttf"
        font.recalcTimestamp = False  # keep builds reproducible
        rename_family(font, name)
        font.save(out)
        print(f"{out}: {out.stat().st_size / 1024 / 1024:.2f} MB")

    STAMP_FILE.write_text(json.dumps(stamp, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
