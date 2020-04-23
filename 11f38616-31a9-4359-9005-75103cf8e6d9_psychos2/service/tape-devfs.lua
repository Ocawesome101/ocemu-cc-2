local counter = 0
local td = {}
local function addNode(addr)
 devfs.register("tape"..tonumber(counter),function()
  local tape = component.proxy(addr)
  return tape.read, tape.write, function() end, tape.seek
 end)
 td[addr] = counter
 counter = counter + 1
end
for addr in component.list("tape_drive") do
 addNode(addr)
end
while true do
 local tE = {coroutine.yield()}
 if tE[1] == "component_added" and tE[3] == "tape_drive" then
  addNode[tE[2]]
 elseif tE[1] == "component_removed" and tE[3] == "tape_drive" then
  if td[tE[2]] then
   fs.remove("/dev/tape"..tostring(td[tE[2]]))
  end
 end
end
