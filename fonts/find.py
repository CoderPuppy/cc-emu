import re
import fontforge

font = fontforge.open('test.sfd')

for i in range(0xF8FF - 0xE000):
    glyph = font.createMappedChar('uni' + re.sub('^0x', '', hex(0xE000 + i)))
    # if glyph.width == 600:
    print(glyph.glyphname, glyph.width)
