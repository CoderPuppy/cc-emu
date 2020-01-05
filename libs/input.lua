local prev, luv, T, _bit, pl, exit, exit_seq, event_queue, reboot, tick = ...

local fcntl = prev.require 'posix.fcntl'

local keys = {
	nil,            "one",          "two",           "three",          "four",       --   1
	"five",         "six",          "seven",         "eight",          "nine",       --   6
	"zero",         "minus",        "equals",        "backspace",      "tab",        --  11
	"q",            "w",            "e",             "r",              "t",          --  16
	"y",            "u",            "i",             "o",              "p",          --  21
	"leftBracket",  "rightBracket", "enter",         "leftCtrl",       "a",          --  26
	"s",            "d",            "f",             "g",              "h",          --  31
	"j",            "k",            "l",             "semiColon",      "apostrophe", --  36
	"grave",        "leftShift",    "backslash",     "z",              "x",          --  41
	"c",            "v",            "b",             "n",              "m",          --  46
	"comma",        "period",       "slash",         "rightShift",     "multiply",   --  51
	"leftAlt",      "space",        "capsLock",      "f1",             "f2",         --  56
	"f3",           "f4",           "f5",            "f6",             "f7",         --  61
	"f8",           "f9",           "f10",           "numLock",        "scollLock",  --  66
	"numPad7",      "numPad8",      "numPad9",       "numPadSubtract", "numPad4",    --  71
	"numPad5",      "numPad6",      "numPadAdd",     "numPad1",        "numPad2",    --  76
	"numPad3",      "numPad0",      "numPadDecimal", nil,              nil,          --  81
	nil,            "f11",          "f12",           nil,              nil,          --  86
	nil,            nil,            nil,             nil,              nil,          --  91
	nil,            nil,            nil,             nil,              "f13",        --  96
	"f14",          "f15",          nil,             nil,              nil,          -- 101
	nil,            nil,            nil,             nil,              nil,          -- 106
	nil,            "kana",         nil,             nil,              nil,          -- 111
	nil,            nil,            nil,             nil,              nil,          -- 116
	"convert",      nil,            "noconvert",     nil,              "yen",        -- 121
	nil,            nil,            nil,             nil,              nil,          -- 126
	nil,            nil,            nil,             nil,              nil,          -- 131
	nil,            nil,            nil,             nil,              nil,          -- 136
	"numPadEquals", nil,            nil,             "cimcumflex",     "at",         -- 141
	"colon",        "underscore",   "kanji",         "stop",           "ax",         -- 146
	nil,            nil,            nil,             nil,              nil,          -- 151
	"numPadEnter",  "rightCtrl",    nil,             nil,              nil,          -- 156
	nil,            nil,            nil,             nil,              nil,          -- 161
	nil,            nil,            nil,             nil,              nil,          -- 166
	nil,            nil,            nil,             nil,              nil,          -- 171
	nil,            nil,            nil,             "numPadComma",    nil,          -- 176
	"numPadDivide", nil,            nil,             "rightAlt",       nil,          -- 181
	nil,            nil,            nil,             nil,              nil,          -- 186
	nil,            nil,            nil,             nil,              nil,          -- 191
	nil,            "pause",        nil,             "home",           "up",         -- 196
	"pageUp",       nil,            "left",          nil,              "right",      -- 201
	nil,            "end",          "down",          "pageDown",       "insert",     -- 206
	"delete"                                                                         -- 211
}
for i, name in pairs(keys) do
	keys[name] = i
end

local pats = {
	['!'] = {leftShift = true; one = true; char = '!';};
	['@'] = {leftShift = true; two = true; char = '@';};
	['#'] = {leftShift = true; three = true; char = '#';};
	['$'] = {leftShift = true; four = true; char = '$';};
	['%'] = {leftShift = true; five = true; char = '%';};
	['^'] = {leftShift = true; six = true; char = '^';};
	['&'] = {leftShift = true; seven = true; char = '&';};
	['*'] = {leftShift = true; eight = true; char = '*';};
	['('] = {leftShift = true; nine = true; char = '(';};
	[')'] = {leftShift = true; zero = true; char = ')';};
	['_'] = {leftShift = true; minus = true; char = '_';};
	['+'] = {leftShift = true; equals = true; char = '+';};

	['{'] = {leftShift = true; leftBracket = true; char = '{';};
	['}'] = {leftShift = true; rightBracket = true; char = '}';};

	-- Ctrl-Shift-Grave
	['\30'] = {leftCtrl = true;};

	[':'] = {leftShift = true; semiColon = true; char = ':';};
	['"'] = {leftShift = true; apostrophe = true; char = '"';};
	['~'] = {leftShift = true; grave = true; char = '~';};

	['|'] = {leftShift = true; backslash = true; char = '|';};

	['<'] = {leftShift = true; comma = true; char = '<';};
	['>'] = {leftShift = true; period = true; char = '>';};
	['?'] = {leftShift = true; slash = true; char = '?';};

	['\4'] = {leftCtrl = true; d = true;};
	['\16'] = {leftCtrl = true; p = true;};

	['\27[1;2D'] = {leftShift = true; left = true;};
	['\27[1;2C'] = {leftShift = true; right = true;};
	['\27[1;2A'] = {leftShift = true; up = true;};
	['\27[1;2B'] = {leftShift = true; down = true;};

	['\27[1;3D'] = {leftAlt = true; left = true;};
	['\27[1;3C'] = {leftAlt = true; right = true;};
	['\27[1;3A'] = {leftAlt = true; up = true;};
	['\27[1;3B'] = {leftAlt = true; down = true;};

	[T.key_btab()] = {leftShift = true; tab = true; char = '\t'};
}

for i = 1,26 do
	local lower = string.char(0x60 + i)
	local upper = string.char(0x40 + i)
	pats[lower] = {[lower] = true; char = lower;}
	pats[upper] = {leftShift = true; [lower] = true; char = upper;}
end

for name, pats_ in pairs({
	zero  = {'0', char = '0'};
	one   = {'1', char = '1'};
	two   = {'2', char = '2'};
	three = {'3', char = '3'};
	four  = {'4', char = '4'};
	five  = {'5', char = '5'};
	six   = {'6', char = '6'};
	seven = {'7', char = '7'};
	eight = {'8', char = '8'};
	nine  = {'9', char = '9'};
	minus = {'-', char = '-'};
	equals = {'=', char = '='};
	backspace = {T.key_backspace(), '\8', '\127'};
	tab = {T.tab(), char = '\t'};
	enter = {'\13'};
	semiColon = {';', char = ';'};
	apostrophe = {'\'', char = '\''};
	grave = {'`', char = '`'};
	backslash = {'\\', char = '\\'};
	comma = {',', char = ','};
	period = {'.', char = '.'};
	slash = {'/', char = '/'};
	space = {' ', char = ' '};
	f1 = {T.key_f1()};
	f2 = {T.key_f2()};
	f3 = {T.key_f3()};
	f4 = {T.key_f4()};
	f5 = {T.key_f5()};
	f6 = {T.key_f6()};
	f7 = {T.key_f7()};
	f8 = {T.key_f8()};
	f9 = {T.key_f9()};
	f10 = {T.key_f10()};
	f11 = {T.key_f11()};
	f12 = {T.key_f12()};
	home = {T.key_home()};
	up = {T.key_up()};
	pageUp = {T.key_ppage()};
	left = {T.key_left()};
	right = {T.key_right()};
	['end'] = {T.key_end()};
	down = {T.key_down()};
	pageDown = {T.key_npage()};
	insert = {T.key_ic()};
	delete = {T.key_dc()};
}) do
	for _, pat in ipairs(pats_) do
		pats[pat] = {[name] = true; char = pats_.char;}
	end
end

prev.io.write(T.keypad_xmit())
prev.io.write '\27[?1000h'
prev.io.write '\27[?1002h'
prev.io.write '\27[?1006h'
prev.io.flush()
fcntl.fcntl(1, fcntl.F_SETFL, _bit.bor(fcntl.fcntl(1, fcntl.F_GETFL), fcntl.O_NONBLOCK))

local chard = ''
local down1, down2 = {}, {}
local timers = {}
table.insert(tick, 1, function()
	local sent = {}
	local function send_key(k)
		if sent[k] then return end
		sent[k] = true

		event_queue[#event_queue + 1] = { 'key', keys[k], not not down2[k] }

		if timers[k] then
			luv.timer_stop(timers[k])
			luv.close(timers[k])
		end

		timers[k] = luv.new_timer()
		luv.timer_start(timers[k], 1000/20, 0, function()
			event_queue[#event_queue + 1] = { 'key_up', keys[k] }
			luv.timer_stop(timers[k])
			luv.close(timers[k])
			timers[k] = nil
		end)
	end

	for _, k in ipairs { 'leftCtrl'; 'rightCtrl'; 'leftShift'; 'rightShift'; 'leftAlt'; 'rightAlt'; } do
		if down1[k] then
			send_key(k)
		end
	end
	for k in pairs(down1) do
		if keys[k] then
			send_key(k)
		end
	end

	for char in chard:gmatch '.' do
		event_queue[#event_queue + 1] = { 'char', char }
	end

	down2 = down1
	down1 = {}
	chard = ''
end)

local function handle_key(data)
	-- print(('%q'):format(data))
	while #data > 0 do
		local test = data
		local rest = ''
		local continue = true
		while continue do
			if test == '' then
				break
			end

			continue = false
			if test == '\20' then
				event_queue[#event_queue + 1] = { 'terminate' }
			elseif test == '\3' or test == '\19' then
				exit()
				prev.os.exit()
			elseif test == '\18' then
				reboot()
			elseif pats[test] then
				chard = chard .. (pats[test].char or '')
				for k in pairs(pats[test]) do
					down1[k] = true
				end
			elseif test:sub(1, 1) == '\27' and pats[test:sub(2)] then
				chard = chard .. (pats[test:sub(2)].char or '')
				down1.leftAlt = true
				for k in pairs(pats[test:sub(2)]) do
					down1[k] = true
				end
			else
				rest = test:sub(#test) .. rest
				test = test:sub(1, #test - 1)
				continue = true
			end
		end
		if test == '' then
			prev.print('unknown:', ('%q'):format(data))
			data = data:sub(2)
		else
			data = rest
		end
	end
end

local stdin = luv.new_tty(0, true)
luv.tty_set_mode(stdin, 1)
luv.read_start(stdin, function(_, data)
	while #data > 0 do
		local pre, btn, x, y, m, post = data:match '^(.-)\27%[<(%d+);(%d+);(%d+)([Mm])(.*)$'
		if pre then
			x, y = tonumber(x), tonumber(y)

			local rep = false
			btn = tonumber(btn)
			if (btn >= 32  and btn <= 34) or btn == 100 or btn == 101 then
				rep = true
				btn = btn - 32
			end

			local down = m == 'M'

			if btn == 64 then
				event_queue[#event_queue + 1] = { 'mouse_scroll', -1, x, y }
			elseif btn == 65 then
				event_queue[#event_queue + 1] = { 'mouse_scroll',  1, x, y }
			else
				event_queue[#event_queue + 1] = {
					down and (rep and 'mouse_drag' or 'mouse_click') or 'mouse_up';
					btn == 0 and 1 or btn == 2 and 2 or btn == 1 and 3;
					x; y;
				}
			end

			handle_key(pre)

			data = post
		else
			handle_key(data)
			break
		end
	end
end)

exit_seq[#exit_seq + 1] = function()
	prev.io.write '\27[?1000l'
	prev.io.write '\27[?1002l'
	prev.io.write '\27[?1006l'
	prev.io.write(T.keypad_local())
	prev.io.flush()
	fcntl.fcntl(1, fcntl.F_SETFL, _bit.band(fcntl.fcntl(1, fcntl.F_GETFL), _bit.bnot(fcntl.O_NONBLOCK)))
	luv.tty_set_mode(stdin, 0)
end

return stdin
