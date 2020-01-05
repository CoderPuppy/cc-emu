local uv = require 'luv'
local T = require(jit and 'terminfo-luajit' or 'terminfo-norm')
local fcntl = require 'posix.fcntl'
local _bit = bit32 or require 'bit'

local stdin = uv.new_tty(0, true)
uv.tty_set_mode(stdin, 1)

io.write(T.keypad_xmit())
io.write(T.smcup())
io.write '\27[?1000h'
io.write '\27[?1002h'
io.write '\27[?1006h'
io.flush()
fcntl.fcntl(1, fcntl.F_SETFL, _bit.bor(fcntl.fcntl(1, fcntl.F_GETFL), fcntl.O_NONBLOCK))

local function exit()
	io.write(T.keypad_local())
	io.write(T.rmcup())
	io.write '\27[?1006l'
	io.write '\27[?1002l'
	io.write '\27[?1000l'
	io.flush()

	uv.tty_set_mode(stdin, 0)
	uv.stop()
end

uv.read_start(stdin, function(err, data)
	if err then error(err) end
	print('full', ('%q'):format(data))
	if data == '\3' then exit() end
end)
uv.run()
