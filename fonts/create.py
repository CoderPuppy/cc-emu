import fontforge
import os.path

if os.path.exists('input.otf'):
    font = fontforge.open('input.otf')
    font.fontname = 'Termu-' + font.fontname
    font.familyname = 'Termu ' + font.familyname
    font.fullname = 'Termu: ' + font.fullname
else:
    font = fontforge.font()
    font.fontname = 'Termu'
    font.familyname = 'Termu'
    font.fullname = 'Termu'
font.encoding = 'UnicodeFull'
font.save('termu.sfd')
