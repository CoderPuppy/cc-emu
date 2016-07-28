local prev, pl, luv, dir, T, stdin, utf8 = ...

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
for i = 0, 9 do
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

local processOutput
if pl.path.exists(pl.path.join(dir, '.termu', 'term-munging')) then
	local utf8 = prev.utf8 or prev.require 'utf8'
	function processOutput(out)
		local res = ''
		for c in out:gmatch '.' do
			if c == '\0' or c == '\9' or c == '\10' or c == '\13' or c == '\32' or c == '\128' or c == '\160' then
				res = res .. c
			else
				res = res .. utf8.char(0xE000 + c:byte())
			end
		end
		return res
	end
else
	function processOutput(out)
		return out
	end
end

local termNat
termNat = {
	clear = function()
		prev.io.write(T.clear())
	end;
	clearLine = function()
		prev.io.write(T.cup(cursorY - 1, 0))
		prev.io.write(T.clr_eol())
		termNat.setCursorPos(cursorX, cursorY)
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
		cursorX, cursorY = math.floor(x), math.floor(y)

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
		text = tostring(text or '')
		text = text:gsub('[\n\r]', '?')
		prev.io.write(processOutput(text))
		termNat.setCursorPos(cursorX + #text, cursorY)
	end;
	blit = function(text, textColors, backColors)
		text = text:gsub('[\n\r]', '?')

		if #text ~= #textColors or #text ~= #backColors then error('term.blit: text, textColors and backColors have to be the same length') end

		for i = 1, #text do
			termNat.setTextColor(ccColorFor(fromHexColor(textColors:sub(i, i))))
			termNat.setBackgroundColor(ccColorFor(fromHexColor(backColors:sub(i, i))))
			prev.io.write(processOutput(text:sub(i, i)))
		end
		cursorX = cursorX + #text
	end;
	setCursorBlink = function() end;
	scroll = function(n)
		n = n or 1
		local w, h = luv.tty_get_winsize(stdin)
		prev.io.write(n < 0 and T.cup(0, 0) or T.cup(h, w))
		local txt = T[n < 0 and 'ri' or 'ind']()
		prev.io.write(txt:rep(math.abs(n)))

		if n > 0 then
			prev.io.write(T.cup(h - n, 0))
			prev.io.write(T.clr_eos())
		elseif n < 0 then
			for i = 0, n do
				prev.io.write(T.cup(i, 0))
				prev.io.write(T.clr_eol())
			end
		end

		termNat.setCursorPos(cursorX, cursorY)
	end
}

prev.io.write(T.smcup())
prev.io.write(T.clear())

return termNat
