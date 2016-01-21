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
local ansiColor = {
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

local _keys = {
	nil; -- none
	{'1', '!'};
	{'2', '@'};
	{'3', '#'};
	{'4', '$'};
	{'5', '%'};
	{'6', '^'};
	{'7', '&'};
	{'8', '*'};
	{'9', '('};
	{'0', ')'};
	{'-', '_'};
	{'=', '+'};
	'\8'; -- backspace
	{'\9', '\27[Z'};
	{'q', 'Q'};
	{'w', 'W'};
	{'e', 'E'};
	{'r', 'R'};
	{'t', 'T'};
	{'y', 'Y'};
	{'u', 'U'};
	{'i', 'I'};
	{'o', 'O'};
	{'p', 'P'};
	{'[', '{'};
	{']', '}'};
	'\13'; -- enter
	'\30'; -- CS` should work as left ctrl
	{'a', 'A'};
	{'s', 'S'};
	{'d', 'D'};
	{'f', 'F'};
	{'g', 'G'};
	{'h', 'H'};
	{'j', 'J'};
	{'k', 'K'};
	{'l', 'L'};
	{';', ':'};
	{'\'', '"'};
	{'`', '~'};
	nil; -- left shift
	{'\\', '|'};
	{'z', 'Z'};
	{'x', 'X'};
	{'c', 'C'};
	{'v', 'V'};
	{'b', 'B'};
	{'n', 'N'};
	{'m', 'M'};
	{',', '<'};
	{'.', '>'};
	{'/', '?'};
	nil; -- right shift
	nil; -- multiply?
	nil; -- left alt
	' ';
	nil; -- caps lock
	'\27OP'; -- f1
	'\27OQ'; -- f2
	'\27OR'; -- f3
	'\27OS'; -- f4
	'\27[15~'; -- f5
	'\27[17~'; -- f6
	'\27[18~'; -- f7
	'\27[19~'; -- f8
	'\27[20~'; -- f9
	'\27[21~'; -- f10
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
	'\27[23~'; -- f11 -- TODO: this could be wrong
	'\27[24~'; -- f12
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- f13
	nil; -- f14
	nil; -- f15
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- kana
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- convert
	nil;
	nil; -- no convert
	nil;
	nil; -- yen
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- num pad equals
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- kanji
	nil; -- stop
	nil; -- ax
	nil;
	nil; -- num pad enter
	nil; -- right ctrl
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- num pad comma
	nil;
	nil; -- num pad divide
	nil;
	nil;
	nil; -- right alt
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- pause
	nil;
	'\27[1~'; -- home
	'\27OA'; -- up
	'\27[5~'; -- page up
	nil;
	'\27OD'; -- left
	nil;
	'\27OC'; -- right
	nil;
	'\27[4~'; -- end
	'\27OB'; -- down
	'\27[6~'; -- page down
	'\27[2~'; -- insert
}

local keys = {}
for cc, real in pairs(_keys) do
	keys[cc] = real
	if type(real) == 'table' then
		for _, seq in ipairs(real) do
			keys[seq] = cc
		end
	else
		keys[real] = cc
	end
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
	file = require 'pl.file';
	pretty = require 'pl.pretty';
}

local _bit = bit32 or require 'bit'
local unpack = _G.unpack or table.unpack

require 'luarocks.index'
local terminfo = require 'terminfo'
local T = setmetatable({}, {
	__index = function(t, k)
		local v = terminfo.get(k)
		if type(v) == 'string' then
			return function(...)
				return terminfo.tparm(v, ...)
			end
		else
			return v
		end
	end;
})
local luv = require 'luv'

local dirname = pl.path.dirname(debug.getinfo(1).source:match("@(.*)$"))

local prev = _G

return function(dir, ...)
	local cmd
	local stdscr

	local alive = true
	local eventQueue = {{n = select('#', ...), ...}}
	local timers = {}
	local termNat

	local stdin = luv.new_tty(0, true)

	local env = {}
	function create(...)
		local _ENV = env
		for _, name in prev.ipairs({'setmetatable', 'getmetatable', 'ipairs', 'string', 'tostring', 'tonumber', 'select', 'getfenv', 'setfenv', 'table', 'pcall', 'xpcall', 'type', 'error', 'pairs', 'loadstring', 'load', 'math', 'rawset', 'rawget', 'coroutine', '_VERSION', 'next'}) do
			env[name] = prev[name]
		end
		env.unpack = unpack
		env.prev = prev -- VERY BAD
		bit = _bit
		_G = env

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
					path = pl.path.normpath(pl.path.join(findPath(path), '.'))
					local files = {}

					if path == dir then
						files[#files + 1] = 'rom'
					end

					for file in pl.path.dir(path) do
						files[#files + 1] = file
					end

					files = pl.tablex.map(pl.path.basename, files)
					table.sort(files)
					return files
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
					local timer = luv.new_timer()
					luv.timer_start(timer, time, 0, function()
						timers[id] = nil
						luv.timer_stop(timer)
						luv.close(timer)
						eventQueue[#eventQueue + 1] = { 'timer', id }
					end)
					timers[id] = { after = prev.os.time(), offset = time, timer = timer }
					return id
				end;
				cancelTimer = function(id)
					local timer = timers[id]
					if timer then
						luv.timer_stop(timer.timer)
						luv.close(timer.timer)
					end
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
					local y, x = luv.tty_get_winsize(stdin)
					return x, y
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

					local color = ansiColor[_colors[c] ]
					prev.io.write(T.setaf(color[1]))
					prev.io.write(T[color[2] and 'bold' or 'sgr0']())
				end;
				getTextColour = function(...) return termNat.getTextColor(...) end;
				getTextColor = function()
					return ccColorFor(textColor)
				end;
				setBackgroundColour = function(...) return termNat.setBackgroundColor(...) end;
				setBackgroundColor = function(c)
					backColor = math.log(c) / log2

					prev.io.write(T.setab(ansiColor[_colors[c] ][1]))
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
					prev.io.write(T[n < 0 and 'rin' or 'indn'](math.abs(n)))

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

			term = termNat
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

		xpcall(runRom, function(err)
			term.setTextColor(math.pow(2, 0))
			term.setBackgroundColor(math.pow(2, 14))
			term.clear()
			print(err)
			local level = 5
			while true do
				local _, msg = pcall(error, '@', level)
				if msg == '@' then break end
				print(msg)
				level = level + 1
			end
			while stdscr:getch() ~= 3 do end
		end, 'bios.lua', ...)
	end
	if setfenv then setfenv(create, env) end

	local co = coroutine.create(create)

	io.write(T.smcup())
	io.write(T.smkx())
	io.write(T.clear())

	local eventFilter

	luv.tty_set_mode(stdin, 1)
	luv.read_start(stdin, function(_, data)
		-- print(pl.pretty.write(data))

		local function sendKey(key, test, char)
			if (#test == 1 or (#test == 2 and test:sub(1, 1) == '\27')) and char > 9 and char < 127 and char ~= 13 and char ~= 26 and char ~= 20 and char ~= 27 and char ~= 30 then
				eventQueue[#eventQueue + 1] = { 'char', test }
			end
			eventQueue[#eventQueue + 1] = { 'key', key }
		end
		
		local start = 1
		while start <= #data do
			local test = ''
			local i = start
			while true do
				local char = string.byte(data:sub(i, i))
				test = test .. data:sub(i, i)
				i = i + 1

				if test == '\20' then
					eventQueue[#eventQueue + 1] = { 'terminate' }
					break
				elseif test == '\3' then
					os.exit()
				end

				local key = keys[test]
				if key then
					sendKey(key, test, char)
					break
				end

				if #test >= #data then
					local found = false
					if test:sub(1, 1) == '\27' then
						for i = 2, #test do
							local test_ = test:sub(2, i)
							local key = keys[test_]
							if key then
								eventQueue[#eventQueue + 1] = { 'key', 56 }
								sendKey(key, test_, char)
								found = true
								break
							end
						end
					end
					if not found then
						env.print('unknown key seq: ' .. pl.pretty.write(test))
					end
					break
				end
			end
			start = i
		end
	end)

	while alive and coroutine.status(co) ~= 'dead' do
		-- local clock = os.time()
		--
		-- for id, time in pairs(timers) do
		-- 	-- env.print(id, clock, env.textutils.serialize(time), os.difftime(clock, time[1]))
		-- 	if os.difftime(clock, time[1]) >= time[2] then
		-- 		-- env.print(id)
		-- 		eventQueue[#eventQueue + 1] = { 'timer', id }
		-- 		timers[id] = nil
		-- 	end
		-- end

		luv.run(#eventQueue >= 1 and 'nowait' or 'once')

		while #eventQueue >= 1 do
			local ev = table.remove(eventQueue, 1)
			if eventFilter == nil or ev[1] == eventFilter or ev[1] == 'terminate' then
				-- debug.sethook(co, function()
				-- 	error('Too long without yielding', 2)
				-- end, '', 35000)
				local ok, err = coroutine.resume(co, unpack(ev, 1, ev.n))
				-- print(unpack(ev), 'end')
				-- print(alive, coroutine.status(co))
				-- debug.sethook(co)
				if ok then
					eventFilter = err
				else
					io.write(T.clear)
					-- red on black
					-- env.term.setTextColor(math.pow(2, 14))
					-- env.term.setBackgroundColor(math.pow(2, 0))
					-- stdscr:mvaddstr(0, 0, err)
					-- stdscr:mvaddstr(1, 0, "Press Control-c to exit")
					-- while stdscr:getch() ~= 3 do end
					error(err)
				end
				break
			end
		end
		io.flush()
	end
end
