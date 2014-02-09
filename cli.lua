-- require('mobdebug').start()

io.stdout:setvbuf('no')

local dir = '/home/cpup/code/lua/cc-emu/dev'

local path = require 'pl.path'
local emu = require 'emu'

emu(dir)