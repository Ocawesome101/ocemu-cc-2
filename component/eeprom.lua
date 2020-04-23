-- eeprom --

local eeprom = {}

function eeprom.getData()
  local data = ""
  if fs.exists("/emu/data") then
    local h = fs.open("/emu/data", "r")
    data = h.readAll()
    h.close()
  end
  return data
end

function eeprom.setData(d)
  require("cc.expect").expect(1, d, "string", "nil")
  local d = d or ""
  local h = fs.open("/emu/data", "w")
  h.write(d:sub(1, 256))
  h.close()
end

return eeprom
