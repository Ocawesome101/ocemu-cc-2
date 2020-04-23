local tA = {...}
for _,fn in ipairs(tA) do
 local f = io.open(fn,"rb")
 io.write(f:read("*a"))
 f:close()
end
