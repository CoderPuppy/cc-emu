local prev, pl, dirname, dir = ...

local glob = prev.require 'posix.glob'.glob

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

		if path:sub(1, 2) == './' or path == '.' then
			path = path:sub(2)
		end

		if path:sub(1, 3) == '../' or path == '..' then
			path = path:sub(3)
		end

		if path:sub(-2) == '/.' then
			path = path:sub(1, -3)
		end
	end

	return path
end
dir = '/' .. betterifyPath(dir)
dirname = '/' .. betterifyPath(dirname)
romPath = '/' .. betterifyPath(pl.path.abspath(romPath))

local function findPath(path)
	path = pl.path.normpath(path)
	path = betterifyPath(path)

	if path:sub(1, 3) == 'rom' then
		return findRomFile(path)
	end

	return pl.path.normpath(pl.path.join(dir, path))
end

local function runRom(path, ...)
	local fn, err = prev.loadfile(findRomFile(path), 't', _G)
	if err then
		error(err)
	end
	if setfenv then
		setfenv(fn, _G)
	end
	return fn(...)
end

return {
	isReadOnly = function(path)
		return betterifyPath(path):sub(1, 3) == 'rom'
	end;

	delete = function(path)
		path = findPath(path)
		if pl.path.exists(path) then
			local ok, err = pl.file.delete(path)
			if err then
				error(err)
			end
		end
	end;

	move = function(src, dest)
		src = findPath(src)
		dest = findPath(dest)

		if not pl.path.exists(src) then
			error('No such file', 2)
		end
		if pl.path.exists(dest) then
			error('File exists', 2)
		end

		pl.file.move(src, dest)
	end;

	copy = function(src, dest)
		src = findPath(src)
		dest = findPath(dest)

		if not pl.path.exists(src) then
			error('No such file', 2)
		end
		if pl.path.exists(dest) then
			error('File exists', 2)
		end

		pl.file.copy(src, dest)
	end;

	list = function(path)
		path = findPath(path)

		if not pl.path.isdir(path) then
			error('Not a directory', 2)
		end
		
		local files = {}

		if path == dir then
			files[#files + 1] = 'rom'
		end

		for file in pl.path.dir(path) do
			if file ~= '.' and file ~= '..' then
				files[#files + 1] = file
			end
		end

		table.sort(files)
		return files
	end;

	open = function(path, mode)
		path = findPath(path)

		if not pl.path.isfile(path) and (mode == 'r' or mode == 'rb') then return nil end

		local file

		local h = {}

		if mode == 'r' then
			file = prev.io.open(path, 'r')
			if not file then return end

			function h.readAll()
				local data, err = file:read('*a')
				if data then
					data = data:gsub('\13', '\n')
					-- prev.print('all', pl.pretty.write(data))
					return data
				else
					if err then
						error(err)
					else
						return ''
					end
				end
			end

			function h.readLine()
				local line = file:read('*l')
				if line then
					line = line:gsub('[\13\n\r]*$', '')
				end
				-- prev.print('line', pl.pretty.write(line))
				return line
			end
		elseif mode == 'w' or mode == 'a' then
			file = prev.io.open(path, mode)

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

		local open = true
		function h.close()
			if open then
				file:close()
			end
			open = false
		end

		return h
	end;

	exists = function(path)
		return pl.path.exists(findPath(path)) ~= false
	end;

	getDrive = function(path)
		path = findPath(path)
		if pl.path.exists(path) then
			if path:find(romPath, 1, true) then
				return 'rom'
			else
				return 'hdd'
			end
		end
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

	getName = function(path) return pl.path.basename(path) end;
	getSize = function(path) return math.pow(2, 20) end;

	find = function(pat)
		pat = pl.path.normpath(pat or '')
		pat = pat:gsub('%*%*', '*')
		local results = {}
		for _, path in ipairs(glob(findPath(pat)) or {}) do
			results[#results + 1] = pl.path.relpath(path, dir)
		end
		for _, path in ipairs(glob(findRomFile(pat)) or {}) do
			results[#results + 1] = pl.path.relpath(path, romPath)
		end
		return results
	end;

	makeDir = function(path)
		path = findPath(path)
		pl.path.mkdir(path)
	end;
}, runRom
