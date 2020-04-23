-- Get and set filesystem labels. --

local args = {...}

if #args < 2 or (args[1] == "set" and #args < 3) then
  error("usage: label <get|set> <path> [label]")
  return false
end

local opt = args[1]
local path = args[2]
local label = table.concat(table.pack(table.unpack(args, 3, args.n)), " ")
local addr = ""

local mounts = fs.mounts()
for i=1, #mounts, 1 do
  if mounts[i].path == path then
    addr = mounts[i].addr
    break
  end
end

if opt == "get" then
  print("Label of", path, "is", fs.getLabel(addr))
elseif opt == "set" then
  fs.setLabel(label, addr)
  print("Label of", path, "set to", fs.getLabel(addr))
else
  error("Invalid operation " .. opt)
end
