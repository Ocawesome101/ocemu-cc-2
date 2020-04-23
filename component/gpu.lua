-- gpu --

local expect = require("cc.expect").expect
--local component = require("component")
local color = require("oc_colors").ocolor
local getco = require("oc_colors").ccolor
local gpu = {}

local w, h = term.getSize()
local bound
local buffer = window.create(term.native(), 1, 1, w, h, true)

buffer.setTextColor(colors.white)
buffer.setBackgroundColor(colors.black)

function gpu.bind(screen)
  expect(1, screen, "string")
  --[[if require("component").type(screen) == "screen" then
    bound = screen
  end
  error("component is not a screen")]]
end

function gpu.set(x, y, s, v)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, s, "string")
  expect(4, v, "boolean", "nil")
  if v then
    local i = y
    for c in s:gmatch(".") do
      buffer.setCursorPos(x, y + i)
      buffer.write(c)
      i = i + 1
    end
  else
    local i = 0
    for c in s:gmatch(".") do
      buffer.setCursorPos(x + i, y)
      buffer.write(c)
      i = i + 1
    end
  end
end

function gpu.get(x, y)
  expect(1, x, "number")
  expect(2, y, "number")
  local line, bg, fg = buffer.getLine(y)
  return line:sub(x, x), color(fg:sub(x, x)), color(bg:sub(x, x))
end

function gpu.getScreen()
  return bound
end

function gpu.getBackground()
  return color(buffer.getBackgroundColor())
end

function gpu.getForeground()
  return color(buffer.getTextColor())
end

function gpu.setForeground(c)
  expect(1, c, "number")
  return buffer.setTextColor((c > 0 and colors.white) or colors.black)--getco(c))
end

function gpu.setBackground(c)
  expect(1, c, "number")
  return buffer.setBackgroundColor((c > 0 and colors.white) or colors.black)--getco(c))
end

function gpu.getDepth()
  return 1
end

function gpu.setDepth()
  error("you have asked for the impossible")
end

function gpu.maxDepth()
  return 4
end

function gpu.maxResolution()
  return w, h
end

function gpu.setResolution()
  return nil
end

function gpu.getResolution()
  return w, h
end

function gpu.copy(x, y, w, h, tx, ty)
  if ty < 0 then
    buffer.scroll(0 - ty)
  end
end

function gpu.fill(x, y, w, h, c)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, w, "number")
  expect(4, h, "number")
  expect(5, c, "string")
  c = c:sub(1,1)
  for _x=x, x+w, 1 do
    for _y=y, y+h, 1 do
      gpu.set(_x, _y, c)
    end
  end
end

return gpu
