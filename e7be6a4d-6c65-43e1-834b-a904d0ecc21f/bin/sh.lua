-- A shell. Just that, nothing more. --

shell = {}
local pwd = "/"
shell.pwd = function()return pwd end
shell.setPwd = function(new)pwd = new or "/" end
shell.version = function() return "Open Shell 1.0.0" end
local exit = false
shell.exit = function() exit = true end
shell.path = function() return "/bin:/sbin:/usr/bin" end

local tokenize, e = require("tokenize")
local network = network or require("network")
if not tokenize then print(e) sleep(10) end

function shell.resolvePath(path, strict)
  if path == ".." then
    printError("You cannot do that.")
    return shell.pwd()
  elseif path:sub(1,1) == "/" then
    if fs.exists(path) or not strict then
      return path
    end
  elseif fs.exists(shell.pwd() .. "/" .. path) or not strict then
    if shell.pwd():sub(-1) == "/" then
      return shell.pwd() .. path
    else
      return shell.pwd() .. "/" .. path
    end
  else
    return shell.pwd()
  end
end

local function runCommand(...)
  local cmd = table.concat({...}, " ")
  local toExec = ""
  local words = tokenize(" ", cmd)
  local head = words[1]:sub(1,1)
  local paths = tokenize(":", shell.path())
  for i=1, #paths, 1 do
    if fs.exists(paths[i] .. "/" .. words[1] .. ".lua") then
      toExec = paths[i] .. "/" .. words[1] .. ".lua"
    end
  end
  if head == "/" or head == "." then
    toExec = words[1]
  end
  if toExec == "" then
    error(words[1] .. ": Command not found")
    return
  end
  local args = table.new()
  for i=2, #words, 1 do
    args:insert(words[i])
  end
  local ok, err = loadfile(toExec)
  if not ok then
    error(err)
    return
  end
  ok(table.unpack(args))
end

--term.clear()
--term.setCursorPos(1,1)

write("Welcome to ")
term.setTextColor(colors.lightBlue)
print(shell.version())
term.setTextColor(colors.white)

pcall(runCommand, "motd")

local tHistory = table.new("")

while not exit do
  term.setTextColor(colors.red)
  write((network.hostname() or "localhost") .. ": " .. shell.pwd() .. "# ")
  term.setTextColor(colors.white)
  local command = read(nil, tHistory)
  if command ~= "" then
    if #tHistory >= 16 then -- Limit command history to 16 entries. Mostly for memory usage reasons.
      tHistory:remove(1)
    end
    tHistory:insert(command)
    local ok, err = pcall(function()
      runCommand(command)
    end)
    if not ok then
      printError(err)
    end
  end
end
