local prev = ...

local cursorX, cursorY = 0, 0
local fg = 1
local bg = 32768
local blink = true
local termNat; termNat = {
	isColor = function() return true end;
	isColour = function() return true end;
	getCursorPos = function() return cursorX, cursorY end;
	setCursorPos = function(x, y) cursorX, cursorY = x, y end;
	getBackgroundColor = function() return bg end;
	setBackgroundColor = function(c) bg = c end;
	getBackgroundColour = function() return bg end;
	setBackgroundColour = function(c) bg = c end;
	getTextColor = function() return fg end;
	setTextColor = function(c) fg = c end;
	getTextColour = function() return fg end;
	setTextColour = function(c) fg = c end;
	getCursorBlink = function() return blink end;
	setCursorBlink = function(b) blink = b end;
	getSize = function() return 80, 19 end;
	write = function(str) prev.io.write(str); termNat.setCursorPos(cursorX + #str, cursorY) end;
	-- write = function() end;
	blit = function(text, fg, bg) prev.io.write(text); termNat.setCursorPos(cursorX + #text, cursorY) end;
	clear = function() end;
	clearLine = function() end;
	scroll = function() end;
}
return termNat
