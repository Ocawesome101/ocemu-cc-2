local tA = {...}
if #tA < 1 then
 local mt = fs.mounts()
 for k,v in pairs(mt) do
  print(tostring(fs.address(v)).." on "..tostring(v).." type "..fs.type(v))
 end
else
 local addr,path = tA[1],tA[2]
 local fscomp = component.list("filesystem")
 if not fscomp[addr] then
  for k,v in pairs(fscomp) do
   if k:find(addr) then
    print(tostring(addr).." not found, assuming you meant "..k)
    addr = k
    break
   end
  end
 end
 local proxy = component.proxy(addr)
 if not proxy then
  return false, "no such filesystem component"
 end
 print(fs.mount(path,proxy))
end
