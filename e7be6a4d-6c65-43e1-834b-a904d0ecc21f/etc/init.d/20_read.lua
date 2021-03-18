-- Do you read me? --

local cursor = " "

local acceptedChars = {}
for i=32, 126, 1 do
  acceptedChars[string.char(i)] = true
end

-- @arg @replace: Character with which to replace every character in the entered string.
-- @arg @history: Table of history
function read(replace, history)
  local str = ""
  local cursorPos = #str
  local history = history
  if not history then
    history = {""}
  else
    table.insert(history, "")
  end
  local histPos = #history
  local x,y = term.getCursorPos()
  local w,h = term.getSize()
  local function redraw(c)
    term.setCursorPos(x,y)
    term.write((" "):rep(w - x))
    term.setCursorPos(x,y)
    if replace then
      term.write(replace:rep(#str))
    else
      term.write(str)
    end
    -- Simulate a cursor since I can't get the term API to do it
    if c ~= "" then
      term.setCursorPos(x + cursorPos, y)
      local oldColor = term.getBackgroundColor()
      local oldTextColor = term.getTextColor()
      term.setBackgroundColor(oldTextColor)
      term.setTextColor(colors.black)
      local char = gpu.get(x + cursorPos, y)
      term.write(char)
      term.setBackgroundColor(oldColor)
      term.setTextColor(oldTextColor)
    end
  end
  while true do
    redraw(cursor)
    local event, _, id, altid = event.pull()
    if event == "key_down" then
      if id == 8 then -- Backspace
        if cursorPos > 0 then
          str = str:sub(1,cursorPos - 1) .. str:sub(cursorPos+1, #str)
        end
        if cursorPos >= 1 then
          cursorPos = cursorPos - 1
        end
      elseif id == 127 then -- Delete
        if cursorPos < #str then
          str = str:sub(1, cursorPos) .. str:sub(cursorPos+2, #str)
        end
      elseif id == 13 then -- Enter
        redraw("") -- No cursor
        term.setCursorPos(1,y+1)
        table.remove(history, #history)
        return str
      elseif id == 0 then
        if altid == 208 then -- Down arrow
          if histPos < #history then
            histPos = histPos + 1
            str = history[histPos]
            cursorPos = #str
          end
        elseif altid == 200 then -- Up arrow
          if histPos > 1 then
            histPos = histPos - 1
            str = history[histPos]
            cursorPos = #str
          end
        elseif altid == 203 then
          if cursorPos > 0 then
            cursorPos = cursorPos - 1
          end
        elseif altid == 205 then
          if cursorPos < #str then
            cursorPos = cursorPos + 1
          end
        end
      else
        local c = string.char(id)
        for k,v in pairs(acceptedChars) do
          if k == c then
            term.write(replace or c)
            str = str:sub(1, cursorPos) .. c .. str:sub(cursorPos+1, #str)
            cursorPos = cursorPos + 1
            break
          end
        end
      end
    elseif event == "clipboard" then
      str = str .. id
      cursorPos = #str
    end
  end
end
