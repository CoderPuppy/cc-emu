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

local _keys = {
	nil; -- none
	string.byte '1';
	string.byte '2';
	string.byte '3';
	string.byte '4';
	string.byte '5';
	string.byte '6';
	string.byte '7';
	string.byte '8';
	string.byte '9';
	string.byte '0';
	string.byte '-';
	string.byte '=';
	263; -- backspace
	string.byte '\t';
	string.byte 'q';
	string.byte 'w';
	string.byte 'e';
	string.byte 'r';
	string.byte 't';
	string.byte 'y';
	string.byte 'u';
	string.byte 'i';
	string.byte 'o';
	string.byte 'p';
	string.byte '[';
	string.byte ']';
	13; -- enter
	30; -- CS` should work as left ctrl
	string.byte 'a';
	string.byte 's';
	string.byte 'd';
	string.byte 'f';
	string.byte 'g';
	string.byte 'h';
	string.byte 'j';
	string.byte 'k';
	string.byte 'l';
	string.byte ';';
	string.byte '\'';
	string.byte '`';
	nil; -- left shift
	string.byte '\\';
	string.byte 'z';
	string.byte 'x';
	string.byte 'c';
	string.byte 'v';
	string.byte 'b';
	string.byte 'n';
	string.byte 'm';
	string.byte ',';
	string.byte '.';
	string.byte '/';
	nil; -- right shift
	string.byte '*';
	nil; -- left alt
	string.byte ' ';
	nil; -- caps lock
	265; -- f1
	266; -- f2
	267; -- f3
	268; -- f4
	269; -- f5
	270; -- f6
	271; -- f7
	272; -- f8
	273; -- f9
	274; -- f10
	nil; -- numlock
	nil; -- scrolllock
	nil; -- num pad 7
	nil; -- num pad 8
	nil; -- num pad 9
	nil; -- num pad sub
	nil; -- num pad 4
	nil; -- num pad 5
	nil; -- num pad 6
	nil; -- num pad add
	nil; -- num pad 1
	nil; -- num pad 2
	nil; -- num pad 3
	nil; -- num pad 0
	nil; -- num pad dec
	nil; nil; nil;
	410; -- f11
	276; -- f12
	nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil;
	nil; -- f13
	nil; -- f14
	nil; -- f15
	nil; nil; nil; nil; nil; nil; nil; nil; nil;
	nil; -- kana
	nil; nil; nil; nil; nil; nil; nil; nil;
	nil; -- convert
	nil;
	nil; -- no convert
	nil;
	nil; -- yen
	nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil;
	nil; -- num pad equals
	nil; nil;
	string.byte '^';
	string.byte '@';
	string.byte ':';
	string.byte '_';
	nil; -- kanji
	nil; -- stop
	nil; -- ax
	nil;
	nil; -- num pad enter
	nil; -- right ctrl
	nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil;
	nil; -- num pad comma
	nil;
	nil; -- num pad divide
	nil; nil;
	nil; -- right alt
	nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil; nil;
	nil; -- pause
	nil;
	262; -- home
	259; -- up
	339; -- page up
	nil;
	260; -- left
	nil;
	261; -- right
	nil;
	360; -- end
	258; -- down
	338; -- page down
	331; -- insert
	330; -- delete
}

local keys = {}
for cc, real in pairs(_keys) do
	keys[real] = cc
end

local ignoredKeys = {
	[40] = true; -- open paren
	[41] = true; -- close paren
	[63] = true; -- question mark
	[20] = true; -- ^T
	[27] = true; -- ^[
}

-- Ignore uppercase
for i = 65, 90 do
	ignoredKeys[i] = true
end

-- Ignore ctrl keys
for i = 1, 22 do
	ignoredKeys[i] = true
end

local pl = {
	path = require 'pl.path';
	dir = require 'pl.dir';
	tablex = require 'pl.tablex';
	file = require 'pl.file'
}

local _bit = bit32 or require 'bit'
local unpack = _G.unpack or table.unpack

require 'luarocks.index'
local curses = require 'posix.curses'

local dirname = pl.path.dirname(debug.getinfo(1).source:match("@(.*)$"))

local prev = _G

return function(dir, ...)
	local cmd
	local stdscr

	local alive = true
	local eventQueue = {{n = select('#', ...), ...}}
	local timers = {}
	local termNat

	local env = {}
	function create(...)
		_ENV = env
		for _, name in prev.ipairs({'setmetatable', 'getmetatable', 'ipairs', 'string', 'tostring', 'tonumber', 'select', 'getfenv', 'setfenv', 'table', 'pcall', 'xpcall', 'type', 'error', 'pairs', 'loadstring', 'load', 'math', 'rawset', 'rawget', 'coroutine', '_VERSION', 'next'}) do
			env[name] = prev[name]
		end
		_ENV.unpack = unpack
		bit = _bit
		_G = getfenv and getfenv() or _ENV

		local runRom
		do -- FS
			local romPath = pl.path.normpath(pl.path.join(dirname, 'cc'))
			local function findRomFile(path)
				return pl.path.normpath(pl.path.join(romPath, path))
			end

			local function betterifyPath(path)
				local oldPath
				while oldPath ~= path do
					oldPath = path

					if path:sub(1, 1) == '/' then
						path = path:sub(2)
					end

					if path:sub(1, 2) == './' then
						path = path:sub(2)
					end
				end

				return path
			end

			local function findPath(path)
				path = betterifyPath(path)

				if path:sub(1, 3) == 'rom' then
					return findRomFile(path)
				end

				return pl.path.normpath(pl.path.join(dir, path))
			end

			function runRom(path, ...)
				local fn
				if setfenv then
					fn = prev.loadfile(findRomFile(path))
					setfenv(fn, _G)
				else
					fn = prev.loadfile(findRomFile(path), 'bt', _G)
				end
				return fn(...)
			end

			fs = {
				isReadOnly = function(path)
					return betterifyPath(path):sub(1, 3) == 'rom'
				end;

				delete = function(path)
					path = findPath(path)
					pl.file.delete(path)
				end;

				move = function(src, dest)
					src = findPath(src)
					dest = findPath(dest)
					pl.file.move(src, dest)
				end;

				copy = function(src, dest)
					src = findPath(src)
					dest = findPath(dest)
					pl.file.copy(src, dest)
				end;

				list = function(path)
					path = findPath(path)
					local files = {}

					if path == dir then
						files[#files + 1] = 'rom'
					end

					for file in pl.path.dir(path) do
						files[#files + 1] = file
					end

					return pl.tablex.map(pl.path.basename, files)
				end;

				open = function(path, mode)
					local file = prev.io.open(findPath(path), mode)

					if file == nil then return nil end

					local h = {}

					if mode == 'r' then
						function h.readAll()
							return file:read('*a')
						end

						function h.readLine()
							return file:read('*l')
						end
					elseif mode == 'w' or mode == 'a' then
						function h.write(data)
							file:write(data)
						end

						function h.writeLine(data)
							file:write(data)
							file:write('\n')
						end

						function h.flush()
							file:flush()
						end
					end

					function h.close()
						file:close()
					end

					return h
				end;

				exists = function(path)
					return pl.path.exists(findPath(path)) ~= false
				end;

				isDir = function(path)
					return pl.path.isdir(findPath(path))
				end;

				combine = function(a, b)
					local function doIt()
						if a == '' then
							a = '/'
						end

						if a:sub(1, 1) ~= '/' and a:sub(1, 2) ~= './' then
							a = '/' .. a
						end

						if b == '.' then
							return a
						end

						if a == '/' and b == '..' then
							return '..'
						end

						if a:sub(-2) == '..' and b == '..' then
							return a .. '/..'
						end

						return pl.path.normpath(pl.path.join(a, b))
					end

					local res = doIt()

					if res:sub(1, 1) == '/' then
						res = res:sub(2)
					end

					return res
				end;

				getName = function(path) return pl.path.basename(path) end
			}
		end

		do -- OS
			os = {
				queueEvent = function(ev, ...)
					eventQueue[#eventQueue + 1] = { n = select('#', ...) + 1, ev, ... }
				end;
				startTimer = function(time)
					local id = #timers + 1
					timers[id] = { prev.os.time(), time }
					return id
				end;
				clock = prev.os.clock;
				time = prev.os.time;
				shutdown = function()
					alive = false
					coroutine.yield()
				end
			}
		end

		do -- Term
			local cursorX, cursorY = 1, 1
			local textColor, backColor = 0, 15
			local log2 = math.log(2)

			local function colorId(fg, bg)
				return bit.lshift(bit.band(fg, 15), 4) + bit.band(bg, 15)
			end

			local function ccColorFor(c)
				if type(c) ~= 'number' or c < 0 or c > 15 then
					error('that\'s not a valid color: ' .. tostring(c))
				end

				return math.pow(2, c)
			end

			local function cursesColorFor(c)
				if type(c) ~= 'number' or c < 0 or c > 15 then
					error('that\'s not a valid color: ' .. tostring(c))
				end

				c = ccColorFor(c)

				if type(_colors[c]) ~= 'string' then
					error('no name for that color: ' .. tostring(c))
				end

				c = _colors[c]

				if c == 'orange' then
					c = curses.COLOR_RED
				elseif c == 'lightBlue' then
					c = curses.COLOR_BLUE
				elseif c == 'lime' then
					c = curses.COLOR_GREEN
				elseif c == 'pink' or c == 'purple' then
					c = curses.COLOR_MAGENTA
				elseif c == 'gray' or c == 'lightGray' then
					c = curses.COLOR_BLACK
				elseif c == 'brown' then
					c = curses.COLOR_YELLOW
				else
					c = curses['COLOR_' .. c:upper()]
				end

				return c
			end

			local function fromHexColor(h)
				return hex[h] or error('not a hex color: ' .. tostring(h))
			end

			local curAttr = 0
			local function updateColor()
				stdscr:attroff(curAttr)

				curAttr = curses.color_pair(colorId(textColor, backColor))

				local name = _colors[math.pow(2, textColor)]

				if name == 'orange' or name == 'lightBlue' or name == 'lime' or name == 'yellow' then
					-- curAttr = bit.bor(curAttr, curses.A_BOLD)
					stdscr:attron(curses.A_BOLD)
				else
					stdscr:attroff(curses.A_BOLD)
				end

				stdscr:attron(curAttr)
			end

			for fg = 0, 15 do
				for bg = 0, 15 do
					curses.init_pair(colorId(fg, bg), cursesColorFor(fg), cursesColorFor(bg))
				end
			end

			local termNat
			termNat = {
				clear = function() stdscr:clear() end;
				clearLine = function()
					stdscr:move(cursorY - 1, 0)
					stdscr:clrtoeol()
					stdscr:move(cursorY - 1, cursorX - 1)
				end;
				isColour = function() return termNat.isColor() end;
				isColor = function() return curses.has_colors() end;
				getSize = function()
					local y, x = stdscr:getmaxyx()
					return x, y
					-- return 52, 19
				end;
				getCursorPos = function() return cursorX, cursorY end;
				setCursorPos = function(x, y)
					if type(x) ~= 'number' or type(y) ~= 'number' then error('term.setCursorPos expects number, number, got: ' .. type(x) .. ', ' .. type(y)) end
					cursorX, cursorY = x, y

					stdscr:move(y - 1, x - 1)
					stdscr:refresh()
				end;
				setTextColour = function(...) return termNat.setTextColor(...) end;
				setTextColor = function(c)
					textColor = math.log(c) / log2

					updateColor()
				end;
				getTextColour = function(...) return termNat.getTextColor(...) end;
				getTextColor = function()
					return ccColorFor(textColor)
				end;
				setBackgroundColour = function(...) return termNat.setBackgroundColor(...) end;
				setBackgroundColor = function(c)
					backColor = math.log(c) / log2

					updateColor()
				end;
				getBackgroundColour = function(...) return termNat.getBackgroundColor(...) end;
				getBackgroundColor = function()
					return ccColorFor(backColor)
				end;
				write = function(text)
					text = text:gsub('[\n\r]', '?')

					stdscr:addstr(text)

					termNat.setCursorPos(cursorX + #text, cursorY)
				end;
				blit = function(text, textColors, backColors)
					text = text:gsub('[\n\r]', '?')

					if #text ~= #textColors or #text ~= #backColors then error('term.blit: text, textColors and backColors have to be the same length') end

					for i = 1, #text do
						textColor = fromHexColor(textColors:sub(i, i))
						backColor = fromHexColor(backColors:sub(i, i))
						updateColor()
						stdscr:mvaddstr(cursorY - 1, cursorX + i - 2, text:sub(i, i))
					end
				end;
				setCursorBlink = function() end;
				scroll = function(n)
					stdscr:scrl(n)

					if n > 0 then
						stdscr:move(19 - n, 0)
						stdscr:clrtobot()
					elseif n < 0 then
						for i = 0, n do
							stdscr:move(i, 0)
							stdscr:clrtoeol()
						end
					end

					termNat.setCursorPos(cursorX, cursorY)
				end
			}

			term = termNat

			updateColor()
		end--]]

		--[[do --term
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
			term = termNat
		end--]]

		do -- RS
			redstone = {
				getSides = function() return { 'top', 'bottom', 'left', 'right', 'front', 'back' } end;
				setOutput = function() end;
			}
			rs = redstone
		end

		do -- Peripheral
			peripheral = {
				getNames = function() return {} end;
				isPresent = function() return false end;
				getType = function() return nil end;
			}
		end

		stdscr:clear()
		stdscr:move(0, 0)

		runRom('bios.lua', ...)
	end
	if setfenv then setfenv(create, env) end

	local co = coroutine.create(create)

	curses.initscr()
	curses.start_color()
	stdscr = curses.stdscr()
	curses.echo(false)
	curses.nl(false)
	curses.raw(true)
	stdscr:keypad(true)
	stdscr:timeout(100)
	stdscr:scrollok(false)
	stdscr:clear()
	stdscr:refresh()

	local eventFilter

	while alive and coroutine.status(co) ~= 'dead' do
		local clock = os.time()
		
		for id, time in pairs(timers) do
			-- env.print(id, clock, env.textutils.serialize(time), os.difftime(clock, time[1]))
			if os.difftime(clock, time[1]) >= time[2] then
				-- env.print(id)
				eventQueue[#eventQueue + 1] = { 'timer', id }
				timers[id] = nil
			end
		end

		local char = stdscr:getch()

		if type(char) == 'number' then
			if char == 3 then
				-- print('^c')
				alive = false
				break
			end

			if char == 20 then
				eventQueue[#eventQueue + 1] = { 'terminate' }
			end

			if char > 9 and char < 127 and char ~= 13 and char ~= 26 and char ~= 20 and char ~= 27 and char ~= 30 then
				eventQueue[#eventQueue + 1] = { 'char', string.char(char) }
			end

			if keys[char] then
				local key = keys[char]
				eventQueue[#eventQueue + 1] = { 'key', key }

				-- if (key >= keys[string.byte '1'] and key <= keys[string.byte '=']) or
				--    (key >= keys[string.byte '\t'] and key <= keys[string.byte 'p']) or
				--    (key >= keys[string.byte 'a'] and key <= keys[string.byte '`']) or
				--    (key >= keys[string.byte '\\'] and key <= keys[string.byte '/']) or
				--    (key == keys[string.byte '*']) or
				--    (key == keys[string.byte ' ']) or
				--    (key >= keys[string.byte '^'] and key <= keys[string.byte '_']) then
				-- 	thread:queue('char', string.char(char))
				-- end
			elseif ignoredKeys[char] == nil then
				env.print('unknown key: ' .. tostring(char))
			end
		end

		while #eventQueue >= 1 do
			local ev = table.remove(eventQueue, 1)
			if eventFilter == nil or ev[1] == eventFilter or ev[1] == 'terminate' then
				-- debug.sethook(co, function()
				-- 	error('Too long without yielding', 2)
				-- end, '', 35000)
				local ok, err = coroutine.resume(co, unpack(ev, 1, ev.n))
				-- debug.sethook(co)
				if ok then
					eventFilter = err
				else
					stdscr:clear()
					-- red on black
					env.term.setTextColor(math.pow(2, 14))
					env.term.setBackgroundColor(math.pow(2, 0))
					stdscr:mvaddstr(0, 0, err)
					stdscr:mvaddstr(1, 0, "Press Control-c to exit")
					while stdscr:getch() ~= 3 do end
					error(err)
				end
				break
			end
		end

		stdscr:refresh()
	end

	-- while stdscr:getch() ~= 3 do end

	curses.echo(true)
	curses.nl(true)
	curses.raw(false)
	stdscr:keypad(false)
	stdscr:scrollok(false)

	curses.endwin()
end
