-- Further enhance the filesystem API -- 

local component = require("component")

kernel.log("Getting root filesystem address")

-- Get the root filesystem address
local eeprom = component.list("eeprom")()
local rootfsAddress = component.invoke(eeprom, "getData")

local serialize = require("serialize")

kernel.log("Initializing mount system")
local mounts = table.new()

function fs.mount(addr, path)
  if addr:find("/") then
    return false
  end
  local path = path or "/mnt/"..addr:sub(1,3)
  for i=1, #mounts, 1 do
    if mounts[i].path == path then
      return true
    end
  end
  kernel.log("Mounting filesystem " .. addr .. " at " .. path)
  fs.makeDirectory(path)
  mounts:insert({
    ["path"] = path,
    ["addr"] = addr,
    ["proxy"] = component.proxy(addr) -- TODO: make this do something
  })
  return true
end

function fs.mounts()
  return mounts
end

local remove = fs.remove
function fs.unmount(filesystem) -- Supports unmounting by address or by path
  if filesystem == "/" or filesystem == rootfsAddress then
    return false, "Cannot unmount the root filesystem"
  end
  kernel.log("Unmounting " .. filesystem)
  for i=1, #mounts, 1 do
    if mounts[i].path == filesystem then
      remove(mounts[i].path)
      mounts:remove(i)
      return true, "Unmounted"
    end
    if mounts[i].addr == filesystem then
      remove(mounts[i].path)
      mounts:remove(i)
      return true, "Unmounted"
    end
  end
  return false, "No filesystem mounted at " .. filesystem
end

function fs.exec(path, operation, ...)
  local args = {...}
  for i=1, #mounts, 1 do
    local mountPath = mounts[i].path
    if mountPath ~= "/" then
      if path:sub(1, #mountPath) == mountPath then
        for i=1, #args, 1 do
          if args[i]:sub(1, #mountPath) == mountPath then
            args[i] = args[i]:sub(#mountPath + 1, #args[i])
          end
        end
        return component.invoke(mounts[i].addr, operation, table.unpack(args))
      end
    end
  end
  return component.invoke(rootfsAddress, operation, table.unpack(args))
end

function fs.open(path, mode, returnHandle)
  local rtn = {}
  local handle = fs.exec(path, "open", path, mode)
  if returnHandle then
    return handle
  end
  
  if not handle then
    return false
  end

  function rtn.close()
    fs.close(handle)
    rtn = nil
  end
  
  if mode == "r" or mode == "rw" or mode == "a" then
    function rtn.read(amount)
      return fs.read(handle, amount)
    end
    function rtn.readAll()
      local buffer = ""
      repeat
        local data = fs.read(handle, 0xFFFF)
        buffer = buffer .. (data or "")
      until not data
      return buffer
    end
  end
  
  if mode == "w" or mode == "rw" or mode == "a" then
    function rtn.write(data)
      fs.write(handle, data)
    end
  end
  
  return rtn
end

function fs.remove(path)
  if path == "/mnt" then
    return false, "Cannot remove /mnt"
  end
  return fs.exec(path, "remove", path)
end

function fs.size(path)
  return fs.exec(path, "size", path)
end

function fs.list(path)
  return fs.exec(path, "list", path)
end

function fs.isDirectory(path)
  return fs.exec(path, "isDirectory", path)
end

function fs.makeDirectory(path)
  return fs.exec(path, "makeDirectory", path)
end

function fs.rename(source, destination)
  return fs.exec(path, "rename", source, destination)
end

fs.move = fs.rename

function fs.copy(source, destination) -- Why on earth do we not have this by default?
  if fs.isDirectory(source) then
    fs.makeDirectory(destination)
    local files = fs.list(source)
    for i=1, #files, 1 do
      fs.copy(source .. "/" .. files[i], destination .. "/" .. files[i])
    end
  else
    local inHandle = fs.open(source, "r")
    local inData = inHandle.readAll()
    inHandle.close()
    local outHandle = fs.open(destination, "w")
    outHandle.write(inData)
    outHandle.close()
  end
end

function fs.lastModified(path)
  return fs.exec(path, "lastModified", path)
end

function fs.exists(path)
  return fs.exec(path, "exists", path)
end

function fs.getLabel(addr) -- Optionally can specify the FS address of which to get the label
  local addr = addr or rootfsAddress
  return component.invoke(addr, "getLabel")
end

function fs.setLabel(label, addr)
  local addr = addr or rootfsAddress
  return component.invoke(addr, "setLabel", label)
end

fs.delete = fs.remove -- I'm used to the CraftOS version and I think delete makes more sense anyway

fs.delete("/mnt")

fs.makeDirectory("/mnt")
if not fs.exists("/tmp") then
  fs.makeDirectory("/tmp")
end

fs.mount(rootfsAddress, "/")

kernel.log("Mounting external filesystems")
for addr, ctype in component.list("filesystem") do
  if fs.getLabel(addr) == "tmpfs" then
    fs.mount(addr, "/tmp")
  elseif addr ~= rootfsAddress then
    fs.mount(addr)
  end
end
