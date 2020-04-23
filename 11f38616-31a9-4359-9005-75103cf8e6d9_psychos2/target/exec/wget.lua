local tA = {...}
local url = tA[1]
local path = tA[2]
local R=component.invoke(component.list("internet")(),"request",url)
if not R then return false end
local f=io.open(path,"wb")
if not f then return false end
repeat
 coroutine.yield()
until R.finishConnect()
local code, message, headers = R.response()
if code > 299 or code < 200 then
 return false, code, message
end
repeat
 coroutine.yield()
 ns = R.read(2048)
 f:write(ns or "")
until not ns
f:close()
