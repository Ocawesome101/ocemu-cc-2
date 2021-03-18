-- hostname --

local args = {...} 

if args[1] and type(args[1]) == "string" then
  network.setHostname(args[1])
else
  print(network.hostname())
end
