-- Run or download programs from Pastebin. --

local args = {...}

local pastebin = "https://pastebin.com/raw/"

local internet = internet or require("internet")

if not internet then
  error("This program requires an internet card.")
end

local function downloadHandle(code)
  print("Downloading " .. pastebin .. code)
  local handle = internet.request(pastebin .. code)
  if not handle then
    error("Download failed.")
  else
    return handle
  end
end

local function contents(openHandle)
  print("Getting contents of paste")
  local rtn = ""
  repeat
    local chunk = openHandle.read(0xFFFF)
    rtn = rtn .. (chunk or "")
  until not chunk
  openHandle:close() -- Be tidy
  return rtn
end

local function writeFile(data, file)
  print("Writing data to file")
  local fileHandle = fs.open(file, "w")
  fileHandle.write(data)
  fileHandle.close()
end

if #args < 2 or (args[1] == "get" and #args < 3) then
  error("usage: pastebin <run|get> <code> [file]")
  return false
end

local pasteHandle = downloadHandle(args[2])
local pasteData = contents(pasteHandle)

if args[1] == "run" then
  local ok, err = load(pasteData, "@" .. args[2], "t", _G)
  if not ok then
    error(err)
    return false
  end
  ok()
elseif args[1] == "get" then
  writeFile(pasteData, args[3])
end
