return function(fmt, ...)
	local params = table.pack(...)
	local out = ''
	local stack = {}
	while true do
		local skip, tail = fmt:match '^([^%%]*)%%(.*)$'
		if not skip then break end
		out = out .. skip
		fmt = tail
		
		repeat
			local tail = fmt:match '^%?(.*)$'
			if tail then
				fmt = tail
				break
			end

			local param, tail = fmt:match '^p([0-9])(.*)$'
			if param then
				fmt = tail
				stack[#stack + 1] = params[tonumber(param)]
				break
			end

			local num, tail = fmt:match '^{([0-9]*)}(.*)$'
			if num then
				fmt = tail
				stack[#stack + 1] = tonumber(num)
				break
			end

			local op, tail = fmt:match '^([%+%-%*/m&|^=<>AO])(.*)$'
			if op then
				fmt = tail
				local a, b = stack[#stack - 1], stack[#stack]
				stack[#stack] = nil
				stack[#stack] = nil
				local r
				if op == '+' then
					r = a + b
				elseif op == '-' then
					r = a - b
				elseif op == '*' then
					r = a * b
				elseif op == '/' then
					r = a / b
				elseif op == 'm' then
					r = a % b
				elseif op == '&' then
					r = bit32.band(a, b)
				elseif op == '|' then
					r = bit32.bor(a, b)
				elseif op == '^' then
					r = bit32.bxor(a, b)
				elseif op == '=' then
					r = a == b and 1 or 0
				elseif op == '<' then
					r = a < b and 1 or 0
				elseif op == '>' then
					r = a > b and 1 or 0
				elseif op == 'A' then
					r = (a ~= 0 and b ~= 0) and 1 or 0
				elseif op == 'O' then
					r = (a ~= 0 or b ~= 0) and 1 or 0
				else
					error('Unhandled operand (should never happen): ' .. op)
				end
				stack[#stack + 1] = r
				break
			end

			local tail = fmt:match '^t(.*)$'
			if tail then
				fmt = tail
				local cond = stack[#stack] ~= 0
				stack[#stack] = nil
				if not cond then
					local nesting = 0
					local continue = true
					while continue do
						repeat
							local tail = fmt:match '^[^%%]*%%(.*)$'
							if not tail then
								continue = false
								break
							end
							fmt = tail

							local tail = fmt:match '^%?(.*)$'
							if tail then
								fmt = tail
								nesting = nesting + 1
								break
							end

							local tail = fmt:match '^;(.*)$'
							if tail then
								fmt = tail
								if nesting == 0 then
									continue = false
									break
								end
								nesting = nesting - 1
								break
							end

							local tail = fmt:match '^e(.*)$'
							if tail and nesting == 0 then
								fmt = tail
								break
							end
						until true
					end
				end
				break
			end

			local tail = fmt:match '^e(.*)$'
			if tail then
				fmt = tail
				local nesting = 0
				local continue = true
				while continue do
					repeat
						local tail = fmt:match '^[^%%]*%%(.*)$'
						if not tail then
							continue = false
							break
						end
						fmt = tail

						local tail = fmt:match '^%?(.*)$'
						if tail then
							fmt = tail
							nesting = nesting + 1
							break
						end

						local tail = fmt:match '^;(.*)$'
						if tail then
							fmt = tail
							if nesting == 0 then
								continue = false
								break
							end
							nesting = nesting - 1
							break
						end
					until true
				end
				break
			end

			local df, tail = fmt:match '^(:?[# 0+-]*[0-9]*%.?[0-9]*[doxXs])(.*)'
			if df then
				fmt = tail
				local v = stack[#stack]
				stack[#stack] = nil
				out = out .. ('%' .. df):format(v)
				break
			end

			local tail = fmt:match '^i(.*)$'
			if tail then
				fmt = tail
				params[1] = params[1] + 1
				params[2] = params[2] + 1
				break
			end

			error(('unhandled terminfo format: %q'):format(fmt))
		until true
	end
	out = out .. fmt
	return out
end
