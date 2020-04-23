-- Stuff --

local ok, err = loadfile("/lib/colors.lua")
if not ok then
  kernel.log("Error " .. err .. "while loading /lib/colors.lua")
  return
end
ok()

local uptime, pullSignal = computer.uptime, computer.pullSignal

function sleep(time)
  local done = uptime() + time
  repeat
    pullSignal(time - uptime())
  until uptime() >= done
end
