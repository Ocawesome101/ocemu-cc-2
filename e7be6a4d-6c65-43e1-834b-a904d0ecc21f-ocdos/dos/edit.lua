-- Maybe, finally, a working text editor...? --
-- Not terribly memory-friendly. --

local args = {...}

if #args < 1 then
  return error("Required parameter missing")
end

local file = fs.concat(fs.getDrive() .. cmd.pwd(), args[1])

local lines = table.new("")

if fs.exists(file) then -- Read the file, and split it into lines
  local handle = fs.open(file)
  local buffer = ""
  repeat
    local data = handle:read(0xFFFF)
    buffer = buffer .. (data or "")
  until not data
  handle:close()

  lines = string.tokenize(buffer, "\n")
end

local line = 1

local w,h = term.getSize()

h = h - 1

local bottomLine
if #lines < h then
  bottomLine = #lines
else
  bottomLine = h
end

term.clear()

-- Save the file to disk
local function saveFile()
  local out_handle = fs.open(file, "w")
  for i=1, #lines, 1 do
    if lines[i] then
      out_handle:write(lines[i] .. "\n")
    end
  end
  out_handle:close()
end

-- Custom read function with proper arrow support and some other bits and bobs
local function read()
  local cursorX = 0
  local cursorY = 2
  local function redraw()
    local y = 2
    for i=(bottomLine - h) + 1, bottomLine, 1 do
      gpu.set(1, y, (" "):rep(w))
      if lines[i] then
        gpu.set(1, y, lines[i]:sub(1, w))
        y = y + 1
      end
    end
    
    gpu.setBackground(0xFFFFFF)
    gpu.setForeground(0x000000)
    gpu.set(1, 1, (" "):rep(w))
    gpu.set(1, 1, file)

    gpu.set(1, h+1, (" "):rep(w))
    gpu.set(1, h+1, "<f3=exit> <f5=save> <f6=refresh>")
    gpu.set(w - #tostring(line) - 6 - #lines, h+1, "Line " .. tostring(line) .. "/" .. tostring(#lines))

    local char = gpu.get(cursorX+1, cursorY)
    gpu.set(cursorX + 1, cursorY, char)
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
  end
  while true do
    redraw()
    local event, _, id, altid = dos.pull()
    if event == "key_down" then
      if id == 8 then -- Backspace
        if cursorX > 0 then
          lines[line] = lines[line]:sub(0,cursorX - 1) .. lines[line]:sub(cursorX+1, #lines[line])
          if cursorX >= 1 then
            cursorX = cursorX - 1
          end
        else
          if line > 1 then
            line = line - 1
            if lines[line] == "" then
              lines:remove(line)
            end
            cursorX = ((#lines[line] < cursorX and #lines[line]) or cursorX)
            if cursorY > 2 then
              cursorY = cursorY - 1
            elseif bottomLine > h then
              bottomLine = bottomLine - 1
            end
          end
        end
      elseif id == 127 then -- Delete
        if cursorX < #lines[line] then
          lines[line] = lines[line]:sub(1, cursorX) .. lines[line]:sub(cursorX+2, #lines[line])
        end
      elseif id == 13 then -- Enter
        if line == #lines then
          lines:insert("")
          cursorX = 0
          redraw()
          line = #lines
          if cursorY < h then
            cursorY = cursorY + 1
          elseif bottomLine < #lines then
            bottomLine = bottomLine + 1
          end
        end
      elseif id == 0 then
        if altid == 208 then -- Down arrow
          if line < #lines then
            line = line + 1
            cursorX = ((#lines[line] < cursorX and #lines[line]) or cursorX)
            if cursorY < h and cursorY < #lines+1 then
              cursorY = cursorY + 1
            elseif bottomLine < #lines then
              bottomLine = bottomLine + 1
            end
          end
        elseif altid == 200 then -- Up arrow
          if line > 1 then
            line = line - 1
            cursorX = ((#lines[line] < cursorX and #lines[line]) or cursorX)
            if cursorY > 2 then
              cursorY = cursorY - 1
            elseif bottomLine > h then
              bottomLine = bottomLine - 1
            end
          end
        elseif altid == 203 then -- Left arrow
          if cursorX >= 1 then
            cursorX = cursorX - 1
          end
        elseif altid == 205 then -- Right arrow
          if cursorX < #lines[line] then
            cursorX = cursorX + 1
          end
        elseif altid == 63 then -- f5
          saveFile()
        elseif altid == 61 then -- f3
          term.clear()
          term.setCursorPos(1,1)
          break
        elseif altid == 64 then -- f6
          redraw()
        end
      else
        if id >= 32 and id <= 127 then
          lines[line] = lines[line]:sub(1, cursorX) .. string.char(id) .. lines[line]:sub(cursorX+1, w)
          cursorX = cursorX + 1
        end
      end
    end
  end
end

read()
