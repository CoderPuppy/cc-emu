-- require('mobdebug').start()

io.stdout:setvbuf('no')

local path = require 'pl.path'

package.path = package.path .. ';' .. path.normpath(path.join(arg[0], '../?.lua'))

local emu = require 'emu'

local args = {...}
local dir = table.remove(args, 1)
-- local dir = '/home/cpup/code/lua/cc-emu/dev'
dir = path.normpath(path.join(path.currentdir(), dir))

emu(dir, unpack(args, 1, select('#', ...) - 1))
