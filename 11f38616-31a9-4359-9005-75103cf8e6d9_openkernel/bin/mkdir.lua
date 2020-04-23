-- mkdir --

local args = {...} 

local dir = args[1]

if not dir then
  error("usage: mkdir DIR")
  return false
end

dir = shell.resolvePath(dir)

if fs.exists(dir) then
  error(dir .. ": Directory already exists")
  return false
end

return fs.makeDirectory(dir)
