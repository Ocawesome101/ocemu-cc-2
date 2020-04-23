local lastkey = computer.uptime()
local state = true
local delay = 60
while true do
 tEv = {coroutine.yield()}
 if tEv[1] == "key_down" then
  lastkey = computer.uptime()
  if not state then
   for addr in component.list("screen") do
    component.invoke(addr,"turnOn")
   end
   state = true
  end
 end
 if computer.uptime() > lastkey + delay and state then
  for addr in component.list("screen") do
    component.invoke(addr,"turnOff")
  end
  state = false
 end
end
