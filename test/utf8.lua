local function mangle(text)
	return text:gsub('[\128-\255]', function(s)
		local b = string.byte(s)
		if b >= 128 and b <= 191 then
			return '\194' .. s
		else
			return '\195' .. string.char(128 + b - 192)
		end
	end)
end

local pp = require 'pl.pretty'.write

local function zip(...)
	local iters, consts, initials = {}, {}, {}
	for i, iter_gen in ipairs({...}) do
		local iter, const, var = table.unpack(iter_gen, 1, 3)
		iters[i] = iter
		consts[i] = const
		initials[i] = var
	end
	local function next(consts, vars)
		local reses, vars_res = {}, {}
		for i, iter in ipairs(iters) do
			local res = {iter(consts[i], vars[i])}
			if res[1] == nil then
				return
			end
			reses[i] = res
			vars_res[i] = res[1]
		end
		return vars_res, table.unpack(reses, 1, #iters)
	end
	return next, consts, initials
end

local function test(before)
	print '-- before:'
	print(pp({string.byte(before, 1, #before)}))
	local after = mangle(before)
	print '-- after:'
	print(pp({utf8.codepoint(after, 1, #after)}))
	for _, b, a in zip({before:gmatch'.'}, {utf8.codes(after)}) do
		if string.byte(b[1]) ~= a[2] then
			print('expected: ' .. string.byte(b[1]) .. ', got: ' .. a[2])
		end
	end
end

for i = 128, 255 do
	test(string.char(i))
end
