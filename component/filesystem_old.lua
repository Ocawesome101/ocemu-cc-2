-- FS component --

local filesystem = {}

local fsAddress = "/"

local openHandles = {}

function filesystem.setAddress(addr) -- Used internally
  fsAddress = "/" .. addr .. "/"
end

function filesystem.seek()
  return false, "This function is not implemented"
end

function filesystem.spaceUsed() -- Behaves like fs.spaceFree() :P
  return fs.getFreeSpace()
end

function filesystem.isReadOnly()
  return false
end

function filesystem.list(path)
  return fs.list(fsAddress .. "/" .. path)
end

function filesystem.rename(source, dest)
  if not fs.exists(fsAddress .. "/" .. source) then
    return true
  end
  return fs.move(fsAddress .. "/" .. source, fsAddress .. "/" .. dest)
end

function filesystem.lastModified()
  return 0
end

--filesystem.isDir = true -- Tell Open Kernel's /etc/init.d/70_filesystem.lua we're on computercraft

function filesystem.makeDirectory(path)
  return fs.makeDir(fsAddress .. "/" .. path)
end

function filesystem.getLabel()
  return os.getComputerLabel()
end

function filesystem.setLabel(label)
  os.setComputerLabel(label)
  return label
end

function filesystem.size(path)
  return fs.getSize(fsAddress .. "/" .. path)
end

function filesystem.spaceTotal()
  return fs.getFreeSpace()
end

function filesystem.isDirectory(path)
  return fs.isDir(fsAddress .. "/" .. path)
end

function filesystem.exists(path)
  return fs.exists(fsAddress .. "/" .. path)
end

function filesystem.open(file, mode)
  if not fs.exists(fsAddress .. "/" .. file) and mode ~= "w" then
    return false, file .. ": file not found"
  end
  local mode = mode or "r"
  local handle = io.open(fsAddress .. "/" .. file, mode)
  openHandles[#openHandles + 1] = handle
  return #openHandles
end

function filesystem.read(handle, amount)
  local amount = amount
  if amount == math.huge then
    amount = 0xFFFF
  end
  if openHandles[handle] then
    local rtnData = openHandles[handle]:read(amount)
    return rtnData
  else
    return nil
  end
end

function filesystem.write(handle, data)
  if openHandles[handle] then
    return openHandles[handle]:write(data)
  end
end

function filesystem.close(handle)
  if openHandles[handle] then
    openHandles[handle]:close()
  end
end

return filesystem
