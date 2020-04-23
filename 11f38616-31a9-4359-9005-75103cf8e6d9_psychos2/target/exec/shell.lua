local serial = require "serialization"
local event = require "event"
print(pcall(function()
local shenv = {}
function shenv.quit()
 os.setenv("run",nil)
end
shenv.cd = os.chdir
shenv.mkdir = fs.makeDirectory
local function findPath(name)
 path = os.getenv("PATH") or "/boot/exec"
 for l in path:gmatch("[^\n]+") do
  if fs.exists(l.."/"..name) then
   return l.."/"..name
  elseif fs.exists(l.."/"..name..".lua") then
   return l.."/"..name..".lua"
  end
 end
end
setmetatable(shenv,{__index=function(_,k)
 local fp = findPath(k)
 if _G[k] then
  return _G[k]
 elseif _G.libs[k] then
  return _G.libs[k]
 elseif fp then
  return function(...)
   local tA = {...}
   local pid = os.spawnfile(fp,fp,table.unpack(tA))
   local tE = {event.pull("process_finished",pid)}
   if tE[1] == true then
    table.remove(tE,1)
   end
   return table.unpack(tE)
  end
 end
end})
print(_VERSION)
os.setenv("run",true)
while os.getenv("run") do
 io.write(string.format("%s:%s> ",os.getenv("HOSTNAME") or "localhost",(os.getenv("PWD") or _VERSION)))
 local input=io.read()
 if input:sub(1,1) == "=" then
  input = "return "..input:sub(2)
 end
 tResult = {pcall(load(input,"shell","t",shenv))}
 if tResult[1] == true then table.remove(tResult,1) end
 for k,v in pairs(tResult) do
  if type(v) == "table" then
   print(serial.serialize(v,true))
  else
   print(v)
  end
 end
end
end))
