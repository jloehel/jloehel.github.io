#!/usr/bin/env python3
"""Drop the OFL Reserved Font Name 'Source' from a subset font's naming records.

Subsetting produces a "Modified Version" under the SIL Open Font License, which
may not use the reserved name. Usage: rename-font.py <font.woff2> <sans|mono>
"""
import sys
from fontTools.ttLib import TTFont

RENAMES = {
    "sans": (("Source Sans 3", "JL Sans"), ("SourceSans3", "JLSans")),
    "mono": (("Source Code Pro", "JL Mono"), ("SourceCodePro", "JLMono")),
}
NAMING_IDS = {1, 3, 4, 6, 16, 17}  # family, unique, full, postscript, typographic family/subfamily

path, key = sys.argv[1], sys.argv[2]
font = TTFont(path)
for record in font["name"].names:
    if record.nameID in NAMING_IDS:
        text = record.toUnicode()
        for old, new in RENAMES[key]:
            text = text.replace(old, new)
        record.string = text
font.save(path)
