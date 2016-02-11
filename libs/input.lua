local prev, luv, T, _bit, pl, exit, exit_seq, event_queue = ...

local fcntl = prev.require 'posix.fcntl'

local _keys = {
	nil; -- none
	{'1', '!'};
	{'2', '@'};
	{'3', '#'};
	{'4', '$'};
	{'5', '%'};
	{'6', '^'};
	{'7', '&'};
	{'8', '*'};
	{'9', '('};
	{'0', ')'};
	{'-', '_'};
	{'=', '+'};
	{T.key_backspace(), '\8', '\127'}; -- backspace
	{T.tab(), T.key_btab()};
	{'q', 'Q'};
	{'w', 'W'};
	{'e', 'E'};
	{'r', 'R'};
	{'t', 'T'};
	{'y', 'Y'};
	{'u', 'U'};
	{'i', 'I'};
	{'o', 'O'};
	{'p', 'P'};
	{'[', '{'};
	{']', '}'};
	'\13'; -- enter
	'\30'; -- CS` should work as left ctrl
	{'a', 'A'};
	{'s', 'S'};
	{'d', 'D'};
	{'f', 'F'};
	{'g', 'G'};
	{'h', 'H'};
	{'j', 'J'};
	{'k', 'K'};
	{'l', 'L'};
	{';', ':'};
	{'\'', '"'};
	{'`', '~'};
	nil; -- left shift
	{'\\', '|'};
	{'z', 'Z'};
	{'x', 'X'};
	{'c', 'C'};
	{'v', 'V'};
	{'b', 'B'};
	{'n', 'N'};
	{'m', 'M'};
	{',', '<'};
	{'.', '>'};
	{'/', '?'};
	nil; -- right shift
	nil; -- multiply?
	nil; -- left alt
	' ';
	nil; -- caps lock
	T.key_f1(); -- f1
	T.key_f2(); -- f2
	T.key_f3(); -- f3
	T.key_f4(); -- f4
	T.key_f5(); -- f5
	T.key_f6(); -- f6
	T.key_f7(); -- f7
	T.key_f8(); -- f8
	T.key_f9(); -- f9
	T.key_f10(); -- f10
	nil; -- numlock
	nil; -- scrolllock
	nil; -- num pad 7
	nil; -- num pad 8
	nil; -- num pad 9
	nil; -- num pad sub
	nil; -- num pad 4
	nil; -- num pad 5
	nil; -- num pad 6
	nil; -- num pad add
	nil; -- num pad 1
	nil; -- num pad 2
	nil; -- num pad 3
	nil; -- num pad 0
	nil; -- num pad dec
	nil;
	nil;
	nil;
	T.key_f11(); -- f11 -- TODO: this could be wrong
	T.key_f12(); -- f12
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- f13
	nil; -- f14
	nil; -- f15
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- kana
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- convert
	nil;
	nil; -- no convert
	nil;
	nil; -- yen
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- num pad equals
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- kanji
	nil; -- stop
	nil; -- ax
	nil;
	nil; -- num pad enter
	nil; -- right ctrl
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- num pad comma
	nil;
	nil; -- num pad divide
	nil;
	nil;
	nil; -- right alt
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil;
	nil; -- pause
	nil;
	T.key_home(); -- home
	T.key_up(); -- up
	T.key_ppage(); -- page up
	nil;
	T.key_left(); -- left
	nil;
	T.key_right(); -- right
	nil;
	T.key_end(); -- end
	T.key_down(); -- down
	T.key_npage(); -- page down
	T.key_ic(); -- insert
	nil; -- delete
	nil;
}

local keys = {}
for cc, real in pairs(_keys) do
	keys[cc] = real
	if type(real) == 'table' then
		for _, seq in ipairs(real) do
			keys[seq] = cc
		end
	else
		keys[real] = cc
	end
end

prev.io.write(T.keypad_xmit())
fcntl.fcntl(1, fcntl.F_SETFL, _bit.bor(fcntl.fcntl(1, fcntl.F_GETFL), fcntl.O_NONBLOCK))

local stdin = luv.new_tty(0, true)
luv.tty_set_mode(stdin, 1)
luv.read_start(stdin, function(_, data)
	-- print(pl.pretty.write(data))

	local function sendKey(key, test, char)
		if (#test == 1 or (#test == 2 and test:sub(1, 1) == '\27')) and char > 9 and char < 127 and char ~= 13 and char ~= 26 and char ~= 20 and char ~= 27 and char ~= 30 then
			event_queue[#event_queue + 1] = { 'char', test }
		end
		event_queue[#event_queue + 1] = { 'key', key }
	end
	
	local start = 1
	while start <= #data do
		local test = ''
		local i = start
		while true do
			local char = string.byte(data:sub(i, i))
			test = test .. data:sub(i, i)
			i = i + 1

			if test == '\20' then
				event_queue[#event_queue + 1] = { 'terminate' }
				break
			elseif test == '\3' or test == '\19' then
				io.write(T.clear())
				exit()
				prev.os.exit()
			elseif test == '\18' then
				reboot()
				break
			end

			local key = keys[test]
			if key then
				sendKey(key, test, char)
				break
			end

			if #test >= #data then
				local found = false
				if test:sub(1, 1) == '\27' then
					for i = 2, #test do
						local test_ = test:sub(2, i)
						local key = keys[test_]
						if key then
							event_queue[#event_queue + 1] = { 'key', 56 }
							sendKey(key, test_, char)
							found = true
							break
						end
					end
				end
				if not found then
					print('unknown key seq: ' .. pl.pretty.write(test))
				end
				break
			end
		end
		start = i
	end
end)

exit_seq[#exit_seq + 1] = function()
	fcntl.fcntl(1, fcntl.F_SETFL, _bit.band(fcntl.fcntl(1, fcntl.F_GETFL), _bit.bnot(fcntl.O_NONBLOCK)))
	io.write(T.keypad_local())
	luv.tty_set_mode(stdin, 0)
end

return stdin
