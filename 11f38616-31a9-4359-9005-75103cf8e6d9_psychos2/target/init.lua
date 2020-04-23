_OSVERSION="PsychOS 2.0a1-4ef792a"

do
syslog = {}
syslog.emergency = 0
syslog.alert = 1
syslog.critical = 2
syslog.error = 3
syslog.warning = 4
syslog.notice = 5
syslog.info = 6
syslog.debug = 7

local rdprint=dprint or function() end
setmetatable(syslog,{__call = function(_,msg, level, service)
level, service = level or syslog.info, service or (os.taskInfo(os.pid()) or {}).name or "unknown"
rdprint(string.format("syslog: [%s:%d/%d] %s",service,os.pid(),level,msg))
computer.pushSignal("syslog",msg, level, service)
end})
function dprint(...)
for k,v in pairs({...}) do
syslog(v,syslog.debug)
end
end
end

do
local tTasks,nPid,nTimeout,cPid = {},1,1,0 -- table of tasks, next process ID, event timeout, current PID
function os.spawn(f,n) -- creates a process from function *f* with name *n*
tTasks[nPid] = {
c=coroutine.create(f), -- actual coroutine
n=n, -- process name
p=nPid, -- process PID
P=cPid, -- parent PID
e={} -- environment variables
}
if tTasks[cPid] then
for k,v in pairs(tTasks[cPid].e) do
tTasks[nPid].e[k] = tTasks[nPid].e[k] or v
end
end
nPid = nPid + 1
return nPid - 1
end
function os.kill(pid) -- removes process *pid* from the task list
tTasks[pid] = nil
end
function os.pid() -- returns the current process' PID
return cPid
end
function os.tasks() -- returns a table of process IDs
local rt = {}
for k,v in pairs(tTasks) do
rt[#rt+1] = k
end
return rt
end
function os.taskInfo(pid) -- returns info on process *pid* as a table with name and parent values
pid = pid or os.pid()
if not tTasks[pid] then return false end
return {name=tTasks[pid].n,parent=tTasks[pid].P}
end
function os.sched() -- the actual scheduler function
os.sched = nil
while #tTasks > 0 do
local tEv = {computer.pullSignal(nTimeout)}
for k,v in pairs(tTasks) do
if coroutine.status(v.c) ~= "dead" then
cPid = k
coroutine.resume(v.c,table.unpack(tEv))
else
tTasks[k] = nil
end
end
end
end
function os.setenv(k,v) -- set's the current process' environment variable *k* to *v*, which is passed to children
if tTasks[cPid] then
tTasks[cPid].e[k] = v
end
end
function os.getenv(k) -- gets a process' *k* environment variable
if tTasks[cPid] then
return tTasks[cPid].e[k]
end
end
end

function os.chdir(p) -- changes the current working directory of the calling process to the directory specified in *p*, returning true or false, error
if not (p:sub(1,1) == "/") then
local np = {}
for k,v in pairs(fs.segments(os.getenv("PWD").."/"..p)) do
if v == ".." then
np[#np] = nil
else
np[#np+1] = v
end
end
p = "/"..table.concat(np,"/")
end
if fs.list(p) then
os.setenv("PWD",p)
else
return false, "no such directory"
end
end

do
fs = {}
local fsmounts = {}

-- basics
function fs.segments(path) -- splits *path* on each /
local segments = {}
for segment in path:gmatch("[^/]+") do
segments[#segments+1] = segment
end
return segments
end
function fs.resolve(path) -- resolves *path* to a specific filesystem mount and path
if not path or path == "." then path = os.getenv("PWD") end
if path:sub(1,1) ~= "/" then path=(os.getenv("PWD") or "").."/"..path end
local segments, rpath, rfs= fs.segments(path)
local rc = #segments
for i = #segments, 1, -1 do
if fsmounts[table.concat(segments, "/", 1, i)] ~= nil then
return table.concat(segments, "/", 1, i), table.concat(segments, "/", i+1)
end
end
return "/", table.concat(segments,"/")
end

-- generate some simple functions
for k,v in pairs({"makeDirectory","exists","isDirectory","list","lastModified","remove","size","spaceUsed","spaceTotal","isReadOnly","getLabel"}) do
fs[v] = function(path)
local fsi,path = fs.resolve(path)
return fsmounts[fsi][v](path)
end
end

local function fread(self,length)
if length == "*a" then
length = math.huge
end
if type(length) == "number" then
local rstr, lstr = "", ""
repeat
lstr = fsmounts[self.fs].read(self.fid,math.min(2^16,length-rstr:len())) or ""
rstr = rstr .. lstr
until rstr:len() == length or lstr == ""
return rstr
elseif type(length) == "string" then
local buf = ""
if length == "*l" then
length = "\n"
end
repeat
local rb = fsmounts[self.fs].read(self.fid,1) or ""
buf = buf .. rb
until buf:match(length) or rb == ""
return buf:match("(.*)"..length)
end
return fsmounts[self.fs].read(self.fid,length)
end
local function fwrite(self,data)
fsmounts[self.fs].write(self.fid,data)
end
local function fseek(self,dist)
fsmounts[self.fs].seek(self.fid,dist)
end
local function fclose(self)
fsmounts[self.fs].close(self.fid)
end

function fs.open(path,mode) -- opens file *path* with mode *mode*
mode = mode or "rb"
local fsi,path = fs.resolve(path)
if not fsmounts[fsi] then return false end
local fid = fsmounts[fsi].open(path,mode)
if fid then
local fobj = {["fs"]=fsi,["fid"]=fid,["seek"]=fseek,["close"]=fclose}
if mode:find("r") then
fobj.read = fread
end
if mode:find("w") then
fobj.write = fwrite
end
return fobj
end
return false
end

function fs.copy(from,to) -- copies a file from *from* to *to*
local of = fs.open(from,"rb")
local df = fs.open(to,"wb")
if not of or not df then
return false
end
df:write(of:read("*a"))
df:close()
of:close()
end

function fs.rename(from,to) -- moves file *from* to *to*
local ofsi, opath = fs.resolve(from)
local dfsi, dpath = fs.resolve(to)
if ofsi == dfsi then
fsmounts[ofsi].rename(opath,dpath)
return true
end
fs.copy(from,to)
fs.remove(from)
return true
end

function fs.mount(path,proxy) -- mounts the filesystem *proxy* to the mount point *path* if it is a directory. BYO proxy.
if fs.isDirectory(path) and not fsmounts[table.concat(fs.segments(path),"/")] then
fsmounts[table.concat(fs.segments(path),"/")] = proxy
return true
end
return false, "path is not a directory"
end
function fs.umount(path)
local fsi,_ = fs.resolve(path)
fsmounts[fsi] = nil
end

function fs.mounts() -- returns a table containing the mount points of all mounted filesystems
local rt = {}
for k,v in pairs(fsmounts) do
rt[#rt+1] = k,v.address or "unknown"
end
return rt
end

function fs.address(path) -- returns the address of the filesystem at a given path, if applicable
local fsi,_ = fs.resolve(path)
return fsmounts[fsi].address
end
function fs.type(path) -- returns the component type of the filesystem at a given path, if applicable
local fsi,_ = fs.resolve(path)
return fsmounts[fsi].type
end

fsmounts["/"] = component.proxy(computer.tmpAddress())
fs.makeDirectory("temp")
if computer.getBootAddress then
fs.makeDirectory("boot")
fs.mount("boot",component.proxy(computer.getBootAddress()))
end

end

io = {}
function io.input(fd)
if type(fd) == "string" then
fd=fs.open(fd,"rb")
end
if fd then
os.setenv("STDIN",fd)
end
return os.getenv("STDIN")
end
function io.output(fd)
if type(fd) == "string" then
fd=fs.open(fd,"wb")
end
if fd then
os.setenv("STDOUT",fd)
end
return os.getenv("STDOUT")
end

io.open = fs.open

function io.read(...)
return io.input():read()
end
function io.write(...)
io.output():write(...)
end

function print(...)
for k,v in ipairs({...}) do
io.write(tostring(v).."\n")
end
end

devfs = {}
devfs.files = {}
devfs.fds = {}
devfs.nextfd = 0
devfs.component = {}

local function rfalse()
return false
end
local function rzero()
return 0
end
function devfs.component.getLabel()
return "devfs"
end
devfs.component.spaceUsed, devfs.component.spaceTotal, devfs.component.isReadOnly, devfs.component.isDirectory,devfs.component.size, devfs.component.setLabel = rzero, rzero, rfalse, rfalse, rzero, rfalse

function devfs.component.exists(fname)
return devfs.files[fname] ~= nil
end

function devfs.component.list()
local t = {}
for k,v in pairs(devfs.files) do
t[#t+1] = k
end
return t
end

function devfs.component.open(fname, mode)
fname=fname:gsub("/","")
if devfs.files[fname] then
local r,w,c,s = devfs.files[fname](mode)
devfs.fds[devfs.nextfd] = {["read"]=r or rfalse,["write"]=w or rfalse,["seek"]=s or rfalse,["close"]=c or rfalse}
devfs.nextfd = devfs.nextfd + 1
return devfs.nextfd - 1
end
return false
end

function devfs.component.read(fd,count)
if devfs.fds[fd] then
return devfs.fds[fd].read(count)
end
end
function devfs.component.write(fd,data)
if devfs.fds[fd] then
return devfs.fds[fd].write(data)
end
end
function devfs.component.close(fd)
if devfs.fds[fd] then
devfs.fds[fd].close()
end
devfs.fds[fd] = nil
end
function devfs.component.seek(fd,...)
if devfs.fds[fd] then
return devfs.fds[fd].seek(...)
end
end
function devfs.component.remove(fname)
end

function devfs.register(fname,fopen) -- Register a new devfs node with the name *fname* that will run the function *fopen* when opened. This function should return a function for read, a function for write, function for close, and optionally, a function for seek, in that order.
devfs.files[fname] = fopen
end

fs.makeDirectory("/dev")
fs.mount("/dev",devfs.component)


devfs.register("null",function()
return function() end, function() end, function() end
end)

devfs.register("syslog",function()
return function() end, syslog, function() end end)

do

function vt100emu(gpu) -- takes GPU component proxy *gpu* and returns a function to write to it in a manner like an ANSI terminal
local mx, my = gpu.maxResolution()
local cx, cy = 1, 1
local pc = " "
local lc = ""
local mode = "n"
local lw = true
local sx, sy = 1,1
local cs = ""

-- setup
gpu.setResolution(mx,my)
gpu.fill(1,1,mx,my," ")

function termwrite(s)
s=s:gsub("\8","\27[D")
pc = gpu.get(cx,cy)
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0)
gpu.set(cx,cy,pc)
for i = 1, s:len() do
local cc = s:sub(i,i)

if mode == "n" then
if cc == "\n" then -- line feed
cx, cy = 1, cy+1
elseif cc == "\r" then -- cursor home
cx = 1
elseif cc == "\27" then -- escape
mode = "e"
elseif string.byte(cc) > 31 and string.byte(cc) < 127 then -- printable, I guess
gpu.set(cx, cy, cc)
cx = cx + 1
end

elseif mode == "e" then
if cc == "[" then
mode = "v"
cs = ""
elseif cc == "D" then -- scroll down
gpu.copy(1,2,mx,my-1,0,-1)
gpu.fill(1,my,mx,1," ")
cy=cy+1
mode = "n"
elseif cc == "M" then -- scroll up
gpu.copy(1,1,mx,my-1,0,1)
gpu.fill(1,1,mx,1," ")
mode = "n"
end

elseif mode == "v" then
if cc == "s" then -- save cursor
sx, sy = cx, cy
mode = "n"
elseif cc == "u" then -- restore cursor
cx, cy = sx, sy
mode = "n"
elseif cc == "H" then -- cursor home or to
local tx, ty = cs:match("(.-);(.-)")
tx, ty = tx or "1", ty or "1"
cx, cy = tonumber(tx), tonumber(ty)
mode = "n"
elseif cc == "A" then -- cursor up
cy = cy - (tonumber(cs) or 1)
mode = "n"
elseif cc == "B" then -- cursor down
cy = cy + (tonumber(cs) or 1)
mode = "n"
elseif cc == "C" then -- cursor right
cx = cx + (tonumber(cs) or 1)
mode = "n"
elseif cc == "D" then -- cursor left
cx = cx - (tonumber(cs) or 1)
mode = "n"
elseif cc == "h" and lc == "7" then -- enable line wrap
lw = true
elseif cc == "l" and lc == "7" then -- disable line wrap
lw = false
end
cs = cs .. cc
end

if cx > mx and lw then
cx, cy = 1, cy+1
end
if cy > my then
gpu.copy(1,2,mx,my-1,0,-1)
gpu.fill(1,my,mx,1," ")
cy=my
end
if cy < 1 then cy = 1 end
if cx < 1 then cx = 1 end

lc = cc
end
pc = gpu.get(cx,cy)
gpu.setForeground(0)
gpu.setBackground(0xFFFFFF)
gpu.set(cx,cy,pc)
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0)
end

return termwrite
end
function vtemu(gpua,scra) -- creates a process to handle the GPU and screen address combination *gpua*/*scra*. Returns read, write and "close" functions.
local gpu = component.proxy(gpua)
gpu.bind(scra)
local write = vt100emu(gpu)
local kba = {}
for k,v in ipairs(component.invoke(scra,"getKeyboards")) do
kba[v]=true
end
local buf = ""
os.spawn(function() dprint(pcall(function()
while true do
local ty,ka,ch = coroutine.yield()
if ty == "key_down" and kba[ka] then
if ch == 13 then ch = 10 end
if ch == 8 then
if buf:len() > 0 then
write("\8 \8")
buf = buf:sub(1,-2)
end
elseif ch > 0 then
write(string.char(ch))
buf=buf..string.char(ch)
end
end
end
end)) end,string.format("ttyd[%s:%s]",gpua:sub(1,8),scra:sub(1,8)))
local function bread()
while not buf:find("\n") do
coroutine.yield()
end
local n = buf:find("\n")
r, buf = buf:sub(1,n-1), buf:sub(n+1)
return r
end
return bread, write, function() io.write("\27[2J\27[H") end
end
end

function loadfile(p) -- reads file *p* and returns a function if possible
local f = fs.open(p,"rb")
local c = f:read("*a")
f:close()
return load(c,p,"t")
end
function runfile(p,...) -- runs file *p* with arbitrary arguments in the current thread
return loadfile(p)(...)
end
function os.spawnfile(p,n,...) -- spawns a new process from file *p* with name *n*, with arguments following *n*.
local tA = {...}
return os.spawn(function() computer.pushSignal("process_finished", os.pid(), pcall(loadfile(p), table.unpack(tA))) end,n or p)
end
_G.libs = {computer=computer,component=component}
function require(f) -- searches for a library with name *f* and returns what the library returns, if possible
if not _G.libs[f] then
local lib = os.getenv("LIB") or "/boot/lib"
for d in lib:gmatch("[^\n]+") do
if fs.exists(d.."/"..f) then
_G.libs[f] = runfile(d.."/"..f)
elseif fs.exists(d.."/"..f..".lua") then
_G.libs[f] = runfile(d.."/"..f..".lua")
end
end
end
if _G.libs[f] then
return _G.libs[f]
end
error("library not found: "..f)
end
os.spawnfile("/boot/exec/init.lua")

os.sched()
