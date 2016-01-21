local prev, pl, dirname, dir = ...
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

local function runRom(path, ...)
	local fn
	if setfenv then
		fn = prev.loadfile(findRomFile(path))
		setfenv(fn, _G)
	else
		fn = prev.loadfile(findRomFile(path), 't', _G)
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
}, runRom
