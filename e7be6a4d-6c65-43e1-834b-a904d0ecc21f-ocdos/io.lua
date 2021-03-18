-- Basic I/O facilities --

if cmd then
  error("System is already initialized")
end

local cproxy = component.proxy

-- Improve the table API --
function table.copy(tbl)
  checkArg(1, tbl, "table")
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end
  return rtn
end

function table.new(...)
  local rtn = {...} or {}
  setmetatable(rtn, {__index = table})
  return rtn
end

-- string.tokenize --
function string.tokenize(str, sep)
  checkArg(1, str, "string")
  checkArg(2, sep, "string")
  local sep = sep or " "
  local words = table.new()
  local word = ""
  for c in str:gmatch(".") do
    if c == sep then
      if word ~= "" then
        words:insert(word)
        word = ""
      end
    else
      word = word .. c
    end
  end
  if word ~= "" then -- We might have a trailing word
    words:insert(word)
  end
  return words
end

-- Set up a GPU proxy and management API --
_G.gpu = cproxy(component.list("gpu")())
local screen = component.list("screen")()
if screen then
  gpu.bind(screen)
end

gpu.setResolution(gpu.maxResolution())

_G.term = {}

local x,y = 1,1
local w,h = gpu.getResolution()

gpu.fill(1,1,w,h," ") -- Clear the screen

function term.getCursorPos()
  return x,y
end

function term.setCursorPos(nX, nY)
  checkArg(1, nX, "number")
  checkArg(2, nY, "number")
  if nX <= w and nY <= h then
    x,y = nX,nY
  end
end

function term.getSize()
  return w,h
end

function term.write(text)
  checkArg(1, text, "string")
  gpu.set(x,y,text)
  x = x + #text
end

function term.clear()
  gpu.fill(1,1,w,h," ")
end

function term.scroll(amount)
  checkArg(1, amount, "number")
  local amount = amount or 1
  gpu.copy(1,1+amount,w,h-amount,0,-1)
  gpu.fill(1,h - (amount - 1),w,1," ")
end

function term.clearLine()
  gpu.set(1,y,(" "):rep(w))
end

gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)

-- write() --
function write(text)
  checkArg(1, text, "string")
  local x,y = term.getCursorPos()
  local w,h = term.getSize()
  local function newline()
    if y == h then
      term.scroll(1)
      term.setCursorPos(1,y)
    else
      term.setCursorPos(1,y+1)
    end
  end
  for char in text:gmatch(".") do
    x,y = term.getCursorPos()
    if char ~= "\n" then
      if x >= w then
        newline()
      end
      term.write(char)
    else
      newline()
    end
  end
end

function _G.print(...)
  local p = {...}
  for i=1, #p, 1 do
    write(tostring(p[i]))
    if i < #p then
      write(" ")
    end
  end
  write("\n")
end

print("Starting OC-DOS....")
-----------------------------------------------------------------------------------------------------

-- Set up filesystems --
local filesystems = {}

local drive_letters = {
  "A:",
  "B:",
  "C:",
  "D:",
  "E:",
  "F:",
  "G:",
  "H:",
  "I:",
  "J:",
  "K:",
  "L:",
  "M:",
  "N:",
  "O:",
  "P:",
  "Q:",
  "R:",
  "S:",
  "U:",
  "V:",
  "W:",
  "X:",
  "Y:",
  "Z:"
}

local current_drive = "A:"

local root_drive = ""
if computer.getBootAddress then
  root_drive = computer.getBootAddress()
else
  root_drive = component.list("filesystem")()
end

filesystems["A:"] = component.proxy(root_drive)

local function resolve_fs(path) -- Get the proper filesystem proxy for a path
  local drive = path:sub(1,2)
  if drive:sub(2,2) ~= ":" then
    drive = current_drive
  end
  if filesystems[drive] then
    return filesystems[drive]
  else
    return nil, "No such drive"
  end
end

local function ch_drive(drive)
  if filesystems[drive] ~= nil then
    current_drive = drive
  else
    return false, "No such drive"
  end
end

local function add_drive(drive_proxy)
  for _,v in pairs(filesystems) do
    if v.address == drive_proxy.address then -- The drive is already mounted
      return true
    end
  end
  for i=1, #drive_letters, 1 do
    if not filesystems[drive_letters[i]] then
      filesystems[drive_letters[i]] = drive_proxy
      return true
    end
  end
  return false, "Too many drives mounted" -- I don't know HOW you'd get 26 drives attached to a computer
end

local function rm_drive(drive)
  if filesystems[drive] then
    filesystems[drive] = nil
  else
    return false, "No such drive"
  end
end

local function path(_path, _mode, _drive)
  local _path = _path
  local _mode = _mode or "remove"
  local _drive = _drive or current_drive
  if _mode == "add" then
    if _path:sub(2,2) ~= ":" then
      if _path:sub(1,1) == "/" then
        _path = _drive .. _path
      else
        _path = _drive .. "/" .. _path
      end
    end
  elseif _mode == "remove" then
    if _path:sub(2,2) ~= ":" then
      _path = _path
    else
      _drive = _path:sub(1,2) -- Return the drive we removed
      _path = _path:sub(3)
    end
  end
  return _path, _drive
end

local function drive_exec(drive, operation, ...) -- Simplify my life
  local drive = drive or current_drive
  if filesystems[drive] and filesystems[drive][operation] then
    return filesystems[drive][operation](...)
  else
    return nil, "No such drive"
  end
end

for a, c in component.list("filesystem") do
  if component.invoke(a, "getLabel") == "tmpfs" then
    filesystems["T:"] = cproxy(a)
    break
  end
end

-----------------------------------------------------------------------------------------------------

-- Some kind of FS library
_G.fs = {}

function fs.chDrive(drive)
  checkArg(1, drive, "string")
  return ch_drive(drive)
end

function fs.getDrive()
  return current_drive
end

function fs.drives() -- All mounted drives
  local rtn = {}
  for k,_ in pairs(filesystems) do
    rtn[k] = k
  end
  return rtn
end

function fs.concat(...) -- Concatenate file paths, with the proper number of slashes
  return table.concat(table.pack(...), "/"):gsub("[/\\]+", "/")
end

function fs.list(dir)
  checkArg(1, dir, "string")
  local path, drive = path(dir, "remove")
  return drive_exec(drive, "list", path)
end

function fs.remove(file)
  checkArg(1, file, "string")
  local file, drive = path(file, "remove")
  return drive_exec(drive, "remove", file)
end

function fs.exists(file)
  checkArg(1, file, "string")
  local file, drive = path(file, "remove")
  return drive_exec(drive, "exists", file)
end

function fs.open(file, mode)
  checkArg(1, file, "string")
  checkArg(1, file, "string", "nil")
  local file, drive = path(file, "remove")
  local mode = mode or "r"
  if not fs.exists(fs.concat(drive, file)) and mode == "r" then
    return nil, fs.concat(drive, file) .. ": File not found"
  end
  local handle, status = drive_exec(drive, "open", file, mode)
  if not handle then
    return nil, status
  end
  local file = {}
  if mode == "r" or mode == "rw" or mode == "a" then
    function file:read(amount)
      return drive_exec(drive, "read", handle, amount)
    end
  end
  if mode == "w" or mode == "rw" or mode == "a" then
    function file:write(data)
      return drive_exec(drive, "write", handle, data)
    end
  end
  function file:close()
    return drive_exec(drive, "close", handle)
  end
  return file
end

function fs.isDirectory(file)
  checkArg(1, file, "string")
  local file, drive = path(file, "remove")
  if not fs.exists(fs.concat(drive, file)) then
    return false, "File not found"
  end
  return drive_exec(drive, "isDirectory", file)
end

function fs.makeDirectory(file)
  checkArg(1, file, "string")
  local file, drive = path(file, "remove")
  if fs.exists(file) then
    return false, "File already exists"
  end
  return drive_exec(drive, "makeDirectory", file)
end

function fs.copy(src, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local source, drive = path(source, "remove")
  local dest, ddrive = path(dest, "remove")
  if not fs.exists(fs.concat(drive, source)) then
    return false, "File not found"
  end
  local in_handle = fs.open(fs.concat(drive, source))
  local out_handle = fs.open(fs.concat(ddrive, dest))
  local in_buffer = ""
  repeat
    local data = in_handle:read()
    in_buffer = in_buffer .. (data or "")
  until not data
  in_handle:close()
  out_handle:write(in_buffer)
  out_handle:close()
end

function fs.xcopy(src, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local source, drive = path(source, "remove")
  local dest, ddrive = path(dest, "remove")
  if fs.isDirectory(fs.concat(drive, source)) then
    fs.makeDirectory()
  else
    fs.copy(fs.concat(drive, source), fs.concat(ddrive, dest))
  end
end

function fs.move(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local source, drive = path(source, "remove")
  local dest, ddrive = path(dest, "remove")
  fs.copy(fs.concat(drive, source), fs.concat(ddrive, dest))
  fs.remove(fs.concat(drive, source))
end

function fs.getLabel(drive)
  checkArg(1, drive, "string")
  return drive_exec(drive, "getLabel")
end

function fs.setLabel(drive, label)
  checkArg(1, drive, "string")
  checkArg(2, label, "string")
  return drive_exec(drive, "setLabel", label)
end

function fs.lastModified(file)
  checkArg(1, file, "string")
  local file, drive = path(file, "remove")
  return drive_exec(drive, "lastModified", file)
end

function fs.getAddress(drive)
  checkArg(1, drive, "string")
  if filesystems[drive] then
    return filesystems[drive].address
  end
end
-----------------------------------------------------------------------------------------------------

-- Signal processing --
local pop = computer.pullSignal
local psh = computer.pushSignal
computer.pullSignal = nil -- We can't have people using this
computer.pushSignal = nil -- Or this

local computer = table.copy(computer)

_G.dos = {}

local listeners = {
  ["component_added"] = function(addr, ctype)
    if ctype == "filesystem" then
      add_drive(cproxy(addr))
    end
  end,
  ["component_removed"] = function(addr, ctype)
    if ctype == "filesystem" then
      local drive = ""
      for k,v in pairs(filesystems) do
        if v.address == addr then
          drive = k
        end
      end
      rm_drive(drive)
    end
  end
}

setmetatable(dos, { __index = computer }) -- :P

function dos.pull(filter, timeout)
  checkArg(1, filter, "string", "nil")
  checkArg(2, timeout, "number", "nil")
  local data = {}
  if timeout then
    data = {pop()}
    if listeners[data[1]] then
      pcall(function()listeners[data[1]](table.unpack(data, 2, data.n))end)
    end
    if data[1] == filter or not filter then
      return table.unpack(data)
    end
  end
  while true do
    data = {pop()}
    if listeners[data[1]] then
      pcall(function()listeners[data[1]](table.unpack(data, 2, data.n))end)
    end
    if data[1] == filter or not filter then
      return table.unpack(data)
    end
  end
end

function dos.push(event, ...)
  checkArg(1, event, "string")
  psh(event, ...)
end

function dos.add_event_listener(event, listener)
  checkArg(1, event, "string")
  checkArg(2, listener, "function")
  if listeners[event] then
    return false, "Cannot overwrite event listeners"
  else
    listeners[event] = listener
  end
end

function dos.remove_event_listener(event)
  checkArg(1, event, "string")
  if listeners[event] then
    listeners[event] = nil
  else
    return false, "No event listener in place"
  end
end

function term.update()
  dos.pull(nil, 0)
end
-----------------------------------------------------------------------------------------------------

-- read and sleep functions, now that event handling is done --
function _G.read()
  local str = ""
  local w,h = term.getSize()
  local x,y = term.getCursorPos()
  local function redraw(c)
    term.setCursorPos(x,y)
    write(str)
    if c then
      write("_ ")
    else
      write(" ")
    end
  end
  redraw(true)
  while true do
    local e, _, id, altid = dos.pull()
    if e == "key_down" then
      if id == 8 then -- Backspace
        str = str:sub(1,-2)
      elseif id == 13 then -- Enter
        redraw(false)
        write("\n")
        return str
      elseif id == 0 then
        if altid == 200 then
          str = str .. "^A"
        elseif altid == 208 then
          str = str .. "^B"
        elseif altid == 205 then
          str = str .. "^C"
        elseif altid == 203 then
          str = str .. "^D"
        end
      else
        if id >= 32 and id <= 127 then -- Printable chars
          str = str .. string.char(id)
        end
      end
      redraw(true)
    end
  end
end

function _G.sleep(time)
  checkArg(1, time, "number")
  local dest = dos.uptime() + time
  repeat
    local data = dos.pull(nil, time)
  until dos.uptime() >= dest
end

os.sleep = _G.sleep

-----------------------------------------------------------------------------------------------------

-- Finally, load ocdos.lua and proceed to stage 2 --
function loadfile(filename, mode, env)
  checkArg(1, filename, "string")
  checkArg(2, mode, "string", "table", "nil")
  checkArg(3, env, "table", "nil")
  local mode = mode or "bt"
  local env = env
  if env == nil and type(mode) == "table" then
    env, mode = mode, "bt"
  end
  if not fs.exists(filename) then
    return false, "file not found"
  end
  local handle, reason = fs.open(filename)
  if not handle then
    return false, reason
  end
  local buffer = ""
  repeat
    local data = handle:read(0xFFFF)
    buffer = buffer .. (data or "")
  until not data
  handle:close()
  return load(buffer, "=" .. filename, "bt", env)
end

local ok, err = loadfile("A:/ocdos.lua")
if not ok then
  error(err)
end
ok()
-----------------------------------------------------------------------------------------------------
