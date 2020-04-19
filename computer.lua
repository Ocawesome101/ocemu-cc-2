local expect = require("cc.expect")
local component = require("component")

local keymap = {
  apostrophe = "'",
  comma = ",",
  hyphen = "-",
  underscore = "_",
  colon = ":",
  semicolon = ";"
}

local function parse(evt)
  local id = evt[1]
  local r = {}
  if id == "key" then
    r[1] = "key_down"
    r[2] = component.list("keyboard")()
    local k = keys.getName(e[2])
    if keymap[k] then
      k = keymap[k]
    end
    r[3] = k:byte()
    r[4] = e[2]
  elseif id == "key_up" then 
    r[1] = id
    r[2] = component.list("keyboard")()
    local k = keys.getName(e[2])
    if keymap[k] then
      k = keymap[k]
    end
    r[3] = k:byte()
    r[4] = e[2]
  else
    r = e
  end
  return table.unpack(r)
end

local c = {}

function c.pullSignal(t)
  expect(1, t, "number", "nil")
  local id
  if timer then
   id = os.startTimer(t)
  end
  repeat
    local e = {os.pullEvent()}
    if e[1] == "timer" and e[2] == id then
      return nil
    end
  until #e > 0
  return parse(e)
end

function c.pushSignal(...)
  return os.queuEvent(...)
end

function c.beep()
  return true
end

function c.getDeviceInfo()
  error("getDeviceInfo not implemented")
end

function c.shutdown(r)
  expect(1, r, "", "")
  if r then
    os.reboot()
  else
    os.shutdown()
  end
end

return c
