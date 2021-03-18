-- This has been missing --

local args = {...}

if #args < 1 then
  return error("usage: wget URL [FILE]")
end

local internet = internet or require("internet")
local tokenize = require("tokenize")

if not internet then
  return error("This program requires an internet card.")
end

local function downloadHandle(file)
  print("Downloading " .. file)
  local handle = internet.request(file)
  if not handle then
    error("Download failed.")
  else
    return handle
  end
end

local function contents(openHandle)
  local rtn = ""
  repeat
    local chunk = openHandle.read(0xFFFF)
    rtn = rtn .. (chunk or "")
  until not chunk
  openHandle:close() -- Be tidy
  return rtn
end

local function writeFile(data, file)
  local fileHandle = fs.open(file, "w")
  fileHandle.write(data or "")
  fileHandle.close()
end

local fileHandle = downloadHandle(args[1])
repeat
  local s = fileHandle.finishConnect()
until s == true
local fileData = contents(fileHandle)

--local url = tokenize(args[1], "/")

writeFile(pasteData, args[2] or url[#url])
