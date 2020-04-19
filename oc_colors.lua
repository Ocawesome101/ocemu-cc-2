-- Mappings of OpenComputers <-> ComputerCraft colors --

local blit = {
  ["0"] = 0xF0F0F0,
  ["1"] = 0xF2B233,
  ["2"] = 0xE57FD8,
  ["3"] = 0x99B2F2,
  ["4"] = 0xDEDE6C,
  ["5"] = 0x7FCC19,
  ["6"] = 0xF2B2CC,
  ["7"] = 0x4C4C4C,
  ["8"] = 0x999999,
  ["9"] = 0x4C99B2,
  a     = 0xB266E5,
  b     = 0x3366CC,
  c     = 0x7F664C,
  d     = 0x57A64E,
  e     = 0xCC4C4C,
  f     = 0x111111
}

local pal  = {
  [0x1]    = "0",
  [0x2]    = "1",
  [0x4]    = "2",
  [0x8]    = "3",
  [0x10]   = "4",
  [0x20]   = "5",
  [0x40]   = "6",
  [0x80]   = "7",
  [0x100]  = "8",
  [0x200]  = "9",
  [0x400]  = "a",
  [0x800]  = "b",
  [0x1000] = "c",
  [0x2000] = "d",
  [0x4000] = "e",
  [0x8000] = "f"
}

local gpu = {
  ["0"] = 0x8000,
  ["8"] = 0x100,
  ["f"] = 0x1
}

local function round(val)
  if val > 0x888888 then
    return "0"
  elseif val == 0x888888 then
    return "8"
  else
    return "f"
  end
end

local c = {}
function c.ocolor(ch)
  if type(ch) == "string" then
    return blit[ch]
  else
    return blit[pal[ch]]
  end
end

function c.ccolor(co)
  return gpu[round(co)]
end

return c
