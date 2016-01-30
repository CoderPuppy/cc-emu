local prev, pl, dir, tick, eventQueue = ...

local GPIO = prev.require 'periphery'.GPIO

local gpio_dir = pl.path.join(dir, '.termu', 'redstone-gpio')

local gpios = {}

if pl.path.isdir(gpio_dir) then
	for side in pl.path.dir(gpio_dir) do
		if side ~= '.' and side ~= '..' then
			local h = prev.io.open(pl.path.join(gpio_dir, side))
			local data, err = h:read '*a'
			if err then
				error(err)
			end
			h:close()
			local pin, dir = data:match '^%s*(%d+)%s+([^%s]+)%s*$'
			local gpio = GPIO(tonumber(pin), dir)
			-- local gpio = {
			-- 	write = function(self, out) end;
			-- 	read = function(self) return false end;
			-- 	poll = function(self) return false end;
			-- }
			gpio:write(false)
			gpios[side] = {
				gpio = gpio;
				out = false;
			}
		end
	end
end

local function get(side)
	local gpio = gpios[side]
	if gpio then
		return gpio
	else
		error('invalid side: ' .. pl.pretty.write(side))
	end
end

function rs.getSides()
	local t = {}
	for k, _ in pairs(gpios) do
		t[#t + 1] = k
	end
	return t
end

function rs.getInput(side)
	return get(side).gpio:read()
end

function rs.setOutput(side, bool)
	local gpio = get(side)
	gpio.gpio:write(bool)
	gpio.out = bool
end

function rs.getOutput(side)
	return get(side).out
end

function rs.getAnalogInput(side)
	return rs.getInput(side) and 15 or 0
end

function rs.setAnalogOutput(side, val)
	rs.setOutput(side, val ~= 0)
end

function rs.getAnalogOutput(side)
	return rs.getOutput(side) and 15 or 0
end

tick[#tick + 1] = function()
	local any = false
	for side, gpio in pairs(gpios) do
		any = any or gpio.gpio:poll(0)
	end
	if any then
		eventQueue[#eventQueue + 1] = { 'redstone' }
	end
end
