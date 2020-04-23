-- Load OC-DOS --

local list, invoke = component.list, component.invoke
if not computer.getBootAddress then
  computer.getBootAddress = function()return nil end
end
local boot_fs = computer.getBootAddress() or list("filesystem")()

local ps = computer.pullSignal

local function loadfile(file)
  local handle = invoke(boot_fs, "open", file)
  if not handle then
    return false, "File not found"
  end
  local buffer = ""
  repeat
    local data = invoke(boot_fs, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  return load(buffer, "=" .. file, "bt", _G)
end

local ok, err = loadfile("/io.lua")
if not ok then
  if error then
    error(err)
  end
else
  ok()
end

while true do
  ps()
end
