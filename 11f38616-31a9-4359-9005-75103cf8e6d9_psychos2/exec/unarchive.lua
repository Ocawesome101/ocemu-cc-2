local tArgs = {...}

local function toint(s)
 s=s or ""
 local n = 0
 local i = 1
 while true do
  local p = s:sub(i,i)
  if p == "" then break end
  local b = string.byte(p)
  n = n << 8
  n = n | b
  i=i+1
 end
 return n
end

local fi = io.open(tArgs[1])
while true do
 local nlen = toint(fi:read(2))
 if nlen == 0 then
  break
 end
 local name = fi:read(nlen)
 local fsize = toint(fi:read(2))
 io.write(string.format("%s: %d... ",name,fsize))
 if not tArgs[2] then
  local dir = name:match("(.+)/.*%.?.+")
  if (dir) then
   fs.makeDirectory(dir)
  end
  local f = io.open(name,"wb")
  local rsize,buf = fsize, ""
  if f then
   repeat
    buf = fi:read(math.min(rsize,1024))
    f:write(buf)
    rsize = rsize - buf:len()
   until rsize <= 1
   f:close()
  end
 else
  local rsize = fsize
  repeat
   buf = fi:read(math.min(rsize,1024))
   rsize = rsize - buf:len()
  until rsize <= 1
 end
 print(fsize)
end
fi:close()
