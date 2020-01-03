local luv = require 'luv'

local async = luv.new_async(function(msg)
	print(msg)
end)

local thread = luv.new_thread(function(async)
	local luv = require 'luv'
	local time = require 'posix.time'

	time.nanosleep { tv_sec = 1 }
	luv.async_send(async, 'hi')
end, async)

luv.run()
