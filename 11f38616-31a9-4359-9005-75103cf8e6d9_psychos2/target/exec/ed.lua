local tA = {...}
local ft, p, fp, ct, il, it, c, C = {}, 1, fp or tA[1] or "", {}, "", {}, "", C -- file table, pointer, filename, command table, input line, input table, command, content
function ct.readfile(fp,rp)
 if not fp then return end
 if not rp then ft = {} end
 local f=io.open(fp,"rb")
 if f then
  C=f:read("*a")
  f:close()
  for l in C:gmatch("[^\n]+") do
   ft[#ft+1] = l
  end
 end
end
function ct.writefile(nfp)
 if not nfp then nfp = fp end
 print(nfp)
 f=io.open(nfp,"wb")
 if f then
  for k,v in ipairs(ft) do
   print(v)
   f:write(v.."\n")
  end
  coroutine.yield()
  f:close()
  coroutine.yield()
  print(f.b)
 end
end
function ct.list(s,e)
 s,e = s or 1, e or #ft
 for i = s,e do
  if ft[i] then
   print(string.format("%4d\t %s",i,ft[i]))
  end
 end
end
function ct.sp(np)
 np=tonumber(np)
 if np then
  if np > #ft then
   np = #ft
  elseif np < 1 then
   np = 0
  end
  p=np
 end
end
function ct.pointer(np)
 ct.sp(np)
 print(string.format("%4d\t %s",p,ft[p]))
end
function ct.insert(np)
 ct.sp(np)
 while true do
  io.write(string.format("%4d\t ",p))
  local l=io.read()
  if l == "." then break end
  table.insert(ft,p,l)
  p=p+1
 end
end
function ct.append(np)
 ct.sp(np)
 p=p+1
 if #ft < 1 then p = 1 end
 ct.insert()
end
function ct.delete(np,n)
 ct.sp(np)
 _G.clip = ""
 for i = 1, (n or 1) do
  _G.clip = _G.clip .. table.remove(ft,p) .. "\n"
 end
end
function ct.substitute(np,n)
 ct.delete(np,n)
 ct.insert(np)
end
function ct.filename(np)
 if np then fp = np end
 print(fp)
end

local function rawpaste()
 for line in string.gmatch(_G.clip,"[^\n]") do
  print(string.format("%4d\t %s",p,line))
  table.insert(ft,p,line)
 end
end
function ct.pasteprevious(np)
 ct.sp(np)
 rawpaste()
end
function ct.paste(np)
 ct.sp(np)
 p = p + 1
 rawpaste()
end

ct.o = ct.readfile
ct.w = ct.writefile
ct.l = ct.list
ct.p = ct.pointer
ct.i = ct.insert
ct.a = ct.append
ct.s = ct.substitute
ct.d = ct.delete
ct.f = ct.filename
ct.PP = ct.pasteprevious
ct.P = ct.paste

ct.readfile(fp)

while true do
 io.write("skex2> ")
 il,it=io.read(),{}
 for w in il:gmatch("%S+") do
  it[#it+1] = w
 end
 c=table.remove(it,1)
 if c == "quit" or c == "q" then
  break
 elseif c:sub(1,1) == "!" then
  print(pcall(load(c:sub(2))))
 elseif ct[c] ~= nil then
  ct[c](table.unpack(it))
 end
end
