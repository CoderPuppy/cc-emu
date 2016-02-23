local prev, pl = ...

local peripherals = {}

local peripheral = {
	isPresent = function(name)
		return not not peripherals[name]
	end;
	getType = function(name)
		if peripherals[name] then
			return peripherals[name].type
		end
	end;
	getMethods = function(name)
		if not peripherals[name] then error('unknown peripheral: ' .. tostring(name)) end
		local methods = {}
		for name, f in pairs(peripherals[name]) do
			if type(f) == 'function' then
				methods[#methods + 1] = name
			end
		end
		return methods
	end;
	call = function(name, meth, ...)
		if not peripherals[name] then error('unknown peripheral: ' .. tostring(name)) end
		if not peripherals[name][meth] then error('unknown method: ' .. tostring(meth)) end
		return peripherals[name][meth](...)
	end;
}
return peripheral, peripherals
