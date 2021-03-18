local expect = require("cc.expect").expect
local c = {}
local component = setmetatable(c, {__index = function(_, k)c = require("apis/component") setmetatable(c, {__index = {}}) return c[k] end})

local keymap = {
  apostrophe = "'",
  comma = ",",
  period = ".",
  hyphen = "-",
  minus = "-",
  underscore = "_",
  colon = ":",
  semicolon = ";",
  semiColon = ";",
  enter = string.char(13),
  backspace = string.char(8),
  left = string.char(0),
  right = string.char(0),
  up = string.char(0),
  down = string.char(0),
  leftCtrl = string.char(0),
  rightCtrl = string.char(0),
  leftShift = string.char(0),
  rightShift = string.char(0),
  space = " ",
  capsLock = string.char(0),
  equals = "=",
  slash = "/",
  backslash = "\\"
}

local function get_char(c)
  local sig, ch
  repeat
    sig, ch = os.pullEvent()
  until sig == "char" or sig == "key_up"
  if sig == "char" then
    return ch
  end
  return keys.getName(c)
end

local function parse(evt)
  local id = evt[1]
  local r = {}
  if id == "key" then
    r[1] = "key_down"
    r[2] = component.list("keyboard")()
    local k = get_char(evt[2])
    if keymap[k] then
      k = keymap[k]
    end
    r[3] = k:byte()
    r[4] = evt[2]
  elseif id == "key_up" then
    r[1] = id
    r[2] = component.list("keyboard")()
    local k = get_char(evt[2])
    if keymap[k] then
      k = keymap[k]
    end
    r[3] = k:byte()
    r[4] = evt[2]
  else
    r = evt
  end
  return table.unpack(r)
end

local c = {}

c.address = ""

debug.setmetatable(c.address, {__call = function()return c.address end, __index = string})

function c.tmpAddress()
  return component.list("filesystem")()
end

function c.freeMemory()
  return math.huge
end

function c.totalMemory()
  return math.huge
end

function c.pullSignal(t)
  expect(1, t, "number", "nil")
  local id
  if t and t ~= math.huge then
   id = os.startTimer(t)
  end
  local e
  repeat
    e = {os.pullEvent()}
    if e[1] == "timer" and e[2] == id then
      return nil
    end
  until #e > 0
  return parse(e)
end

function c.pushSignal(evt, ...)
--  debug.debug("pushed signal " .. table.concat({evt, ...}, " "))
  return os.queueEvent(evt, ...)
end

function c.beep()
  return true
end

c.uptime = os.time

function c.getDeviceInfo()
  error("getDeviceInfo not implemented")
end

function c.shutdown(r)
  expect(1, r, "boolean", "nil")
  if r then
    os.reboot()
  else
    os.shutdown()
  end
end

return c
