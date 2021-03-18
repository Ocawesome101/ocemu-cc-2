-- cd --

local args, switches = cmd.parse(...) 

if #args < 1 then
  print(fs.concat(fs.getDrive(), cmd.pwd()))
  return
end

cmd.cd(fs.concat(cmd.pwd(), args[1]))
