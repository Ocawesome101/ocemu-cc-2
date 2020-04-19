-- component lib --

local component = {}

local expect = require("cc.expect").expect

local default, err = settings.get("oc.components") or load("return " .. fs.open("/oc/components", "r").readAll(), "=components")()
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
  local addr = c[2] or randomAddress()
  local prox = require("component." .. ctyp)
  prox.address = addr
  prox.type = ctyp
  components[addr] = {type = ctyp, proxy = prox}
end

local function checkAddress(address)
  expect(1, address, "string")
  if not components[address] then
    error("no such component")
  else
    return component[address]
  end
end

function component.invoke(address, field, ...)
  expect(1, address, "string")
  expect(2, field, "string")
  local comp = checkAddress(address)
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
  return setmetatable(matches, {__call = function()
    return next(matches) 
  end})
end

function component.proxy(address)
  expect(1, address, "string")
  return checkAddress(address).proxy
end

return component
