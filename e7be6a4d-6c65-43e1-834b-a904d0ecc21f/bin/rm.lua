-- rm --

local args = {...}

if #args < 1 then
  error("usage: rm FILE1 FILE2 ...")
  return false
end

for i=1, #args, 1 do
  if fs.exists(shell.resolvePath(args[i])) then
    write("Really delete " .. args[i] .. "? [y/n] ")
    local yn = read()
    if yn:lower() == "y" then
      fs.remove(shell.resolvePath(args[i]))
    else
      print("Skipping")
    end
  else
    printError(args[i] .. ": No such file")
  end
end
