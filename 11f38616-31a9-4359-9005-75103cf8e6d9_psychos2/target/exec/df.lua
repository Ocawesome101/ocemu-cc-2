local mt = fs.mounts()
local ml = 0
for k,v in pairs(mt) do
 if v:len() > ml then
  ml = v:len()
 end
end
local scale = {"K","M","G","T","P"}
local function wrapUnits(n)
 local count = 0
 while n > 1024 do
  count = count + 1
  if not scale[count] then return "inf" end
  n = n / 1024
 end
 return tostring(math.floor(n))..(scale[count] or "")
end
local fstr = "%-"..tostring(ml).."s %5s %5s"
print("fs"..(" "):rep(ml-2).."  size  used")
for k,v in pairs(mt) do
 local st, su = fs.spaceTotal(v), fs.spaceUsed(v)
 print(string.format(fstr,v,wrapUnits(st),wrapUnits(su)))
end
