-- Event management --

event = {}

event.listeners = {
  ["component_added"] = function(addr, ctype)
    if ctype == "filesystem" then
      if fs.mount then
        fs.mount(addr)
      end
      elseif ctype == "gpu" then
        term.enableGPU(addr)
      end
  end,
 ["component_removed"] = function(addr, ctype)
    if ctype == "filesystem" then
      if fs.unmount then
        fs.unmount(addr)
      end
    elseif ctype == "gpu" then
      term.disableGPU(addr)
    end
  end
}

setmetatable(event.listeners, { __index = table })

function event.addListener(event, func)
  event.listeners[event] = func
end

function event.removeListener(event)
  if event.listeners[event] then
    event.listeners[event] = nil
  end
end

local pullSignal = computer.pullSignal

function event.pull(filter, timeout)
  if timeout then
    local data = {pullSignal(timeout)}
    if event.listeners[data[1]] then -- Support event listeners
      event.listeners[data[1]](table.unpack(data, 2, data.n))
    end
    if data[1] == filter then
      return table.unpack(data)
    elseif not filter then
      return table.unpack(data)
    end
    return
  end
  while true do
    local data = {pullSignal()}
    if event.listeners[data[1]] then -- Support event listeners
      event.listeners[data[1]](table.unpack(data, 2, data.n))
    end
    if data[1] == filter then
      return table.unpack(data)
    elseif not filter then
      return table.unpack(data)
    end
  end
end
