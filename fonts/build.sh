#!/bin/sh
python3 create.py
convert -crop 6x9 termFont.png glyph_%d.png
python3 pixel2svg/pixel2svg.py glyph_*.png
rm glyph_*.png
python3 add-svgs.py
rm glyph_*.svg
python3 generate.py
