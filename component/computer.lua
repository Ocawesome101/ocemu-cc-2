-- computer component --

local c = {}

c.address = ""
c.type = "computer"

return setmetatable(c, {__index = function(tbl, k)
  setmetatable(tbl, {__index = require("computer")})
end})
