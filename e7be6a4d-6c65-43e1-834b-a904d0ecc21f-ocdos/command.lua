-- Pretty much just a shell --

if cmd then
  error("Cannot run the shell in the shell\n")
  return false
end

print("Booted in " .. dos.uptime() - _START .. " seconds.")

_G.cmd = {}

local exit = false
local path = "/dos;/dos/programs;/programs"
local currentPwd = "/"

-- Exit the shell
function cmd.exit()
  exit = true
end

function cmd.pwd()
  return currentPwd
end

function cmd.cd(newDir)
  if fs.exists(newDir) then
    currentPwd = newDir
    return true
  else
    return false
  end
end

-- Parse arguments, filtering out switches
function cmd.parse(...)
  local args = {...}
  local rArgs, rSwitches = table.new(), table.new()
  for i=1, #args, 1 do
    if args[i]:sub(1,1) == "/" then
      rSwitches[args[i]:sub(2,2):lower()] = true
    else
      rArgs:insert(args[i])
    end
  end
  return rArgs, rSwitches
end

-- Execute programs from the path
function cmd.exec(program, ...)
  checkArg(1, program, "string")
  local paths = string.tokenize(path, ";")
  paths:insert(currentPwd)
  local programPath = ""
  local rootdrive = "A:" -- The root drive. Probably has our programs on it
  local drive = fs.getDrive()
  for p=1, #paths, 1 do
    if fs.exists(drive .. paths[p] .. "/" ..program) then
      programPath = drive .. paths[p] .. "/" .. program
    elseif fs.exists(drive .. paths[p] .. "/" .. program .. ".lua") then
      programPath = drive .. paths[p] .. "/" .. program .. ".lua"
    end
  end
  for p=1, #paths, 1 do
    if fs.exists(rootdrive .. paths[p] .. "/" ..program) then
      programPath = rootdrive .. paths[p] .. "/" .. program
    elseif fs.exists(rootdrive .. paths[p] .. "/" .. program .. ".lua") then
      programPath = rootdrive .. paths[p] .. "/" .. program .. ".lua"
    end
  end

  if program:sub(2,2) == ":" then
    if fs.exists(program) then
      programPath = program
    end
  end
  if programPath == "" then -- It wasn't found
    error("Program not found")
    return false
  end
  local ok, err = loadfile(programPath, "bt", _G)
  if not ok then
    error(err)
  end
  return ok(...)
end

while not exit do
  write(fs.concat(fs.getDrive(), currentPwd) .. "> ")
  term.update()
  local command = read()
  if command and command ~= "" then
    if command:sub(2,2) == ":" and #command == 2 then
      local ok, err = fs.chDrive(command)
      if not ok and err then
        printError(err)
      end
    else
      local command = string.tokenize(command, " ")
      local status, returned = pcall(function()cmd.exec(table.unpack(command))end)
      if not status then
        printError(returned)
      end
    end
  end
end
