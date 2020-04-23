local event = {}
function event.pull(t,...) -- return an event, optionally with timeout *t* and filter *...*.
 local tA = {...}
 if type(t) == "string" then
  table.insert(tA,1,t)
  t = 0
 end
 if not t or t <= 0 then
  t = math.huge
 end
 local tE = computer.uptime()+t
 repeat
  tEv = {coroutine.yield()}
  local ret = true
  for i = 1, #tA do
   if type(tEv[i]) == "string" and type(tA[i]) == "string" then
    if not (tEv[i] or ""):match(tA[i]) then
     ret = false
    end
   else
    ret = tEv[i] == tA[i]
   end
  end
  if ret then return table.unpack(tEv) end
 until computer.uptime() > tE
 return nil
end

function event.listen(e,f) -- run function *f* for every occurance of event *e*
 os.spawn(function() while true do
  local tEv = {coroutine.yield()}
  if tEv[1] == e then
   f(table.unpack(tEv))
  end
  if not os.taskInfo(os.taskInfo().parent) or (tEv[1] == "unlisten" and tEv[2] == e and tEv[3] == tostring(f)) then break end
 end end,string.format("[%d] %s listener",os.pid(),e))
end

function event.ignore(e,f) -- stop function *f* running for every occurance of event *e*
 computer.pushSignal("unlisten",e,tostring(f))
end

return event
