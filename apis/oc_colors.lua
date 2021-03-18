-- Mappings of OpenComputers <-> ComputerCraft colors --

local blit = {
  ["f"] = 0xF0F0F0,
  ["e"] = 0xF2B233,
  ["d"] = 0xE57FD8,
  ["c"] = 0x99B2F2,
  ["b"] = 0xDEDE6C,
  ["a"] = 0x7FCC19,
  ["9"] = 0xF2B2CC,
  ["8"] = 0x4C4C4C,
  ["7"] = 0x999999,
  ["6"] = 0x4C99B2,
  ["5"] = 0xB266E5,
  ["4"] = 0x3366CC,
  ["3"] = 0x7F664C,
  ["2"] = 0x57A64E,
  ["1"] = 0xCC4C4C,
  ["0"] = 0x111111
}

local pal  = {
  [0x1]    = "f",
  [0x2]    = "e",
  [0x4]    = "d",
  [0x8]    = "c",
  [0x10]   = "b",
  [0x20]   = "a",
  [0x40]   = "9",
  [0x80]   = "8",
  [0x100]  = "7",
  [0x200]  = "6",
  [0x400]  = "5",
  [0x800]  = "4",
  [0x1000] = "3",
  [0x2000] = "2",
  [0x4000] = "1",
  [0x8000] = "0"
}

local term = {
  f     = 0x1,
  e     = 0x2,
  d     = 0x4,
  c     = 0x8,
  b     = 0x10,
  a     = 0x20,
  ["9"] = 0x40,
  ["8"] = 0x80,
  ["7"] = 0x100,
  ["6"] = 0x200,
  ["5"] = 0x400,
  ["4"] = 0x800,
  ["3"] = 0x1000,
  ["2"] = 0x2000,
  ["1"] = 0x4000,
  ["0"] = 0x8000
}

local c = {}
function c.ocolor(ch)
  if type(ch) == "string" then
    return blit[ch]
  else
    return blit[pal[ch]]
  end
end

-- fairly basic color-conversion system
function c.ccolor(co)
  local r, g, b = colors.unpackRGB(co)
  r, g, b = 255 * r, 255 * g, 255 * b
  if r > 0x30 or g >= 0x30 or b >= 0x30 then
    return term.f
  else
    return term["0"]
  end
end

return c
