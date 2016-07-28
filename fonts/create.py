import fontforge

font = fontforge.open('input.otf')
font.fontname = 'Termu-' + font.fontname
font.familyname = 'Termu: ' + font.familyname
font.fullname = 'Termu: ' + font.fullname
font.save('termu.sfd')
