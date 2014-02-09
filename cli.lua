-- require('mobdebug').start()

io.stdout:setvbuf('no')

local path = require 'pl.path'
local emu = require 'emu'

-- local dir = ...
local dir = '/home/cpup/code/lua/cc-emu/dev'
dir = path.normpath(path.join(path.currentdir(), dir))

emu(dir)