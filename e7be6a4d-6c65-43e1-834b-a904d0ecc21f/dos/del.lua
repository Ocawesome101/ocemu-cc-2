-- del --

local args, switches = cmd.parse(...)

if #args < 1 then
  return error("Required parameter missing")
end

local file = fs.concat(fs.getDrive() .. cmd.pwd(), args[1])

if fs.exists(file) then
  if switches.p then
    while true do
      write(file .. ", Delete? [y/n] ")
      local yn = read()
      if yn:lower() == "y" then
        return fs.remove(file)
      elseif yn:lower() == "n" then
        return
      end
    end
  else
    return fs.remove(file)
  end
else
  return error("File not found")
end
