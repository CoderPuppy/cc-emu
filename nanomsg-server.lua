local nn = require 'nn'

local pub_addr, inp_addr = ...

local inp = nn.socket(nn.AF_SP, nn.NN_PULL)
inp:bind(inp_addr)

local pub = nn.socket(nn.AF_SP, nn.NN_PUB)
pub:bind(pub_addr)

while true do
	pub:send(inp:recv())
end
