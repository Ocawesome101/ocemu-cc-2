-- Simple MV shell command. --

local args = {...} 

if #args < 2 then
  error("usage: mv SOURCE DESTINATION")
  return false
end

fs.move(shell.resolvePath(args[1]), shell.resolvePath(args[2]))
