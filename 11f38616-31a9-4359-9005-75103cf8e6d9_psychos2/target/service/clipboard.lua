local lc = computer.uptime()
_G.clip = ""
while true do
 local eT = {coroutine.yield()}
 if eT[1] == "clipboard" then
  if computer.uptime() > lc + 5 then
   _G.clip = ""
  end
  _G.clip = _G.clip .. eT[3]
 end
end
