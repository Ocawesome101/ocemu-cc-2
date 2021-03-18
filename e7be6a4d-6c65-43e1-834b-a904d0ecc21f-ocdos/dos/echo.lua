-- echo --

local args, switches = {...} 

if #args < 1 then
  return print("")
end

print(table.unpack(args))
