require 'luarocks.index'
local T = require(jit and 'terminfo-luajit' or 'terminfo-norm')
local luv = require 'luv'
local fcntl = require 'posix.fcntl'

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
	T.key_backspace(); -- backspace
	{T.tab(), T.key_btab()};
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
	T.key_f1(); -- f1
	T.key_f2(); -- f2
	T.key_f3(); -- f3
	T.key_f4(); -- f4
	T.key_f5(); -- f5
	T.key_f6(); -- f6
	T.key_f7(); -- f7
	T.key_f8(); -- f8
	T.key_f9(); -- f9
	T.key_f10(); -- f10
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
	nil;
	nil;
	nil;
	T.key_f11(); -- f11 -- TODO: this could be wrong
	T.key_f12(); -- f12
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
	nil; -- pause
	nil;
	T.key_home(); -- home
	T.key_up(); -- up
	T.key_ppage(); -- page up
	nil;
	T.key_left(); -- left
	nil;
	T.key_right(); -- right
	nil;
	T.key_end(); -- end
	T.key_down(); -- down
	T.key_npage(); -- page down
	T.key_ic(); -- insert
	nil; -- delete
	nil;
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

local pl = {
	path = require 'pl.path';
	dir = require 'pl.dir';
	tablex = require 'pl.tablex';
	file = require 'pl.file';
	pretty = require 'pl.pretty';
}

local _bit = bit32 or require 'bit'
local unpack = _G.unpack or table.unpack

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
	local function exit()
		io.write(T.keypad_local())
		luv.tty_set_mode(stdin, 0)
		luv.loop_close()
	end

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
		_HOST = 'termu'

		local function loadLib(lib, ...)
			local fn, err = prev.loadfile(pl.path.normpath(pl.path.join(dirname, 'libs', lib .. '.lua')), 't', _G)
			if err then
				error(err)
			end
			if setfenv then
				setfenv(fn, _G)
			end
			return fn(...)
		end

		local runRom
		fs, runRom = loadLib('fs', prev, pl, dirname, dir)

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

		termNat = loadLib('term', prev, luv, T, stdin)
		-- termNat = loadLib('term-fake')
		term = termNat

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

		http = loadLib('http', prev, luv, pl, dirname, eventQueue)

		local args = { n = select('#', ...), ... }
		local ok, err = xpcall(function()
			runRom('bios.lua', unpack(args, 1, args.n))
		end, function(err)
			local level = 5
			local stack = {}
			while true do
				local _, msg = pcall(error, '@', level)
				if msg == '@' then break end
				stack[#stack + 1 ] = msg
				level = level + 1
			end
			return {err = err, stack = stack}
		end)
		if not ok then
			term.setTextColor(math.pow(2, 0))
			term.setBackgroundColor(math.pow(2, 14))
			term.setCursorPos(1, 1)
			term.clear()
			prev.print(err.err)
			for _, frame in ipairs(err.stack) do
				prev.print(frame)
			end
		end
	end
	if setfenv then setfenv(create, env) end

	local co = coroutine.create(create)

	io.write(T.smcup())
	io.write(T.keypad_xmit())
	io.write(T.clear())
	fcntl.fcntl(1, fcntl.F_SETFL, bit.bor(fcntl.fcntl(1, fcntl.F_GETFL), fcntl.O_NONBLOCK))

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
					exit()
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
		luv.run(#eventQueue >= 1 and 'nowait' or 'once')

		while #eventQueue >= 1 do
			local ev = table.remove(eventQueue, 1)
			if eventFilter == nil or ev[1] == eventFilter or ev[1] == 'terminate' then
				-- debug.sethook(co, function()
				-- 	error('Too long without yielding', 2)
				-- end, '', 35000)
				local ok, err = coroutine.resume(co, unpack(ev, 1, ev.n))
				io.flush()
				-- debug.sethook(co)
				if ok then
					eventFilter = err
				else
					-- red on black
					print('there\'s an error')
					if termNat then
						termNat.setTextColor(math.pow(2, 14))
						termNat.setBackgroundColor(math.pow(2, 0))
						termNat.clear()
						termNat.setCursorPos(1, 1)
						termNat.write(err)
					else
						print(err)
					end
					alive = false
					-- error(err)
				end
				break
			end
		end
	end
	exit()
end
