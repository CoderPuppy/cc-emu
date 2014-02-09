local function equal(a, b)
	if type(a) ~= type(b) then
		return false, 'different types'
	end
	
	local typ = type(a)
	
	if typ == 'table' then
		for key, val in pairs(a) do
			local ok, reason = equal(val, b[key])
			if not ok then
				return false, 'a[' .. tostring(key) .. '] ~= b[' .. tostring(key) .. '] because ' .. reason
			end
		end
		
		for key, val in pairs(b) do
			local ok, reason = equal(a[key], val)
			if not ok then
				return false, 'a[' .. tostring(key) .. '] ~= b[' .. tostring(key) .. '] because ' .. reason
			end
		end
	elseif typ == 'string' or typ == 'number' then
		return a == b
	else
		error('Can\'t handle type: ' .. typ)
	end
end

local function filterEvent(filter, ev)
	if type(filter) ~= 'table' then
		error('Filters must be tables')
	end
	
	if filter[1] == 'and' then
		for i = 2, #filter do
			if not filterEvent(filter[i], ev) then
				return false
			end
		end
		
		return true
	elseif filter[1] == 'match' then
		for i = 2, #filter do
			local filterArg = filter[i]
			local arg = ev[i - 1]
			
			if not equal(arg, filterArg) then
				return false
			end
		end
		
		return true
	else
		error('Unknown filter type: ' .. tostring(filter[1]))
	end
end


local utils = {
	sleep = function(time)
		local id = coroutine.yield('setTimer', time)
		
		local filters = {}
		
		local filter
		repeat
			filter = coroutine.yield('rmFilter')
			
			if filter ~= nil then
				table.insert(filters, filter)
			end
		until filter == nil
		
		--coroutine.yield('addFilter', { 'match', 'timer', id })
		local ev = {coroutine.yield('pullEvent', { 'match', 'timer', id })}
		--print('Ev: { ' .. table.concat(ev, ', ') .. ' }')
		-- coroutine.yield('rmFilter')
		
		for i = 1, #filters do
			coroutine.yield('addFilter', filters[i])
		end
	end
}

local threads = {}

function threads.new(co, ...)
	if type(co) == 'function' then
		co = coroutine.create(co)
	end
	
	if type(co) ~= 'thread' then
		error('That\'s not a coroutine')
	end
	
	local self = {
		args = { ... },
		
		eventQueue = {},
		coroutine = co,
		timers = {},
		filters = {},
		suspended = false,
		alive = false
	}
	
	function self:start()
		local status = coroutine.status(self.coroutine)
		
		if status ~= 'suspended' then
			error('The coroutine is in an invalid state for starting: ' .. status)
		end
		
		self.alive = true
		self.suspended = false
		
		self.filters = {}
		self.timers = {}
		self.eventQueue = {} 
		
		return self
	end
	
	function self:stop()
		return self
	end
	
	function self:pause()
		self.suspended = true
		return self
	end
	
	function self:resume()
		self.suspended = false
		return self
	end
		
	function self:queue(ev, ...)
		self.eventQueue[#self.eventQueue + 1] = {ev, ...}
		return self
	end
	
	function self:_filterEvent(ev)
		return filterEvent({ 'and', unpack(self.filters) }, ev)
	end
	
	function self:run(num)
		if not self.suspended then
			local function process()
				local args = {}
				
				if coroutine.status(self.coroutine) == 'dead' then
					self.result = { unpack(self.cmd) }
					self.alive = false
					
					return false
				end
				
				-- print('cmd: ' .. tostring(self.cmd and self.cmd[1]))

				if type(self.cmd) ~= 'table' then
					args = { unpack(self.args) }
				elseif self.cmd[1] == 'pullEvent' then
					local ev
					local filter = self.cmd[2]
					
					local i = 1

					while true do
						if #self.eventQueue == 0 then
							return false
						end
						
						ev = self.eventQueue[i]
						
						if ev == nil then
							return false
						end
						
						if self:_filterEvent(ev) then
							if filter == nil or filterEvent(filter, ev) then
								table.remove(self.eventQueue, i)
								break
							else
								i = i + 1
							end
						else
							table.remove(self.eventQueue, i)
						end
					end
					
					args = ev
				elseif self.cmd[1] == 'setTimer' then
					local id = #self.timers + 1
					
					self.timers[id] = {os.time(), self.cmd[2]}
					
					args = { id }
				elseif self.cmd[1] == 'addFilter' then
					table.insert(self.filters, self.cmd[3] or #self.filters + 1, self.cmd[2])
				elseif self.cmd[1] == 'rmFilter' then
					args = { table.remove(self.filters, self.cmd[2] or #self.filters) }
				elseif self.cmd[1] == 'queueEvent' then
					self:queue(unpack(self.cmd[2]))
				else
					print("Can't handle command: " .. tostring(self.cmd[1]))
					error("Can't handle command: " .. tostring(self.cmd[1]))
				end
				
				self.cmd = { coroutine.resume(self.coroutine, unpack(args)) }
				
				local ok = table.remove(self.cmd, 1)

				if not ok then
					error(self.cmd[1])
				end
				
				-- print('Ok: ' .. tostring(table.remove(self.cmd, 1)))
				-- print('new cmd: ' .. tostring(self.cmd[1]))
					
				return true
			end
			
			if type(num) == 'number' then
				for _ = 1, num do
					process()
				end
			else
				while process() do end
			end
		end
		
		return self
	end
	
	function self:interupt(ev, ...)
		self:queue(ev, ...):run(1)
	end
	
	return self
end

return threads

--[[function fn(time)
	print('clock: ' .. tostring(os.clock()))
	
	utils.sleep(time)
	
	print('clock: ' .. tostring(os.clock()))
end

local threadA = threads.new(fn, 2):start()
local threadB = threads.new(fn, 1):start()

while threadA.alive or threadB.alive do
	local clock = os.clock()
	
	if threadA.alive then
		for id, time in pairs(threadA.timers) do
			if clock >= time then
				threadA:queue('timer', id)
				threadA.timers[id] = nil
			end
		end
		
		threadA
			:queue('foo')
			:queue('bar')
			:queue('baz')
		
		threadA:run()
	end
	
	if threadB.alive then
		for id, time in pairs(threadB.timers) do
			if clock >= time then
				threadB:queue('timer', id)
				threadB.timers[id] = nil
			end
		end
		
		threadB
			:queue('foo')
			:queue('bar')
			:queue('baz')
		
		threadB:run()
	end
end

print('thread a event queue: ', #threadA.eventQueue)
print('thread b event queue: ', #threadB.eventQueue)

threadA:stop()
threadB:stop()]]