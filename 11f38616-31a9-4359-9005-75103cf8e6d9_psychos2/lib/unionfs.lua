local unionfs = {}

local function normalise(path)
 return table.concat(fs.segments(path),"/")
end

function unionfs.create(...)
 local paths,fids,fc = {...}, {}, 0
 for k,v in pairs(paths) do
  paths[k] = "/"..normalise(v)
 end
 local proxy = {}
 local function realpath(path)
  path = path or ""
  for k,v in pairs(paths) do
   if fs.exists(v.."/"..path) then
    return v.."/"..path
   end
  end
  return paths[1].."/"..path
 end

 function proxy.setLabel()
  return false
 end
 
 function proxy.spaceUsed()
  return fs.spaceUsed(paths[1])
 end
 function proxy.spaceTotal()
  return fs.spaceTotal(paths[1])
 end
 function proxy.isReadOnly()
  return fs.isReadOnly(paths[1])
 end
 function proxy.isDirectory(path)
  return fs.isDirectory(realpath(path))
 end
 function proxy.lastModified(path)
  return fs.lastModified(realpath(path))
 end
 function proxy.getLabel()
  return fs.getLabel(paths[1])
 end

 function proxy.exists(path)
  return fs.exists(realpath(path))
 end
 function proxy.remove(path)
  return fs.remove(realpath(path))
 end
 function proxy.size(path)
  return fs.size(realpath(path))
 end

 function proxy.list(path)
  local nt,rt = {},{}
  if #fs.segments(path) < 1 then
   for k,v in pairs(paths) do
    for l,m in ipairs(fs.list(v.."/"..path)) do
     nt[m] = true
    end
   end
   for k,v in pairs(nt) do
    rt[#rt+1] = k
   end
   table.sort(rt)
   return rt
  else
   return fs.list(realpath(path))
  end
 end

 function proxy.open(path,mode)
  local fh, r = fs.open(realpath(path),mode)
  if not fh then return fh, r end
  fids[fc] = fh
  fc = fc + 1
  return fc - 1
 end

 function proxy.close(fid)
  if not fids[fid] then
   return false, "file not open"
  end
  local rfh = fids[fid]
  fids[fid] = nil
  return rfh:close()
 end
 function proxy.write(fid,d)
  if not fids[fid] then
   return false, "file not open"
  end
  return fids[fid]:write(d)
 end
 function proxy.read(fid,d)
  if not fids[fid] then
   return false, "file not open"
  end
  local rb = fids[fid]:read(d)
  if rb == "" then rb = nil end
  return rb
 end
 function proxy.seek(fid,d)
  if not fids[fid] then
   return false, "file not open"
  end
  return fids[fid]:seek(d)
 end

 return proxy
end

return unionfs
