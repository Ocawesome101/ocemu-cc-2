-- mkdir --

local args, switches = cmd.parse(...)

if #args < 1 then
  return error("Required parameter missing")
end

if fs.exists(fs.concat(cmd.pwd(), args[1])) then
  return error("Directory already exists")
end

return fs.makeDirectory(fs.concat(cmd.pwd(), args[1]))
