import re
import fontforge
import psMat

font = fontforge.open('termu.sfd')

for i in range(256):
    glyph_name = 'uni' + re.sub('^0x', '', hex(0xe000 + i))
    glyph = font.createMappedChar(glyph_name)
    width = glyph.width
    glyph.clear()
    glyph.importOutlines('glyph_' + str(i) + '.svg')
    glyph.transform(psMat.scale(6/8, 9/11))
    glyph.transform((3.5087777777778, 0.0, 0.0, 3.5087719298246, 0, -640 -978.421 -22.160684210526 -7.5187857142857))
    glyph.width = 842.10666666667

font.save('termu.sfd')
