-- ocdos.lua. Stage 2. --

-- Safer erroring --
_G.printError = function(...)
  local oldFG = gpu.getForeground()
  gpu.setForeground(0xFF0000)
  print(...)
  gpu.setForeground(oldFG)
end
_G.error = function(...)
  printError(...)
end
-----------------------------------------------------------------------------------------------------

-- Component registration --
local invoke = component.invoke
for addr, ctype in component.list() do -- Do things for all the components
  if ctype == "filesystem" then
    if invoke(addr, "getLabel") ~= "tmpfs" then
      dos.push("component_added", addr, ctype)
    end
  else
    dos.push("component_added", addr, ctype)
  end
end
-----------------------------------------------------------------------------------------------------

-- Module loading system --
_G.module = {}
local loaded = {
  ["_G"]        = _G,
  ["math"]      = math,
  ["string"]    = string,
  ["table"]     = table,
  ["component"] = table.copy(component),
  ["computer"]  = table.copy(computer),
  ["dos"]       = dos,
  ["term"]      = term,
  ["module"]    = module
}

-- Protected modules, i.e. they cannot be unloaded directly
local protected = {
  ["_G"]        = true,
  ["math"]      = true,
  ["string"]    = true,
  ["table"]     = true,
  ["component"] = true,
  ["computer"]  = true,
  ["dos"]       = true,
  ["term"]      = true,
  ["module"]    = true
}

-- Unclutter the global namespace a little bit
_G.component, _G.computer = nil, nil

module.path = "/dos;/dos/modules;/dosmodules" -- Paths that will be searched on available drives, or the specified drive, to find modules

function module.search(modName, drive)
  checkArg(1, modName, "string")
  checkArg(2, drive, "string")
  local path = string.tokenize(module.path, ";")
  local function search(d, mod)
    if fs.exists(d .. mod) then
      return d .. mod
    else
      return nil
    end
  end
  for i=1, #pathEntries, 1 do
    for k,_ in pairs(fs.drives()) do
      local path = search(k, pathEntries[i] .. "/" .. modName)
      if path then
        return path
      end
    end
  end
  return false, "Module not found"
end

function module.load(modName, drive)
  checkArg(1, modName, "string")
  checkArg(2, drive, "string")
  if loaded[modName] then
    return loaded[modName]
  else
    local path, err = module.search(modName, drive)
    if not path then
      return false, err
    end
    local ok, err = loadfile(path)
    if not ok then
      return false, err
    else
      loaded[modName] = ok()
      return loaded[modName]
    end
  end
end

function module.inject(modName, name, func) -- Inject a function into a loaded module
  checkArg(1, modName, "string")
  checkArg(2, name, "string")
  checkArg(3, func, "function")
  if loaded[modName][name] then
    return false
  else
    loaded[modName][name] = func
  end
end

function module.unload(modName)
  checkArg(1, modName, "string")
  if loaded[modName] and not protected[modName] then
    loaded[modName] = nil
    return true
  else
    return false
  end
end
-----------------------------------------------------------------------------------------------------

-- Load autoexec, if it exists --
if fs.exists("C:/autoexec.lua") then
  local ok, err = loadfile("A:/autoexec.lua")
  if ok then pcall(ok) end -- We don't want the system to error out in autoexec.
end
-----------------------------------------------------------------------------------------------------

-- Load the shell
local ok, err = loadfile("A:/command.lua")
if not ok then
  error(err)
end
ok()

term.clear()
term.update()
if os.sleep then
  os.sleep(1)
end

-- Don't shut down if command.lua exits; DOS never had ACPI support, at least not to my knowledge. init.lua will pullSignal infinitely. --
