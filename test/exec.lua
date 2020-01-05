local luv = require 'luv'
local unistd = require 'posix.unistd'

local stdin = luv.new_tty(0, true)
print(luv.tty_get_winsize(stdin))
local h = io.popen '/bin/which lua'
local lua = h:read '*l'
h:close()

local timer = luv.new_timer()
timer:start(1000, 0, function()
	unistd.exec(lua, {'/home/cpup/code/cc-termu/test.lua'})
end)

luv.run()
