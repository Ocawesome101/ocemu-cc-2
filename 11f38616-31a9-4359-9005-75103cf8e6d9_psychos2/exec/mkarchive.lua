local tArgs = {...}
local output = table.remove(tArgs,#tArgs)
local of = io.open(output,"wb")
local files, dirs = {}, {tArgs[1] or "."}

local function cint(n,l)
 local t={}
 for i = 0, 7 do
  t[i+1] = (n >> (i * 8)) & 0xFF
 end
 return string.reverse(string.char(table.unpack(t)):sub(1,l))
end

local function genHeader(fname,len)
 return string.format("%s%s%s",cint(fname:len(),2),fname,cint(len,2))
end

for k,v in pairs(dirs) do
 local dir = fs.list(v)
 for _,file in ipairs(dir) do
  if fs.isDirectory(file) then
   dirs[#dirs+1] = v.."/"..file
  else
   files[#files+1] = v.."/"..file
  end
 end
end

for k,v in ipairs(files) do
 io.write(v)
 local f = io.open(v,"rb")
 if f then
  of:write(genHeader(v,fs.size(v)))
  while true do
   local c = f:read(1024)
   if not c or c == "" then break end
   of:write(c)
  end
  f:close()
 end
 print("... done")
end
of:write(string.char(0):rep(2))
of:close()
