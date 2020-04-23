local delay = 60
local port = 3442
local message = "WoLBeacon"

for modem in component.list("modem") do
 component.invoke(modem,"setWakeMessage",message)
end

local ltime = computer.uptime()
while true do
 if computer.uptime() > ltime+delay then
  for modem in component.list("modem") do
   component.invoke(modem,"broadcast",port,message)
  end
  ltime=computer.uptime()
 end
 coroutine.yield()
end
