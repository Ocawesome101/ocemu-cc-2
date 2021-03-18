-- Collaborative multiosing. --

local tasks = table.new(
  {
    pid = 0,
    id = "kernel",
    coro = nil
  },
  {
    pid = 1,
    id = "init",
    coro = nil
  }
)

local counter = 1
function os.spawn(name, process)
  checkArg(1, name, "string")
  checkArg(2, process, "string", "function")
  local coro, err
  if type(process) == "string" then
    local ok, err = loadfile(process)
    if not ok then
      return false, err
    end
    coro, err = coroutine.create(ok)
    if not coro then
      return false, err
    end
  else
    coro, err = coroutine.create(process)
    if not coro then
      return false, err
    end
  end
  counter = counter + 1
  local pid = counter
  kernel.log("Spawning process " .. tostring(pid) .. " with name " .. name)
  tasks[pid] = {pid = pid, id = name, coro = coro}
  return pid
end

function os.kill(pid)
  if pid == 0 or pid == 1 then
    return false, "Cannot kill a system process"
  end
  kernel.log("Killing process " .. tostring(pid))
  if tasks[pid].pid == pid then
    tasks[pid] = nil
    return true
  end
  for i,v in pairs(tasks) do
    if tasks[i].pid == pid then
      tasks[i] = nil
      return true
    end
  end
  kernel.log("No such process")
  return false, "No such process"
end

function os.info(task)
  checkArg(1, task, "number", "string", "nil")
  if not task then
    local r = table.new()
    for i=1, #tasks, 1 do
      r:insert({pid = tasks[i].pid, name = tasks[i].id})
    end
    return r
  elseif type(task) == "number" then
    for i=1, #tasks, 1 do
      if tasks[i].pid == task then
        return {pid = tasks[i].pid, name = tasks[i].id}
      end
    end
  else
    for i=1, #tasks, 1 do
      if tasks[i].name == task then
        return {pid = tasks[i].pid, name = tasks[i].id}
      end
    end
  end
  return false, "Invalid process ID"
end

function os.start()
  local eventData = {n = 0}
  local filters = table.new()
  while true do
    for i,v in pairs(tasks) do
      if tasks[i].coro then
        if filters[i] == nil or filters[i] == eventData[1] or filters[i] == "" then
          local ok, param = coroutine.resume(tasks[i].coro, table.unpack(eventData))
          if not ok then
            kernel.log("Task " .. (tasks[i].id or tostring(tasks[i].pid) or tostring(i)) .. " died: " .. param)
            tasks:remove(i)
            if filters[i] then
              filters:remove(i)
            end
          else
            filters[i] = param
          end
        end
      end
    end
    eventData = {event.pull(nil, 0.5)}
  end
end
