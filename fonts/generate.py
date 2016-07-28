import fontforge

font = fontforge.open('termu.sfd')
font.generate('termu.otf')
