local function mount(addr)
 dest = component.invoke(addr,"getLabel") or "mnt/"..addr:sub(1,3)
 dest = "/"..dest
 syslog("Mounting "..addr.." to "..dest)
 fs.makeDirectory(dest)
 local w,r = fs.mount(dest,component.proxy(addr))
 if not w then 
  syslog("Failed to mount: "..r)
 end
end
for addr, _ in component.list("filesystem") do
 mount(addr)
end
while true do
 local tE = {coroutine.yield()}
 if tE[1] == "component_added" and tE[3] == "filesystem" then
  mount(tE[2])
 elseif tE[1] == "component_removed" and tE[3] == "filesystem" then
  fs.umount("/mnt/"..tE[2]:sub(1,3))
 end
end
