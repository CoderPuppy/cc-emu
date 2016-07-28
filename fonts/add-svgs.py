import re
import fontforge

font = fontforge.open('termu.sfd')

for i in range(256):
    glyph_name = 'uni' + re.sub('^0x', '', hex(0xe000 + i))
    glyph = font.createMappedChar(glyph_name)
    width = glyph.width
    glyph.clear()
    glyph.importOutlines('glyph_' + str(i) + '.svg')
    glyph.transform((2.34, 0.0, 0.0, 2.34, 600/2 - 561.6/2, -1099))
    glyph.width = 600

font.save('termu.sfd')
