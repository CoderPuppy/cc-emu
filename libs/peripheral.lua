local peripherals = {}

local peripheral = {
	getNames = function()
		local names = {}
		for name in pairs(peripherals) do
			names[#names + 1] = name
		end
		return names
	end;
	isPresent = function(nmae)
		return not not peripherals[name]
	end;
	getType = function(name)
		return peripherals[name].type
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
