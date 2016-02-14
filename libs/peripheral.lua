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
		local methods = {}
		for name, f in pairs(peripherals[name]) do
			if type(f) == 'function' then
				methods[#methods + 1] = name
			end
		end
		return methods
	end;
	call = function(name, meth, ...)
		return peripherals[name][meth](...)
	end;
}
return peripheral, peripherals
