-- local curses = require 'posix.curses'
-- local scr = curses.initscr()
-- curses.raw(true)
-- curses.echo(false)
-- curses.nl(true)
-- scr:keypad(true)
-- while true do
-- 	local chr = scr:getch()
-- 	print(chr)
-- 	if chr == 3 then
-- 		break
-- 	end
-- end

local luv = require 'luv'
local p = require 'pl.pretty'.write
local T = require 'terminfo'
io.write(T.get'keypad_xmit')
local stdin = luv.new_tty(0, true)
luv.tty_set_mode(stdin, 1)
luv.read_start(stdin, function(_, data)
	print(p(data))
end)
luv.run()
