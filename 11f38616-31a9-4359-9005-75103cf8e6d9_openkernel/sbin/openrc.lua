-- OpenRC: Background process management for Open Kernel. --

if module.loaded["openrc"] then
  return error("OpenRC has already been started.")
end

local rc = {}
local daemons = table.new()

local tokenize = require("tokenize")

function rc.start(daemon)
  checkArg(1, daemon, "string")
  if daemon:sub(1, 1) ~= "/" then
    return false, "Daemon path must be absolute"
  end
  local path = tokenize(".", daemon)
  local pname = path[1]
  local z = tokenize("/", pname)
  pname = z[#z]
  kernel.log("Starting OpenRC service " .. pname)
  if not os.info(pname) then
    local pid, err = os.spawn(pname, daemon)
    if not pid then
      kernel.log("Failed to start " .. pname .. ": " .. err)
    end
    daemons[pname] = {pid = pid, name = pname, fpath = daemon}
    return pname
  else
    return false, "Daemon is already running"
  end
end

function rc.stop(daemon)
  checkArg(1, daemon, "string")
  if daemons[daemon] then
    return os.kill(daemons[daemon])
  else
    return false, "Daemon is not running"
  end
end

function rc.restart(daemon)
  checkArg(1, daemon, "string")
  local ok, err = rc.stop(daemon)
  if not ok then
    error(err)
    return false
  else
    local ok, err = rc.start(daemon)
    if not ok then
      error(err)
      return false
    else
      return true
    end
  end
end

function rc.info(daemon)
  checkArg(1, daemon, "string")
  if daemons[daemon] then
    return os.info(daemons[daemon].pid)
  else
    return false, "Daemon is not running"
  end
end

-- Inject OpenRC into the loaded module index, so that it can be required by programs.
module.loaded["openrc"] = rc

-- Start services according to the configuration
kernel.log("Checking for OpenRC configuration at /etc/openrc.cfg")
local handle, err = fs.open("/etc/openrc.cfg", "r")
local cfg = {}
if not handle then
  kernel.log("No OpenRC configuration found")
else
  local ok, err = load("return " .. handle.readAll(), "=openrc.cfg", "bt", _G)
  if not ok then
    kernel.log("Error parsing OpenRC configuration: " .. err)
  else
    cfg = ok()
  end
end

for k,v in pairs(cfg) do
  local ok, err = rc.start(v)
end
