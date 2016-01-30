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
			if file ~= '.' and file ~= '..' then
				files[#files + 1] = file
			end
		end

		table.sort(files)
		return files
	end;

	open = function(path, mode)
		local file = prev.io.open(findPath(path), mode)

		if file == nil then return nil end

		local h = {}

		if mode == 'r' then
			function h.readAll()
				local data = file:read('*a')
				if data then
					data = data:gsub('\13', '\n')
				end
				-- prev.print('all', pl.pretty.write(data))
				return data
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

	getName = function(path) return pl.path.basename(path) end;

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
