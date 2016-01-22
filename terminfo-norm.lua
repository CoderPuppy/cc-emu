local terminfo = require 'terminfo'
return setmetatable({}, {
	__index = function(t, k)
		local v = terminfo.get(k)
		if type(v) == 'string' then
			return function(...)
				return terminfo.tparm(v, ...)
			end
		else
			return v
		end
	end;
})
