local cursorPos = {0, 0}
local fg = 1
local bg = 32768
local blink = true
local termNat; termNat = {
	isColor = function() return false end;
	isColour = function() return false end;
	getCursorPos = function() return unpack(cursorPos) end;
	setCursorPos = function(x, y) cursorPos = {x, y} end;
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
	write = function(str) prev.io.write(str) end;
	scroll = function() end;
}
return termNat
