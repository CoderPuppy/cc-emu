local prev, pl, luv, event_queue = ...

local nn = prev.require 'nn'

return function(dir, id)
	local sub_addr, send_addr

	do
		if not pl.path.isfile(pl.path.join(dir, 'sub_addr')) then
			error('no subscription socket defined for: ' .. dir)
		end
		local h = prev.io.open(pl.path.join(dir, 'sub_addr'))
		local err
		sub_addr, err = h:read '*a'
		if err then
			error(err)
		end
		h:close()
		sub_addr = sub_addr:gsub('^%s+', ''):gsub('%s+$', ''):gsub('^ipc://(.+)$', function(f)
			return 'ipc://' .. pl.path.abspath(f, dir)
		end)
	end

	do
		if not pl.path.isfile(pl.path.join(dir, 'send_addr')) then
			error('no sendput socket defined for: ' .. dir)
		end
		local h = prev.io.open(pl.path.join(dir, 'send_addr'))
		local err
		send_addr, err = h:read '*a'
		if err then
			error(err)
		end
		h:close()
		send_addr = send_addr:gsub('^%s+', ''):gsub('%s+$', ''):gsub('^ipc://(.+)$', function(f)
			return 'ipc://' .. pl.path.abspath(f, dir)
		end)
	end

	local sub_id = tostring({})
	local ctrl = nn.socket(nn.AF_SP, nn.NN_PUSH)
	ctrl:bind('inproc://' .. sub_id .. '-ctrl')

	local inp = nn.socket(nn.AF_SP, nn.NN_PULL)
	inp:bind('inproc://' .. sub_id .. '-inp')

	local async = luv.new_async(function()
		while true do
			local msg = inp:recv(nil, nn.NN_DONTWAIT)
			if msg then
				local chan, rpl, data = msg:match '^(%d+):(%d+):(.+)$'
				chan = tonumber(chan)
				rpl = tonumber(rpl)
				data = (prev.loadstring or prev.load)('return ' .. data, 'modem:' .. id, nil, {})()
				event_queue[#event_queue + 1] = {'modem_message', id, chan, rpl, data, 100}
			else
				break
			end
		end
	end)

	local send = nn.socket(nn.AF_SP, nn.NN_PUSH)
	send:connect(send_addr)

	local thread = luv.new_thread(function(sub_addr, sub_id, async)
		xpcall(function()
			local nn = require 'nn'
			local luv = require 'luv'

			local sub = nn.socket(nn.AF_SP, nn.NN_SUB)
			sub:connect(sub_addr)

			local ctrl = nn.socket(nn.AF_SP, nn.NN_PULL)
			ctrl:connect('inproc://' .. sub_id .. '-ctrl')

			local inp = nn.socket(nn.AF_SP, nn.NN_PUSH)
			inp:connect('inproc://' .. sub_id .. '-inp')

			local	poll = nn.poll()
			local sub_poll = poll:add(sub)
			local ctrl_poll = poll:add(ctrl)

			while true do
				if poll:poll() > 0 then
					if poll:inp(sub_poll) then
						while true do
							local msg = sub:recv(nil, nn.NN_DONTWAIT)
							if msg then
								inp:send(msg, nn.NN_DONTWAIT)
							else
								break
							end
						end
						luv.async_send(async)
					end

					if poll:inp(ctrl_poll) then
						while true do
							local msg = ctrl:recv(nil, nn.NN_DONTWAIT)
							if msg then
								local op, chan = msg:match '^([+-])(%d+)$'
								sub:setopt(nn.NN_SUB, (op == '+' and nn.NN_SUB_SUBSCRIBE or nn.NN_SUB_UNSUBSCRIBE), chan .. ':')
							else
								break
							end
						end
					end
				end
			end
		end, function(msg)
			print 'nanomsg listen thread err'
			print('err: ' .. msg)
			local level = 5
			local stack = {}
			while true do
				local _, msg = pcall(error, '@', level)
				if msg == '@' then break end
				print(msg)
				level = level + 1
			end
		end)
	end, sub_addr, sub_id, async)

	local open = {}

	local modem = { type = 'modem' }

	function modem.isOpen(chan)
		return open[chan]
	end

	function modem.open(chan)
		if not open[chan] then
			ctrl:send('+' .. tostring(chan))
		end
		open[chan] = true
	end

	function modem.close(chan)
		if open[chan] then
			ctrl:send('-' .. tostring(chan))
		end
		open[chan] = nil
	end

	function modem.closeAll()
		for chan, open in pairs(open) do
			ctrl:send('-' .. tostring(chan))
		end
		open = {}
	end

	function modem.transmit(chan, rpl, msg)
		send:send(tostring(chan) .. ':' .. tostring(rpl) .. ':' .. (pl.pretty.write(msg, '')))
	end

	function modem.isWireless()
		return true
	end

	return modem
end
