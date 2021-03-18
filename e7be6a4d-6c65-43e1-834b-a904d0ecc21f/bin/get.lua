print("Press Q to exit")

while true do
  local data = {event.pull()}
  print(table.unpack(data))
  if string.char(data[3]) == "q" then
    break
  end
end
