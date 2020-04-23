-- component lib --

local component = {}

local expect = require("cc.expect").expect

local default, err = settings.get("oc.components") or load("return " .. fs.open("/components", "r").readAll(), "=components")()
if not default then
  error(err)
end

--print(default, err)

local components = {}

local function randomAddress() -- Generate a component address
  local s = {4,2,2,2,6}
  local addr = ""
  local p = 0

  for _,_s in ipairs(s) do
    if #addr > 0 then
      addr = addr .. "-"
    end
    for _=1, _s, 1 do
      local b = math.random(0, 255)
      if p == 6 then
        b = bit32.bor(bit32.band(b, 0x0F), 0x40)
      elseif p == 8 then
        b = bit32.bor(bit32.band(b, 0x3F), 0x80)
      end
      addr = addr .. ("%02x"):format(b)
      p = p + 1
    end
  end
  return addr
end

for i=1, #default, 1 do
  local c = default[i]
  if not c then
    error(textutils.serialize(default))
  end
  local ctyp = c[1]
  c[2] = c[2] or randomAddress()
  local addr = c[2]
  local prox = require("component." .. ctyp)
  prox.address = addr
  prox.type = ctyp
--[[  if ctyp == "filesystem" then
    prox.setAddress(prox.address)
  end]]
  components[addr] = {type = ctyp, proxy = prox}
end

settings.set("oc.components", default)
settings.save(".settings")

local function checkAddress(address)
  expect(1, address, "string")
  if not components[address] then
    error("no such component: " .. address)
  else
    return components[address]
  end
end

function component.invoke(address, field, ...)
  expect(1, address, "string")
  expect(2, field, "string")
  local comp = checkAddress(address)
  if not comp then
    error(address .. ": no such component")
  end
  if not comp.proxy[field] then
    error("attempt to call/index field '" .. field .. "' (a nil value)")
  end
  return comp.proxy[field](...)
end

function component.type(address)
  expect(1, address, "string")
  return checkAddress(address).type
end

function component.list(ctype, exact)
  expect(1, ctype, "string", "nil")
  expect(2, exact, "boolean", "nil")
  local matches = {}
  for a, c in pairs(components) do
    if c.type == ctype or not ctype then
      matches[a] = c.type
    end
  end
  local sehctam = {}
  for a, t in pairs(matches) do
    sehctam[#sehctam + 1] = {a, t}
  end
  return setmetatable(matches, {__call = function()
    local e = table.remove(sehctam)
    if e then return e[1], e[2] end
  end})
end

function component.proxy(address)
  expect(1, address, "string")
  local prx = checkAddress(address)
  return setmetatable({address = address, type = prx.type}, {__index = prx.proxy})
end

return component
