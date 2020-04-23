if os.taskInfo(1) and os.pid() ~= 1 then
 return false, "init already started"
end
os.setenv("PWD","/boot")
io.input("/dev/null")
io.output("/dev/syslog")
local f = io.open("/boot/cfg/hostname","rb")
local hostname = computer.address():sub(1,8)
if f then
 hostname = f:read("*l")
 f:close()
end
os.setenv("HOSTNAME",hostname)
syslog(string.format("Hostname set to %s",hostname))
local pids = {}
local function loadlist()
 local f = io.open("/boot/cfg/init.txt","rb")
 if not f then return false end
 for line in f:read("*a"):gmatch("[^\r\n]+") do
  pids[line] = -1
 end
 f:close()
end
loadlist()
while true do
 for k,v in pairs(pids) do
  if not os.taskInfo(v) then
   syslog("Starting service "..k)
   pids[k] = os.spawnfile("/boot/service/"..k)
  end
 end
 coroutine.yield()
end
