-- I've been spending so much time writing OSes for CC, it's about time I wrote one for OC. --
-- This script just loads the kernel. That's all it does. You can go now. --

local addr, invoke = computer.getBootAddress(), component.invoke

local function loadfile(file)
  local handle = assert(invoke(addr, "open", file))
  local buffer = ""
  repeat
    local data = invoke(addr, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  invoke(addr, "close", handle)
  return load(buffer, "=" .. file, "bt", _G)
end

loadfile("/boot/kernel.lua")()

while true do
  local sig, _, n = computer.pullSignal()
  if sig == "key_down" then
    if string.char(n) == "r" then
      computer.shutdown(true)
    end
  end
end
