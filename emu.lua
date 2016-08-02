require 'luarocks.index'
local T = require(jit and 'terminfo-luajit' or 'terminfo-norm')
local luv = require 'luv'
local fcntl = require 'posix.fcntl'

local pl = {
	path = require 'pl.path';
	dir = require 'pl.dir';
	tablex = require 'pl.tablex';
	file = require 'pl.file';
	pretty = require 'pl.pretty';
}

local _bit = bit32 or require 'bit'
local unpack = _G.unpack or table.unpack

local unistd = require 'posix.unistd'

local dirname = pl.path.dirname(debug.getinfo(1).source:match("@(.*)$"))

local prev = _G

return function(dir, ...)
	local cmd
	local stdscr

	local config_path = pl.path.join(dir, '.termu')

	local alive = true
	local event_queue = {{n = select('#', ...), ...}}
	local timers = {}
	local tick = {}
	local termNat
	local starting_uptime = 0
	do
		local path = pl.path.join(config_path, 'uptime')
		if pl.path.isfile(path) then
			local h = io.open(path)
			starting_uptime = tonumber(h:read '*a':match '^%s*(%d+)%s*') or 0
			h:close()
		end
	end
	local start_time = os.time()

	local function uptime()
		return os.difftime(os.time(), start_time) + starting_uptime
	end

	local exit_seq = {}
	local function exit()
		if not pl.path.isdir(config_path) then
			pl.path.mkdir(config_path)
		end
		do
			local h = io.open(pl.path.join(config_path, 'uptime'), 'w')
			h:write(tostring(uptime()))
			h:close()
		end
		for _, fn in ipairs(exit_seq) do
			fn()
		end
		luv.loop_close()
	end

	local env = {}
	local function reboot()
		-- local h = prev.io.popen('/bin/which lua')
		-- local lua = h:read('*l')
		-- h:close()
		-- print(pl.pretty.write({lua, {pl.path.abspath(pl.path.join(dirname, 'cli.lua')), dir, unpack(args)}}))
		-- exit()
		-- unistd.exec(lua, {pl.path.abspath(pl.path.join(dirname, 'cli.lua')), dir, unpack(args)})
		env.print 'Sorry, rebooting is not supported'
	end
	function create(...)
		local _ENV = env
		for _, name in prev.ipairs({'setmetatable', 'getmetatable', 'ipairs', 'string', 'tostring', 'tonumber', 'select', 'setfenv', 'table', 'pcall', 'xpcall', 'type', 'error', 'pairs', 'math', 'rawset', 'rawget', 'coroutine', '_VERSION', 'next', 'assert'}) do
			env[name] = prev[name]
		end
		env.unpack = unpack
		-- env.prev = prev -- VERY BAD
		bit = _bit
		_G = env
		_HOST = 'termu'

		local args = { n = select('#', ...), ... }

		local ok, err = xpcall(function()
			function load(src, name, mode, env)
				return prev.load(src, name, mode, env or _ENV)
			end

			function loadstring(src, name, env)
				return prev.load(src, name, nil, env or _ENV)
			end

			function getfenv(f)
				if type(f) == 'number' and f > 0 then
					f = f + 1
				elseif f == nil then
					f = 2
				end

				local r = prev.getfenv(f)

				if r == prev then
					return _ENV
				else
					return r
				end
			end

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

			local peripherals
			peripheral, peripherals = loadLib('peripheral', prev, pl)

			loadLib('peripheral-config', prev, pl, dir, peripherals, {
				["nanomsg-modem"] = loadLib('nanomsg-modem', prev, pl, luv, event_queue);
				["cups-printer"] = loadLib('cups-printer', prev, pl, luv, event_queue);
			})

			local stdin = loadLib('input', prev, luv, T, _bit, pl, exit, exit_seq, event_queue, reboot, tick)

			local runRom
			fs, runRom = loadLib('fs', prev, pl, dirname, dir)

			do -- OS
				os = {
					queueEvent = function(ev, ...)
						event_queue[#event_queue + 1] = { n = select('#', ...) + 1, ev, ... }
					end;

					startTimer = function(time)
						local id = #timers + 1
						local timer = luv.new_timer()
						luv.timer_start(timer, time * 1000, 0, function()
							timers[id] = nil
							luv.timer_stop(timer)
							luv.close(timer)
							event_queue[#event_queue + 1] = { 'timer', id }
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
					day = function()
						-- increments every 20 minutes
						return math.floor(uptime() / 60 / 20) + 1
					end;

					shutdown = function()
						alive = false
						coroutine.yield()
					end;

					getComputerID = function()
						local path = pl.path.join(config_path, 'id')
						if pl.path.isfile(path) then
							local h, err = prev.io.open(path)
							if err then
								error(err)
							end
							local contents = h:read('*a'):match('^%s*(%d+)%s*$')
							if not contents then
								print('Invalid computer id')
								return 0
							end
							h:close()
							return tonumber(contents)
						else
							return 0
						end
					end;

					getComputerLabel = function()
						local path = pl.path.join(config_path, 'label')
						if pl.path.isfile(path) then
							local h, err = prev.io.open(path)
							if err then
								error(err)
							end
							local contents = h:read('*a')
							h:close()
							return contents
						else
							return nil
						end
					end;

					setComputerLabel = function(label)
						if not pl.path.isdir(config_path) then
							pl.path.mkdir(config_path)
						end
						local h, err = prev.io.open(pl.path.join(config_path, 'label'), 'w')
						if err then
							error(err)
						end
						h:write(label)
						h:close()
					end;

					reboot = reboot;
				}
			end

			do -- RS
				redstone = {
					getSides = function() return { 'top', 'bottom', 'left', 'right', 'front', 'back' } end;
					setOutput = function() end;
				}
				rs = redstone
			end

			termNat = loadLib('term', prev, pl, luv, dir, T, stdin, exit_seq)
			-- termNat = loadLib('term-fake', prev)
			term = termNat

			do -- RS
				redstone = {
					getSides = function() return { 'top', 'bottom', 'left', 'right', 'front', 'back' } end;

					getInput = function(...) return redstone.getAnalogInput(...) ~= 0 end;
					getAnalogInput = function() return 0 end;

					setOutput = function(...) return redstone.setAnalogOutput(..., 15) end;
					getOutput = function(...) return redstone.getAnalogOutput(...) ~= 0 end;
					
					setAnalogOutput = function() end;
					getAnalogOutput = function() return 0 end;

					getBundledInput = function() return 0 end;
					testBundledInput = function() return false end;

					setBundledOutput = function() end;
					getBundledOutput = function() return 0 end;
				}
				rs = redstone
			end

			http = loadLib('http', prev, luv, pl, dirname, event_queue)

			runRom('bios.lua', unpack(args, 1, args.n))
		end, function(err)
			for i = 1, 4 do
				prev.print(i, pcall(error, '@', i))
			end
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
			if term then
				term.setTextColor(math.pow(2, 0))
				term.setBackgroundColor(math.pow(2, 14))
				term.setCursorPos(1, 1)
				term.clear()
			end
			prev.print('error')
			prev.print(err.err)
			for _, frame in ipairs(err.stack) do
				prev.print(frame)
			end
		end
	end
	if setfenv then setfenv(create, env) end

	local co = coroutine.create(create)

	local eventFilter

	tick[#tick + 1] = function()
		luv.run(#event_queue >= 1 and 'nowait' or 'once')
	end

	tick[#tick + 1] = function()
		while #event_queue >= 1 do
			local ev = table.remove(event_queue, 1)
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

	while alive and coroutine.status(co) ~= 'dead' do
		for _, fn in ipairs(tick) do
			fn()
		end
		io.flush()
	end
	exit()
end
