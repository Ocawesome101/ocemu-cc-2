-- Should, in theory, install Open Kernel to a selected medium. --

local args = {...}

-- Multi-platform compat right here
local term = term or require("term")
local read = read or io.read
local http = http or internet or require("component").internet
local fs = fs or require("filesystem")

local write = write or term.write

local path = args[1] or nil

local function install_computerCraft(path)
  error("ComputerCraft support is not implemented yet")
end

local function install_openComputers(path)
  local url = "https://raw.githubusercontent.com/ocawesome101/open-kernel/master/files.list"
  local function download(URL)
    local h
    if http.request then
      h = http.request(URL)
      h.finishConnect()
    else
      h = http.get(URL)
    end
    return h
  end
  local handle = download(url)
  local data = ""
  repeat
    local chunk = handle.read(0xFFFF)
    data = data .. (chunk or "")
  until not chunk
  
  handle:close()
  
  local lines = {}
  local word = ""
  -- Split the files list into lines
  for char in string.gmatch(data, ".") do
    if char == "\n" then
      table.insert(lines, word)
      word = ""
    else
      word = word .. char
    end
  end
  -- Finally, download the files
  local baseURL = "https://raw.githubusercontent.com/ocawesome101/open-kernel/master/"
  for i=1, #lines, 1 do
    if lines[i]:sub(-1) == "/" then
      print("Creating " .. path .. "/" .. lines[i])
      fs.makeDirectory(path .. lines[i])
    else
      print("Downloading " .. lines[i])
      local handle = download(baseURL .. lines[i])
      local data = ""
      repeat
        local chunk = handle.read(0xFFFF)
        data = data .. (chunk or "")
      until not chunk

      handle:close()

      print("Writing " .. lines[i])
      local handle = fs.open(path .. "/" .. lines[i], "w")
      if fs.proxy then
        handle:write(data)
        handle:close()
      else
        handle.write(data)
        handle.close()
      end
    end
  end
end

local mounts = fs.list("/mnt")
local choice
while true do
  print("Please select an install medium.")
  if type(mounts) == "function" then
    local m = {}
    for mount in mounts do
      print(i, "/mnt/" .. mount)
      table.insert(m, mount)
    end
    mounts = m
  else
    for i=1, #mounts, 1 do
      print(i, "/mnt/" .. mounts[i])
    end
  end

  write("> ")

  local input = read()
  if not mounts[tonumber(input)] then
    print("Invalid selection")
  else
    choice = tonumber(input)
    break
  end
end

local selection = path or "/mnt/" .. mounts[choice]

print("You have selected " .. selection .. ". Continue?")
write("[y/N]: ")

local input = read()

if input:lower() ~= "y" then
  print("Answer was not yes, assuming no. Have a good day.")
  return false
end

local platform = 1

if platform == 1 then
  install_openComputers(selection)
elseif platform == 2 then
  install_computerCraft(selection)
end