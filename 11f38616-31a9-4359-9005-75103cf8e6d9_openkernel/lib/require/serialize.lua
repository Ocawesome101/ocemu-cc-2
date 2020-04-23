-- A simple table serializing function. Usable with require("serialize") --

local function serialize(tbl)
  local tbl = tbl
  local str = "{"
  for k,v in pairs(tbl) do
    local k = k
    if type(v) == "string" then
      str = str .. "\n  " .. tostring(k) .. " = \"" .. v .. "\""
    end
    if type(v) == "function" then
      str = str .. "\n  " .. tostring(k) .. " = <function>"
    end
    if type(v) == "table" then
      str = str .. "\n  " .. tostring(k) .. " = " .. (serialize(v) or "<table>")
    end
    if type(v) == "number" then
      str = str .. "\n  " .. tostring(k) .. " = " .. tostring(v)
    end
    str = str .. ","
  end
  str = str .. "\n}"
  return str
end

return serialize
