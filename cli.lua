io.stdout:setvbuf('no')

local args = {...}
-- local args = { '/home/cpup/code/peak/', 'dev/test.lua' }

local path = require 'pl.path'
local dirname = path.dirname(debug.getinfo(1).source:match("@(.*)$"))
local emu = require(path.normpath(path.join(dirname, 'emu')))

emu(args[1], args[2])