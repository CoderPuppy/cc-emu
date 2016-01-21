local prev, luv, T, stdin = ...

local _colors = {
	[1] = "white";
	[2] = "orange";
	[4] = "magenta";
	[8] = "lightBlue";
	[16] = "yellow";
	[32] = "lime";
	[64] = "pink";
	[128] = "gray";
	[256] = "lightGray";
	[512] = "cyan";
	[1024] = "purple";
	[2048] = "blue";
	[4096] = "brown";
	[8192] = "green";
	[16384] = "red";
	[32768] = "black";
}
local ansiColors = {
	    white = {7, false}; -- white
	   orange = {1,  true}; -- bright red
	  magenta = {5, false}; -- magenta
	lightBlue = {4,  true}; -- bright blue
	   yellow = {3,  true}; -- bright yellow
	     lime = {2,  true}; -- bright green
	     pink = {5, false}; -- magenta
	     gray = {0, false}; -- black
	lightGray = {0, false}; -- black
	     cyan = {6, false}; -- cyan
	   purple = {5, false}; -- magenta
	     blue = {4, false}; -- blue
	    brown = {3, false}; -- yellow
	    green = {2, false}; -- green
	      red = {1, false}; -- red
	    black = {0, false}; -- black
}
local hex = {
	['a'] = 10;
	['b'] = 11;
	['c'] = 12;
	['d'] = 13;
	['e'] = 14;
	['f'] = 15;
}
for i = 0, 7 do
	hex[tostring(i)] = i
end

local cursorX, cursorY = 1, 1
local textColor, backColor = 0, 15
local log2 = math.log(2)

local function ccColorFor(c)
	if type(c) ~= 'number' or c < 0 or c > 15 then
		error('that\'s not a valid color: ' .. tostring(c))
	end

	return math.pow(2, c)
end

local function fromHexColor(h)
	return hex[h] or error('not a hex color: ' .. tostring(h))
end

local termNat
termNat = {
	clear = function()
		prev.io.write(T.clear())
	end;
	clearLine = function()
		termNat.setCursorPos(cursorY, 1)
		prev.io.write(T.el)
		termNat.setCursorPos(cursorY, cursorX)
	end;
	isColour = function() return true end;
	isColor = function() return true end;
	getSize = function()
		return luv.tty_get_winsize(stdin)
		-- return 52, 19
	end;
	getCursorPos = function() return cursorX, cursorY end;
	setCursorPos = function(x, y)
		if type(x) ~= 'number' or type(y) ~= 'number' then error('term.setCursorPos expects number, number, got: ' .. type(x) .. ', ' .. type(y)) end
		cursorX, cursorY = x, y

		prev.io.write(T.cup(cursorY - 1, cursorX - 1))
	end;
	setTextColour = function(...) return termNat.setTextColor(...) end;
	setTextColor = function(c)
		textColor = math.log(c) / log2

		local color = ansiColors[_colors[c] ]
		prev.io.write(T[color[2] and 'bold' or 'sgr0']())
		prev.io.write(T.setaf(color[1]))
	end;
	getTextColour = function(...) return termNat.getTextColor(...) end;
	getTextColor = function()
		return ccColorFor(textColor)
	end;
	setBackgroundColour = function(...) return termNat.setBackgroundColor(...) end;
	setBackgroundColor = function(c)
		backColor = math.log(c) / log2

		prev.io.write(T.setab(ansiColors[_colors[c] ][1]))
	end;
	getBackgroundColour = function(...) return termNat.getBackgroundColor(...) end;
	getBackgroundColor = function()
		return ccColorFor(backColor)
	end;
	write = function(text)
		text = text:gsub('[\n\r]', '?')
		prev.io.write(text)
		termNat.setCursorPos(cursorX + #text, cursorY)
	end;
	blit = function(text, textColors, backColors)
		text = text:gsub('[\n\r]', '?')

		if #text ~= #textColors or #text ~= #backColors then error('term.blit: text, textColors and backColors have to be the same length') end

		for i = 1, #text do
			termNat.setTextColor(ccColorFor(fromHexColor(textColors:sub(i, i))))
			termNat.setBackgroundColor(ccColorFor(fromHexColor(backColors:sub(i, i))))
			prev.io.write(text:sub(i, i))
		end
		cursorX = cursorX + #text
	end;
	setCursorBlink = function() end;
	scroll = function(n)
		prev.io.write(T.cup(0, 0))
		local txt = T[n < 0 and 'ri' or 'ind']()
		prev.io.write(txt:rep(math.abs(n)))

		-- if n > 0 then
		-- 	stdscr:move(19 - n, 0)
		-- 	stdscr:clrtobot()
		-- elseif n < 0 then
		-- 	for i = 0, n do
		-- 		stdscr:move(i, 0)
		-- 		stdscr:clrtoeol()
		-- 	end
		-- end

		termNat.setCursorPos(cursorX, cursorY)
	end
}

return termNat
