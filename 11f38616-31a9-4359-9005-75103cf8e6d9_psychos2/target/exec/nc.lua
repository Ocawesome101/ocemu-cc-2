local minitel = require "minitel"
local tA = {...}

host, port = tA[1], tA[2] or 22

local socket = minitel.open(host,port)
if not socket then return false end
local b = ""
os.spawn(function()
 repeat
  local b = socket:read("*a")
  if b and b:len() > 0 then
   io.write(b)
  end
  coroutine.yield()
 until socket.state ~= "open"
end)
repeat
 local b = io.read()
 if b and b:len() > 0 then
  socket:write(b.."\n")
 end
until socket.state ~= "open"
