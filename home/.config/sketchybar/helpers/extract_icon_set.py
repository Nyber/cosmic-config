#!/usr/bin/env python3
"""Extract valid icon ligature names from sketchybar-app-font and output icon_set.lua."""

import sys
from pathlib import Path

try:
    from fontTools.ttLib import TTFont
except ImportError:
    print("fonttools not installed, skipping icon_set.lua generation", file=sys.stderr)
    sys.exit(0)

FONT_PATH = Path.home() / "Library" / "Fonts" / "sketchybar-app-font.ttf"
OUTPUT = Path(__file__).parent / "icon_set.lua"


def extract_ligature_names(font_path):
    """Extract ligature names from the font's GSUB table."""
    font = TTFont(str(font_path))
    names = set()

    if "GSUB" not in font:
        print("No GSUB table found in font", file=sys.stderr)
        sys.exit(1)

    gsub = font["GSUB"].table
    cmap = font.getBestCmap()
    # Build reverse cmap: glyph name -> unicode char
    glyph_to_char = {}
    for codepoint, glyph_name in cmap.items():
        glyph_to_char[glyph_name] = chr(codepoint)

    for feature in gsub.FeatureList.FeatureRecord:
        if feature.FeatureTag != "liga":
            continue
        for lookup_idx in feature.Feature.LookupListIndex:
            lookup = gsub.LookupList.Lookup[lookup_idx]
            for subtable in lookup.SubTable:
                if hasattr(subtable, "ligatures"):
                    for first_glyph, ligatures in subtable.ligatures.items():
                        first_char = glyph_to_char.get(first_glyph, "")
                        for lig in ligatures:
                            components = [first_char] + [
                                glyph_to_char.get(g, "") for g in lig.Component
                            ]
                            name = "".join(components)
                            if name:
                                names.add(name)

    font.close()
    return names


def main():
    if not FONT_PATH.exists():
        print(f"Font not found at {FONT_PATH}, skipping", file=sys.stderr)
        sys.exit(0)

    names = extract_ligature_names(FONT_PATH)
    if not names:
        print("No ligature names extracted", file=sys.stderr)
        sys.exit(1)

    # Strip surrounding colons — font ligatures use :name: format
    bare_names = set()
    for name in names:
        bare = name.strip(":")
        if bare:
            bare_names.add(bare)

    lines = ["return {"]
    for name in sorted(bare_names):
        lines.append(f'  ["{name}"] = true,')
    lines.append("}")
    lines.append("")

    OUTPUT.write_text("\n".join(lines))
    print(f"Generated {OUTPUT} with {len(names)} icon names")


if __name__ == "__main__":
    main()
