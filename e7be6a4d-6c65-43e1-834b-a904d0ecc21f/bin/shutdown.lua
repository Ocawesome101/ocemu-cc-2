-- Shut down --

local args = {...} 

local computer = computer or require("computer")

if #args < 1 then
  error("usage: shutdown -s|-r")
  return false
end

if args[1] == "-s" then
  kernel.log("Shutting down")
  term.update()
  computer.shutdown(false)
elseif args[1] == "-r" then
  kernel.log("Restarting")
  term.update()
  computer.shutdown(true)
else
  error("usage: shutdown -s|-r")
  return false
end
