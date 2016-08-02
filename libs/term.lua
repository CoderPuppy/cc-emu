local prev, pl, luv, dir, T, stdin, exit_seq = ...

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

local color_escapes = {
	fg = {
		    white = T.setaf(7);
		   orange = T.setaf(3);
		  magenta = T.setaf(5);
		lightBlue = T.setaf(4);
		   yellow = T.setaf(3);
		     lime = T.setaf(2);
		     pink = T.setaf(5);
		     gray = T.setaf(0);
		lightGray = T.setaf(0);
		     cyan = T.setaf(6);
		   purple = T.setaf(5);
		     blue = T.setaf(4);
		    brown = T.setaf(3);
		    green = T.setaf(2);
		      red = T.setaf(1);
		    black = T.setaf(0);
	};
	bg = {
		    white = T.setab(7);
		   orange = T.setab(3);
		  magenta = T.setab(5);
		lightBlue = T.setab(4);
		   yellow = T.setab(3);
		     lime = T.setab(2);
		     pink = T.setab(5);
		     gray = T.setab(0);
		lightGray = T.setab(0);
		     cyan = T.setab(6);
		   purple = T.setab(5);
		     blue = T.setab(4);
		    brown = T.setab(3);
		    green = T.setab(2);
		      red = T.setab(1);
		    black = T.setab(0);
	};
}
do
	local fg_dir = pl.path.join(dir, '.termu', 'term-colors', 'fg')
	if pl.path.isdir(fg_dir) then
		for color in pl.path.dir(fg_dir) do
			local path = pl.path.join(fg_dir, color)
			if id ~= '.' and id ~= '..' and pl.path.isfile(path) then
				local h = prev.io.open(path)
				color_escapes.fg[color] = h:read '*a'
				h:close()
			end
		end
	end

	local bg_dir = pl.path.join(dir, '.termu', 'term-colors', 'bg')
	if pl.path.isdir(bg_dir) then
		for color in pl.path.dir(bg_dir) do
			local path = pl.path.join(bg_dir, color)
			if id ~= '.' and id ~= '..' and pl.path.isfile(path) then
				local h = prev.io.open(path)
				color_escapes.bg[color] = h:read '*a'
				h:close()
			end
		end
	end
end

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
		local w, h = termNat.getSize()
		for l = 0, h - 1 do
			prev.io.write(T.cup(l, 0))
			prev.io.write((' '):rep(w))
		end
		termNat.setCursorPos(cursorX, cursorY)
	end;
	clearLine = function()
		local w, h = termNat.getSize()
		prev.io.write(T.cup(cursorY - 1, 0))
		prev.io.write((' '):rep(w))
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
		local oldX, oldY = cursorX, cursorY
		cursorX, cursorY = math.floor(x), math.floor(y)

		local w, h = luv.tty_get_winsize(stdin)
		if cursorY < 1 or cursorY > h or cursorX < 1 or cursorX > w then
			prev.io.write(T.cursor_invisible())
		else
			if oldY < 1 or oldY > h or oldX < 1 or oldX > w then
				prev.io.write(T.cursor_normal())
			end
			prev.io.write(T.cup(cursorY - 1, cursorX - 1))
		end
	end;
	setTextColour = function(...) return termNat.setTextColor(...) end;
	setTextColor = function(c)
		textColor = math.log(c) / log2

		prev.io.write(color_escapes.fg[_colors[c] ])
	end;
	getTextColour = function(...) return termNat.getTextColor(...) end;
	getTextColor = function()
		return ccColorFor(textColor)
	end;
	setBackgroundColour = function(...) return termNat.setBackgroundColor(...) end;
	setBackgroundColor = function(c)
		backColor = math.log(c) / log2

		prev.io.write(color_escapes.bg[_colors[c] ])
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

		-- if n > 0 then
		-- 	prev.io.write(T.cup(h - n, 0))
		-- 	prev.io.write(T.clr_eos())
		-- elseif n < 0 then
		-- 	for i = 0, n do
		-- 		prev.io.write(T.cup(i, 0))
		-- 		prev.io.write((' '):rep(w))
		-- 	end
		-- end

		termNat.setCursorPos(cursorX, cursorY)
	end
}

prev.io.write(T.smcup())
termNat.setTextColor(1)
termNat.setBackgroundColor(32768)
termNat.clear()
prev.io.flush()

exit_seq[#exit_seq + 1] = function()
	prev.io.write(T.rmcup())
	prev.io.flush()
end

return termNat
