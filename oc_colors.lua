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

local gpu = {
  ["0"] = 0x8000,
  ["8"] = 0x100,
  ["f"] = 0x1
}

local function round(val)
  if val > 0x111111 then
    return "f"
  elseif val == 0x111111 then
    return "8"
  else
    return "0"
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

-- fairly advanced color-conversion system that doesn't work
function c.ccolor(co)
--[[  local r, g, b = colors.unpackRGB(co)
  r, g, b = 255 * r, 255 * g, 255 * b]]
  local diff = {
    --[[r = {},
    g = {},
    b = {}]]
  }
  local col = {}
  for character, color in pairs(blit) do
    --[[local cr, cg, cb = colors.unpackRGB(co)
    cr, cg, cb = 255 * cr, 255 * cg, 255 * cb
    local dr, dg, db = r / cr, g / cg, b / cb]]
    diff[#diff + 1] = {diff = color - co, color = color}
    col[#diff] = color - co
  end
  local min = math.min(table.unpack(col))
  for k, v in pairs(diff) do
    if v.diff == min then
      for b, c in pairs(blit) do
        if c == v.color then
          for p, _b in pairs(pal) do
            if _b == b then
              return p
            end
          end
        end
      end
    end
  end
end

return c
