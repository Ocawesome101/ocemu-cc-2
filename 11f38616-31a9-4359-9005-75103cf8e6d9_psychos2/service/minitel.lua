--[[
packet format:
packetID: random string to differentiate
packetType:
 - 0: unreliable
 - 1: reliable, requires ack
 - 2: ack packet
destination: end destination hostname
sender: original sender of packet
data: the actual packet data, duh.
]]--

local listeners,timers,processes,modems = {},{},{},{}
local hostname = os.getenv("HOSTNAME")

local cfg = {}
cfg.debug = false
cfg.port = 4096
cfg.retry = 10
cfg.retrycount = 64
cfg.route = true

local event, component, computer, serial = event, component, computer, serial
local hnpath, cfgpath = "", ""

OPENOS, PSYCHOS, KITTENOS = false, false, false
if _OSVERSION:sub(1,6) == "OpenOS" then
 OPENOS = true
 hnpath = "/etc/hostname"
 cfgpath = "/etc/minitel.cfg"
elseif _OSVERSION:sub(1,7) == "PsychOS" then
 PSYCHOS = true
 hnpath = "/boot/cfg/hostname"
 cfgpath = "/boot/cfg/minitel.cfg"
elseif _OSVERSION:sub(1,8) == "KittenOS" then
 KITTENOS = true
end

-- packet cache: [packet ID]=uptime
local pcache = {}
cfg.pctime = 30

--[[
LKR format:
address {
 local hardware address
 remote hardware address
 time last received
}
]]--

cfg.sroutes = {}
local rcache = setmetatable({},{__index=cfg.sroutes})
cfg.rctime = 15

--[[
packet queue format:
{
 packetID,
 packetType
 destination,
 data,
 timestamp,
 attempts
}
]]--
local pqueue = {}

local function saveconfig()
 if OPENOS or PSYCHOS then
  local f = io.open(cfgpath,"wb")
  if f then
   f:write(serial.serialize(cfg))
   f:close()
  end
 end
end
local function loadconfig()
 hostname = os.getenv("HOSTNAME") or computer.address():sub(1,8)
 if OPENOS or PSYCHOS then
  local f,g=io.open(hnpath,"rb")
  if f then
   hostname = f:read("*a"):match("(.-)\n")
   f:close()
  end
  local f = io.open(cfgpath,"rb")
  if f then
   local newcfg = serial.unserialize(f:read("*a")) or {}
   f:close()
   for k,v in pairs(newcfg) do
    cfg[k] = v
   end
  else
   saveconfig()
  end
 elseif KITTENOS then
  local globals = neo.requestAccess("x.neo.pub.globals") -- KittenOS standard hostname stuff
  if globals then
   hostname = globals.getSetting("hostname") or hostname
   globals.setSetting("hostname",hostname)
  end
 end
end

-- specific OS support here
if PSYCHOS then -- PsychOS specific code
 serial = require "serialization"
elseif OPENOS then -- OpenOS specific code
 event = require "event"
 component = require "component"
 computer = require "computer"
 serial = require "serialization"
 listener = false
elseif KITTENOS then
 neo.requireAccess("s.h.modem_message","pulling packets")
 computer = {["uptime"]=os.uptime,["address"]=os.address} -- wrap computer so the OpenOS code more or less works
 function computer.pushSignal(...)
  for k,v in pairs(processes) do
   v(...)
  end
 end
end

local function dprint(...)
 if cfg.debug then
  print(...)
 end
end

function start()
 loadconfig()
 print("Hostname: "..hostname)
 if listener then return end
 if OPENOS or PSYCHOS then
  for a,t in component.list("modem") do
   modems[#modems+1] = component.proxy(a)
  end
  for k,v in ipairs(modems) do
   v.open(cfg.port)
   print("Opened port "..cfg.port.." on "..v.address:sub(1,8))
  end
  for a,t in component.list("tunnel") do
   modems[#modems+1] = component.proxy(a)
  end
 elseif KITTENOS then
  for p in neo.requireAccess("c.modem","networking").list() do -- fun stuff for KittenOS
   dprint(p.address)
   modems[p.address] = p
  end
  for k,v in pairs(modems) do
   v.open(port)
   print("Opened port "..port.." on "..v.address)
  end
  for p in neo.requireAccess("c.tunnel","networking").list() do
   dprint(p.address)
   modems[p.address] = p
  end
 end
 
 local function genPacketID()
  local npID = ""
  for i = 1, 16 do
   npID = npID .. string.char(math.random(32,126))
  end
  return npID
 end
 
 local function sendPacket(packetID,packetType,dest,sender,vPort,data,repeatingFrom)
  if rcache[dest] then
   dprint("Cached", rcache[dest][1],"send",rcache[dest][2],cfg.port,packetID,packetType,dest,sender,vPort,data)
   if component.type(rcache[dest][1]) == "modem" then
    component.invoke(rcache[dest][1],"send",rcache[dest][2],cfg.port,packetID,packetType,dest,sender,vPort,data)
   elseif component.type(rcache[dest][1]) == "tunnel" then
    component.invoke(rcache[dest][1],"send",packetID,packetType,dest,sender,vPort,data)
   end
  else
   dprint("Not cached", cfg.port,packetID,packetType,dest,sender,vPort,data)
   for k,v in pairs(modems) do
    if v.address ~= repeatingFrom or (v.type ~= "tunnel" and v.isWireless()) then
     if v.type == "modem" then
      v.broadcast(cfg.port,packetID,packetType,dest,sender,vPort,data)
     elseif v.type == "tunnel" then
      v.send(packetID,packetType,dest,sender,vPort,data)
     end
    end
    end
  end
 end
 
 local function pruneCache()
  for k,v in pairs(rcache) do
   dprint(k,v[3],computer.uptime())
   if v[3] < computer.uptime() then
    rcache[k] = nil
    dprint("pruned "..k.." from routing cache")
   end
  end
  for k,v in pairs(pcache) do
   if v < computer.uptime() then
    pcache[k] = nil
    dprint("pruned "..k.." from packet cache")
   end
  end
 end

 local function checkPCache(packetID)
  dprint(packetID)
  for k,v in pairs(pcache) do
   dprint(k)
   if k == packetID then return true end
  end
  return false
 end
 
 local function processPacket(_,localModem,from,pport,_,packetID,packetType,dest,sender,vPort,data)
  pruneCache()
  if pport == cfg.port or pport == 0 then -- for linked cards
   dprint(cfg.port,vPort,packetType,dest)
   if checkPCache(packetID) then return end
   if dest == hostname then
    if packetType == 1 then
     sendPacket(genPacketID(),2,sender,hostname,vPort,packetID)
    end
    if packetType == 2 then
     dprint("Dropping "..data.." from queue")
     pqueue[data] = nil
     computer.pushSignal("net_ack",data)
    end
    if packetType ~= 2 then
     computer.pushSignal("net_msg",sender,vPort,data)
    end
   elseif dest:sub(1,1) == "~" then -- broadcasts start with ~
    computer.pushSignal("net_broadcast",sender,vPort,data)
   elseif cfg.route then -- repeat packets if route is enabled
    sendPacket(packetID,packetType,dest,sender,vPort,data,localModem)
   end
   if not rcache[sender] then -- add the sender to the rcache
    dprint("rcache: "..sender..":", localModem,from,computer.uptime())
    rcache[sender] = {localModem,from,computer.uptime()+cfg.rctime}
   end
   if not pcache[packetID] then -- add the packet ID to the pcache
    pcache[packetID] = computer.uptime()+cfg.pctime
   end
  end
 end
 
 local function queuePacket(_,ptype,to,vPort,data,npID)
  npID = npID or genPacketID()
  if to == hostname or to == "localhost" then
   computer.pushSignal("net_msg",to,vPort,data)
   computer.pushSignal("net_ack",npID)
   return
  end
  pqueue[npID] = {ptype,to,vPort,data,0,0}
  dprint(npID,table.unpack(pqueue[npID]))
 end
 
 
 local function packetPusher()
  for k,v in pairs(pqueue) do
   if v[5] < computer.uptime() then
    dprint(k,v[1],v[2],hostname,v[3],v[4])
    sendPacket(k,v[1],v[2],hostname,v[3],v[4])
    if v[1] ~= 1 or v[6] == cfg.retrycount then
     pqueue[k] = nil
    else
     pqueue[k][5]=computer.uptime()+cfg.retry
     pqueue[k][6]=pqueue[k][6]+1
    end
   end
  end
 end

 listeners["modem_message"]=processPacket
 listeners["net_send"]=queuePacket
 if OPENOS then
  event.listen("modem_message",processPacket)
  print("Started packet listening daemon: "..tostring(processPacket))
  event.listen("net_send",queuePacket)
  print("Started packet queueing daemon: "..tostring(queuePacket))
  timers[#timers+1]=event.timer(0,packetPusher,math.huge)
  print("Started packet pusher: "..tostring(timers[#timers]))
 elseif KITTENOS then
  neo.requireAccess("r.svc.minitel","minitel daemon")(function(pkg,pid,sendSig)
  processes[pid] = sendSig
  return {["sendPacket"]=queuePacket}
 end)
 end
 
 if KITTENOS or PSYCHOS then
  while true do
   local ev = {coroutine.yield()}
   packetPusher()
   pruneCache()
   if ev[1] == "k.procdie" then
    processes[ev[3]] = nil
   end
   if listeners[ev[1]] then
    pcall(listeners[ev[1]],table.unpack(ev))
   end
  end
 end
end

function stop()
 for k,v in pairs(listeners) do
  event.ignore(k,v)
  print("Stopped listener: "..tostring(v))
 end
 for k,v in pairs(timers) do
  event.cancel(v)
  print("Stopped timer: "..tostring(v))
 end
end

function set(k,v)
 if type(cfg[k]) == "string" then
  cfg[k] = v
 elseif type(cfg[k]) == "number" then
  cfg[k] = tonumber(v)
 elseif type(cfg[k]) == "boolean" then
  if v:lower():sub(1,1) == "t" then
   cfg[k] = true
  else
   cfg[k] = false
  end
 end
 print("cfg."..k.." = "..tostring(cfg[k]))
 saveconfig()
end

function set_route(to,laddr,raddr)
 cfg.sroutes[to] = {laddr,raddr,0}
end
function del_route(to)
 cfg.sroutes[to] = nil
end

if not OPENOS then
 start()
end
