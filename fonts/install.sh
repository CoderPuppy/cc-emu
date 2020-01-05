#!/bin/sh

cp termu.otf /usr/share/fonts/local/termu.otf
mkfontscale /usr/share/fonts/local
mkfontdir /usr/share/fonts/local
fc-cache -s
xset fp rehash
