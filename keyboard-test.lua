local curses = require 'posix.curses'
local scr = curses.initscr()
curses.raw(true)
curses.echo(false)
curses.nl(true)
scr:keypad(true)
while true do
	local chr = scr:getch()
	print(chr)
	if chr == 3 then
		break
	end
end
