-- cat --

local args = {...}

if #args < 1 then
  error("usage: cat FILE")
  return false
end

local path = shell.resolvePath(args[1])

if not fs.isDirectory(path) then
  local handle = fs.open(path, "r")
  local data = handle.readAll()
  handle.close()
  print(data)
else
  error(path .. ": Cannot cat a directory")
  return false
end
