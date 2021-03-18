-- OpenComputers emulator! --

local computer = require("apis.computer")
local component = require("apis.component")
--debug.debug()

local function tcopy(t)
  local r = {}
  for k, v in pairs(t) do
    r[k] = v
  end
  return r
end

local sandbox = {}
sandbox = {
  _VERSION = "Lua 5.2",
  checkArg = require("cc.expect").expect,
  assert = assert,
  type = type,
  pcall = pcall,
  xpcall = xpcall,
  rawget = rawget,
  rawset = rawset,
  rawequal = rawequal,
  error = error,
  tostring = tostring,
  tonumber = tonumber,
  setmetatable = setmetatable,
  getmetatable = getmetatable,
  select = select,
  next = next,
  pairs = pairs,
  ipairs = ipairs,
  component = component,
  computer = computer,
  debug = {
    traceback = debug.traceback,
    getupvalue = debug.getupvalue,
    getlocal = debug.getlocal,
    getinfo  = debug.getinfo
  },
  os = {
    clock = function()return os.epoch("utc")end,
    date = os.date,
    difftime = function(t1, t2)return t2 - t1 end,
    time = os.time
  },
  math = tcopy(math),
  bit32 = tcopy(bit32),
  string = tcopy(string),
  table = tcopy(table),
  coroutine = tcopy(coroutine),
  unicode = {
    char = function(n)return string.char((n < 255 and n) or 255)end,
    charWidth = function()return 1 end,
    isWide = function()return false end,
    len = string.len,
    lower = string.lower,
    reverse = string.reverse,
    sub = string.sub,
    upper = string.upper,
    wlen = string.len,
    wtrunc = string.sub
  }
}

local string_format = string.format
function sandbox.string.format(fmt, ...)
  local args = {...}
  for i=1, #args, 1 do
    if type(args[i]) == "table" then
      args[i] = table.concat(args[i], " ")
    end
  end
  return string_format(fmt, table.unpack(args))
end

sandbox._G = sandbox
sandbox._ENV = sandbox
sandbox.load = function(str, name, mode, env)
  local f, e = load(str, name, mode or "bt", env or sandbox)
  if setfenv and f then
    setfenv(f, sandbox)
  end
  return f, e
end

local bios, err = loadfile("/emu/bios.lua", "bt", sandbox)
if not bios then
  error("Failed loading /emu/bios.lua: " .. err)
end
if setfenv then
  setfenv(bios, sandbox)
end

local s, r = xpcall(bios, debug.traceback)
if not s and r then
  error(r)
end
