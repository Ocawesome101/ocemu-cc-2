local minitel = require "minitel"

local tA = {...}

local function parseURL(url)
 local proto,addr = url:match("(.-)://(.+)")
 addr = addr or url
 local hp, path = addr:match("(.-)(/.*)")
 hp, path = hp or addr, path or "/"
 local host, port = hp:match("(.+):(.+)")
 host = host or hp
 return proto, host, port, path
end

local proto, host, port, path = parseURL(tA[1])
proto,port = proto or "fget", port or 70
local fname, rtype = tA[2] or "-", tA[3] or "t"

local sock = minitel.open(host,port)
local f = nil
if fname ~= "-" then
 f = io.open(fname,"w")
 if not f then error("couldn't open file for writing") end
else
 f = io.open(os.getenv("t"))
 f.close = function() end
end
if not sock then error("couldn't open connection to host") end
sock:write(string.format("%s%s\n",rtype,path))
local rtype, buf = "", ""
repeat
 coroutine.yield()
 rtype = sock:read(1)
until rtype ~= ""
repeat
 coroutine.yield()
 buf = sock:read("*a")
 f:write(buf)
until sock.state == "closed" and buf == ""
f:close()
