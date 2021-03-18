-- Filesystem API wrapper-ish-kinda-sorta thing --

local oldOpen = fs.open

function fs.open(file, mode, returnHandle)
  if not fs.exists(file) then
    return false
  end
  local handle = oldOpen(file, mode)
  if returnHandle then
    return handle
  end
  local rtn = {}
  function rtn.read(amount)
    return fs.read(handle, amount)
  end
  function rtn.readAll()
    local r = ""
    repeat
      local data = fs.read(handle, 0xFFFF) -- If you've got a file larger than 64K you're insane. Literally.
      r = r .. (data or "")
    until not data
    return r
  end
  function rtn.write(data)
    fs.write(handle, data)
  end
  function rtn.close()
    rtn = nil
    return fs.close(handle)
  end
  return rtn
end
