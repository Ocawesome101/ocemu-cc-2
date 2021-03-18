-- File copier. Should work. --

local args = {...} 

if #args < 2 then
  error("usage: cp SOURCE DESTINATION")
  return false
end

fs.copy(shell.resolvePath(args[1]), shell.resolvePath(args[2]))
