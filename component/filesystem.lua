-- fs component --

local filesystem = {}

local expect = require("cc.expect").expect

filesystem.address = ""
filesystem.label = "emufs"

local function p(_p)
  if not fs.exists(filesystem.address) then fs.makeDir(filesystem.address) end
  return fs.combine(filesystem.address, _p)
end

local function z()
  return 0
end

local function h()
  return math.huge
end

local function t()
  return true
end

local function f()
  return false
end

filesystem.spaceUsed = z
filesystem.spaceTotal = h
filesystem.lastModified = z
filesystem.isReadOnly = f

local handles = {}
function filesystem.open(file, mode)
  expect(1, file, "string")
  expect(2, mode, "string", "nil")
  local afile = p(file)
  if not fs.exists(afile) then
    return nil, file
  end
  local h = io.open(afile, (mode or "r") .. "b")
  local hid = #handles + 1
  handles[hid] = h
  return hid
end

function filesystem.read(h, a)
  expect(1, h, "number")
  expect(2, a, "number")
  if a > 2048 then a = 2048 end
  if not handles[h] then
    return nil, "bad file descriptor"
  end
  return handles[h]:read(a)
end

function filesystem.write(h, d)
  expect(1, h, "number")
  expect(2, d, "string")
  if not handles[h] then
    return nil, "bad file descriptor"
  end
  return handles[h]:write(d)
end

function filesystem.seek(h, w, o)
  expect(1, h, "number")
  expect(2, w, "string")
  expect(3, o, "number")
  if not handles[h] then
    return nil, "bad file descriptor"
  end
  return handles[h]:seek(h, w, o)
end

function filesystem.close(h)
  expect(1, h, "number")
  if not handles[h] then
    return nil, "bad file descriptor"
  end
  return handles[h]:close()
end

function filesystem.makeDirectory(path)
  expect(1, path, "string")
  return fs.makeDir(p(path))
end

function filesystem.exists(path)
  expect(1, path, "string")
  return fs.exists(p(path))
end

function filesystem.isDirectory(path)
  expect(1, path, "string")
  return fs.isDir(p(path))
end

function filesystem.rename(src, dest)
  expect(1, src, "string")
  expect(2, dest, "string")
  fs.delete(p(dest))
  return fs.move(p(src), p(dest))
end

function filesystem.remove(path)
  expect(1, path, "string")
  return fs.delete(p(path))
end

function filesystem.size(path)
  expect(1, path, "string")
  local s = fs.getSize(path)
  return (s > 0 and s) or 512
end

function filesystem.list(path)
  expect(1, path, "string")
  return fs.list(p(path))
end

function filesystem.getLabel()
  return filesystem.label
end

function filesystem.setLabel(lbl)
  expect(1, lbl, "string")
  filesystem.label = lbl:sub(1, 32)
  return lbl:sub(1, 32)
end

return filesystem
