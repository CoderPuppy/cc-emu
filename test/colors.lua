local T = require(jit and 'terminfo-luajit' or 'terminfo-norm')
local function B(r, g, b)
	return string.format('\27[48;2;%d;%d;%dm', r, g, b)
end

for i = 0,7 do
	io.write(i .. ': ' .. T.setaf(i) .. T.setab(i) .. 'A' .. T.sgr0() .. ' | ')
end
