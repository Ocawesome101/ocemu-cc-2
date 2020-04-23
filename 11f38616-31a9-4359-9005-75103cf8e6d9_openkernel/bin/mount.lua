-- disk mounter --

local args = {...} 

if args[1] and args[2] then
  fs.mount(args[1], args[2])
elseif args[1] then
  error("usage: mount SOURCE DEST")
else
  local mnt = fs.mounts()
  for i=1, #mnt, 1 do
    local name = mnt[i].addr
    if fs.getLabel(name) then
      name = "\"" .. fs.getLabel(name) .. "\""
    end
    print(name, "mounted on", mnt[i].path)
  end
end
