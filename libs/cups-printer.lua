local prev, pl, luv, event_queue = ...

return function(dir, id)
	local config = setmetatable({}, { __index = function(_, name)
		local h = prev.io.open(pl.path.join(dir, name))
		if not h then
			return nil
		end
		local r = h:read('*a'):gsub('^%s+', ''):gsub('%s+$', '')
		h:close()
		return r
	end })

	local inPage = false
	local cmd
	local width, height
	local buf
	local title
	local cursor_x, cursor_y

	local printer = { type = 'printer' }

	function printer.newPage()
		if inPage then return false end
		cmd = config.cmd or 'a2ps --columns=1 -l $$width$$ -L $$height$$ --center-title=$$title$$ 2>/dev/null | lpr >/dev/null 2>/dev/null'
		width = tonumber(config.width) or 25
		height = tonumber(config.height) or 21
		title = 'Untitled'
		cursor_x, cursor_y = 1, 1

		buf = {}
		for y = 1, height do
			buf[y] = string.rep(' ', width)
		end

		inPage = true
		return true
	end

	function printer.getPageSize()
		if not inPage then
			error('Page not started', 2)
		end
		return width, height
	end

	function printer.setPageTitle(t)
		if not inPage then
			error('Page not started', 2)
		end
		title = t
	end

	function printer.getPaperLevel()
		return 320
	end

	function printer.getInkLevel()
		return 64
	end

	function printer.setCursorPos(x, y)
		if type(x) ~= 'number' or type(y) ~= 'number' then
			error('expected number, number', 2)
		end
		cursor_x, cursor_y = x, y
	end

	function printer.getCursorPos()
		return cursor_x, cursor_y
	end

	function printer.write(text)
		local line = buf[cursor_y]
		if not line then return end
		
		line = line:sub(1, cursor_x - 1) .. text:sub(1, math.min(width - cursor_x + 1, #text)) .. line:sub(cursor_x + #text)
		cursor_x = cursor_x + #text
		buf[cursor_y] = line
	end

	function printer.endPage()
		if not inPage then
			error('Page not started', 2)
		end

		inPage = false

		cmd = cmd:gsub('%$%$width%$%$', tostring(width)):gsub('%$%$height%$%$', tostring(height)):gsub('%$%$title%$%$', tostring(title))
		local h = prev.io.popen(cmd, 'w')
		for _, line in ipairs(buf) do
			h:write(line)
			h:write('\n')
		end
		h:close()

		return true
	end

	return printer
end
