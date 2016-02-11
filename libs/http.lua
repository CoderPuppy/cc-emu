local prev, luv, pl, dirname, eventQueue = ...

local function continue(co)
	co = co or coroutine.running()
	return function(...)
		local ok, err = coroutine.resume(co, ...)
		if not ok then error(err) end
	end
end

local decoder = prev.loadfile(pl.path.join(dirname, 'libs', 'http', 'codec.lua'))()

local function parseURL(url)
	if type(url) ~= 'string'  then return false end
	local purl = {}
	local protocol, dest, path = url:match('^(https?)://([^/]+)(/?.*)$')
	purl.protocol = protocol
	purl.path = path == '' and '/' or path
	if not dest then return false end
	local server, port = dest:match('^([^:]+):?(%d*)$')
	if not server then return false end
	purl.server = server
	purl.port = tonumber(port) or 80
	return purl
end

local function dns(addr)
	luv.getaddrinfo(addr, nil, {
		v4mapped = true;
		all = true;
		addrconfig = true;
		canonname = true;
		numericserv = true;
		socktype = 'STREAM';
	}, continue())
	local err, data = coroutine.yield()
	if err then
		error(err)
	end
	return data
end

local function openTCP(ip, port)
	-- print('connecting to ' .. tostring(ip) .. ':' .. tostring(port))
	local client = luv.new_tcp()
	luv.tcp_connect(client, ip, port, continue())
	-- print'connected'
	local err = coroutine.yield()
	if err then
		error(err)
	end
	local socket = {}
	function socket.write(data)
		luv.write(client, data)
	end
	function socket.done()
		luv.shutdown(client)
	end
	function socket.read_start(cb)
		luv.read_start(client, cb)
	end
	function socket.read_stop()
		luv.read_stop(client)
	end
	function socket.close()
		luv.close(client)
	end
	return socket
end

local function read_response()
	local decode = decoder()
	local buffer = ''
	local head
	local contents = ''
	local continue = true
	while continue do
		local err, chunk = coroutine.yield()
		-- print'got data'
		if err then
			error(err)
		elseif chunk then
			buffer = buffer .. chunk
			-- from Luvit
			while true do
				local event, extra = decode(buffer)
				-- print(pl.pretty.write({
				-- 	-- buffer = buffer;
				-- 	event = event;
				-- 	extra = extra;
				-- }))
				if not extra then break end

				buffer = extra
				if type(event) == 'table' then
					head = event
				elseif type(event) == 'string' then
					if #event == 0 then
						continue = false
						break
					else
						contents = contents .. event
					end
				end
			end
		else
			break
		end
	end
	return head, contents
end

local function request(url, postData, headers)
	url = parseURL(url)
	-- print(pl.pretty.write({
	-- 	url = url;
	-- 	postData = postData;
	-- 	headers = headers;
	-- }))
	local ip = url.server:match('^([12]?%d?%d)%.(%d?%d?%d)%.(%d?%d?%d)%.(%d?%d?%d)') and url.server or dns(url.server)[1].addr
	-- local ip = '127.0.0.1'
	-- url.port = 8080
	local socket = openTCP(ip, url.port)
	if url.protocol == 'https' then
		socket = tls(socket, url)
	end
	socket.write((postData and 'POST' or 'GET') .. ' ' .. url.path .. ' HTTP/1.1\r\n')
	local _headers = {}
	for k, v in pairs(headers or {}) do
		_headers[k:lower()] = v
	end
	if not _headers.host then
		_headers.host = url.server
	end
	for k, v in pairs(_headers) do
		socket.write(k .. ': ' .. tostring(v) .. '\r\n')
	end
	socket.write('\r\n')
	if postData then
		socket.write(postData)
	end
	-- socket.done()
	socket.read_start(continue())
	local head, data = read_response()
	socket.read_stop()
	socket.close()
	return head, data
end

local http = {}
function http.checkURL(url)
	return not not parseURL(url)
end
function http.request(url, postData, headers)
	local origURL = url
	local co = coroutine.create(function()
		xpcall(function()
			local head, data
			local continue = true
			while continue do
				head, data = request(url, postData, headers)
				if math.floor(head.code / 300) == 1 then
					for _, header in ipairs(head) do
						if header[1]:lower() == 'location' then
							url = header[2]
						end
					end
				else
					continue = false
				end
			end
			if math.floor(head.code / 200) == 1 then
				local res = {}
				function res.close() end
				function res.readLine()
					local line = data:match '^([^\n\r]*)\r?\n'
					if line then
						data = data:sub(#line + 1)
						return line
					end
				end
				function res.readAll()
					local dat = data
					data = ''
					return dat
				end
				function res.getResponseCode()
					return head.code
				end
				eventQueue[#eventQueue + 1] = { 'http_success', origURL, res }
			else
				eventQueue[#eventQueue + 1] = { 'http_failure', origURL, 'got: ' .. tostring(head.code) }
			end
		end, function(err)
			eventQueue[#eventQueue + 1] = { 'http_failure', origURL, err }
		end)
	end)
	continue(co)()
	return true
end
return http
