-- umount. Why it isn't unmount I've no idea --

local args = {...}

if not args[1] then
  error("usage: umount PATH")
  return false
end

print("Umounting", args[1])

local ok, err = fs.unmount(args[1])
if not ok then
  error(err)
end
