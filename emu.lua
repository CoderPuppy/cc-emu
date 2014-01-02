local pl = {
	path = require 'pl.path',
	dir = require 'pl.dir',
	tablex = require 'pl.tablex'
}

require 'luarocks.index'
local natTerm = require 'term'
local curses = require 'curses'
local posix = require 'posix'

local dirname = pl.path.dirname(debug.getinfo(1).source:match("@(.*)$"))
local threads = require(pl.path.normpath(pl.path.join(dirname, 'threads')))

local prev = _G

return function(dir, cmd)
	function create()
		setmetatable = prev.setmetatable
		ipairs = prev.ipairs
		string = prev.string
		tostring = prev.tostring
		select = prev.select
		getfenv = prev.getfenv
		table = prev.table
		unpack = prev.unpack
		setfenv = prev.setfenv
		pcall = prev.pcall
		type = prev.type
		pairs = prev.pairs
		error = prev.error
		loadstring = prev.loadstring
		_G = getfenv()

		coroutine = {
			create = prev.coroutine.create,
			status = prev.coroutine.status,
			yield = prev.coroutine.yield,
			resume = function(...)
				local res = {prev.coroutine.resume(...)}
				local ok = table.remove(res, 1)

				if not ok then
					error(res[1])
				end

				return unpack(res)
			end
		}

		local function findRomFile(path)
			return pl.path.join(dirname, 'cc', path)
		end

		local function findPath(path)
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

			if path:sub(1, 3) == 'rom' then
				return findRomFile(path)
			end

			return pl.path.normpath(pl.path.join(dir, path))
		end

		local function runRom(path, ...)
			local fn = prev.loadfile(findRomFile(path))
			setfenv(fn, _G)
			return fn(...)
		end

		fs = {
			list = function(path)
				local files = pl.dir.getfiles(findPath(path))
				return pl.tablex.map(pl.path.basename, files)
			end,

			open = function(path, mode)
				local file = prev.io.open(findPath(path), mode)

				if file == nil then return nil end

				local h = {}

				function h.readAll()
					return file:read('*a')
				end

				function h.close()
					file:close()
				end

				return h
			end,

			exists = function(path)
				return pl.path.exists(findPath(path))
			end,

			isDir = function(path)
				return pl.path.isdir(findPath(path))
			end,

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

				-- prev.print('"' .. a .. '" / "' .. b .. '" = ' .. res)

				return res
			end,

			getName = function(path) return pl.path.basename(path) end
		}

		local eventQueue = {}
		os = {
			queueEvent = function(ev, ...)
				eventQueue[#eventQueue + 1] = { ev, ... }
			end,
			clock = prev.os.clock
		}

		local cursorX, cursorY = 1, 1

		local termNat
		termNat = {
			isColor = function() return false end,
			isColour = function() return false end,
			getSize = function() return 80, 19 end,
			getCursorPos = function() return cursorX, cursorY end,
			setCursorPos = function(x, y)
				cursorX, cursorY = x, y

				-- prev.io.write('moving to: ' .. tostring(x) .. ', ' .. tostring(y))
				-- error('blah')

				natTerm.cursor.moveto(y, x)
			end,
			setTextColour = function(...) return termNat.setTextColor(...) end,
			setTextColor = function(c)
				prev.io.write(tostring(natTerm.colors[colors[c]]))
			end,
			setBackgroundColour = function(...) return termNat.setBackgroundColor(...) end,
			setBackgroundColor = function(c)
				prev.io.write(tostring(natTerm.colors['on' .. colors[c]]))
			end,
			write = function(text)
				-- text = text:gsub('\n', '?')
				prev.io.write(text)
				termNat.setCursorPos(cursorX + #text, cursorY)
			end,
			setCursorBlink = function() end
		}

		term = termNat

		rs = {
			getSides = function() return { 'top', 'bottom', 'left', 'right', 'front', 'back' } end
		}

		peripheral = {
			getNames = function() return {} end,
			isPresent = function() return false end,
			getType = function() return nil end
		}

		function run()
			function main()
				_G.prev = prev

				natTerm.clear()
				natTerm.cursor.moveto(1, 1)

				runRom('bios.lua')
				-- shell.run(cmd)
				prev.io.write(tostring(natTerm.colors.reset))
				-- natTerm.clear()
				-- natTerm.cursor.moveto(1, 1)
			end

			local co = coroutine.create(main)

			local ev = {}

			while coroutine.status(co) == 'suspended' do
				local newFilter = coroutine.resume(co, unpack(ev))
				-- prev.print(ok)
				if newFilter then
					coroutine.yield('addFilter', { 'match', newFilter })
				end

				for i = 1, #eventQueue do
					coroutine.yield('queueEvent', eventQueue[i])
				end
				eventQueue = {}
				
				ev = { coroutine.yield('pullEvent') }

				if newFilter then
					coroutine.yield('rmFilter')
				end
			end
		end

		local thread = threads.new(run):start()

		curses.initscr()
		curses.cbreak()
		curses.echo(false)
		curses.nl(false)
		local stdscr = curses.stdscr()
		curses.raw(true)
		stdscr:clear()
		stdscr:refresh()
		stdscr:keypad(true)

		while thread.alive do
			local clock = os.clock()
			
			for id, time in pairs(thread.timers) do
				if clock >= time then
					thread:queue('timer', id)
					thread.timers[id] = nil
				end
			end

			local res = stdscr:getch()

			print(type(res))
			
			thread:run()
		end

		thread:stop()

		curses.endwin()
	end

	local env = {}
	setfenv(create, env)
	create()
end