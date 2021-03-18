-- screen --

local s = {}

local c = {}
local component = setmetatable(c, {__index = function(_, k)c = require("apis.component") setmetatable(c, {__index = {}}) return c[k] end})

function s.getKeyboards()
  return component.list("keyboard")
end

return s
