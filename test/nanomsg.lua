local nn = require 'nanomsg'

local s = nn.socket(nn.AF_SP, nn.NN_SUB)
s:connect('ipc://pub.sock')
s:setsockopt(nn.NN_SUB, nn.NN_SUB_SUBSCRIBE, '')

local poll = nn.poll_arr(s)
local fd = poll[1]

-- while true do
-- 	print(s:recv_msg())
-- end
while true do
	print(poll:poll())
	if fd:inp() then
		print('inp')
		print(s:recv_msg())
	end
end
