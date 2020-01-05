#!/bin/sh
echo "# create.py"
python3 create.py
echo "# convert 1"
convert -crop 128x176+0+0 +repage termFont.png termFont.1.png
echo "# convert 2"
convert -crop 8x11 termFont.1.png glyph_%d.png
echo "# pixel2svg.py"
python3 pixel2svg/pixel2svg.py glyph_*.png
rm glyph_*.png
echo "# add-svgs.py"
python3 add-svgs.py
rm glyph_*.svg
echo "# generate.py"
python3 generate.py
