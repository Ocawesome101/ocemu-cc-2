print(pcall(function()
local minitel = require "minitel"
local port = 22
--local logfile = "/boot/termsrv.log"

local oout = io.output()
local pname = os.taskInfo(os.pid()).name
local function sread(self, len)
 while true do
  local d=self.sock:read(len)
  if d then
   return d
  end
  coroutine.yield()
 end
end
local function swrite(self, data)
 while self.flushing do
  coroutine.yield()
 end
 if data and data:len() > 0 then
  self.wb = self.wb .. (data or "")
 end
end
local function sclose(self)
 self.sock:close()
end
local function sflush(self)
 self.flushing = true
 self.sock:write(self.wb)
 self.wb = ""
 self.flushing = false
end
while true do
 local sock = minitel.listen(port)
 print(string.format("Connection from %s:%d",sock.addr,sock.port))
 os.spawn(function() _G.worked = {pcall(function()
  local fh = {}
  fh.sock = sock
  fh.read = sread
  fh.write = swrite
  fh.close = sclose
  fh.flush = sflush
  fh.wb = ""
  io.input(fh)
  io.output(fh)
  fh:write(string.format("Connected to %s on port %d\n",os.getenv("HOSTNAME"),sock.port))
  local pid = os.spawnfile("/boot/exec/shell.lua")
  repeat
   coroutine.yield()
   if fh.wb:len() > 0 then
    fh:flush()
   end
  until sock.state ~= "open" or not os.taskInfo(pid)
  sock:close()
  os.kill(pid)
  oout:write(string.format("Session %s:%d ended",sock.addr,sock.port))
 end)} end,string.format(pname.." [%s:%d]",sock.addr,sock.port))
end
end))
