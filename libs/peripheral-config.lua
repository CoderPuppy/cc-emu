local prev, pl, dir, peripherals, types = ...

local perphs_dir = pl.path.join(dir, '.termu', 'peripherals')

if pl.path.isdir(perphs_dir) then
	for id in pl.path.dir(perphs_dir) do
		local path = pl.path.join(perphs_dir, id)
		if id ~= '.' and id ~= '..' and pl.path.isdir(path) and pl.path.isfile(pl.path.join(path, 'type')) then
			local  h = prev.io.open(pl.path.join(path, 'type'))
			local data, err = h:read '*a'
			if err then
				error(err)
			end
			h:close()

			data = data:gsub('^%s+', ''):gsub('%s+$', '')

			if peripherals[id] then error('there is already a peripheral: ' .. pl.pretty.write(id)) end
			if not types[data] then error('unknown peripheral type: ' .. pl.pretty.write(data)) end

			peripherals[id] = types[data](path, id)
		end
	end
end
