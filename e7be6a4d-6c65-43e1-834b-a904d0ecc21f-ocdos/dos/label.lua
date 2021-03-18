-- Label manager --

local args = {...} 

local currentdrive = fs.getDrive()
local currentlabel = fs.getLabel(currentdrive)
local driveaddr = fs.getAddress(currentdrive)

local function proced(set, new)
  print("Volume in drive " .. currentdrive .. " is \"" .. (currentlabel or "nil") .. "\"")
  print("Volume serial number is " .. driveaddr:sub(1,6))
  if set then
    if new then
      fs.setLabel(currentdrive, new)
      print("Set volume label to \"" .. new .. "\"")
    else
      write("Enter a new label for drive " .. currentdrive .. " (ENTER for none): ")
      local new = read()
      if new == "" then
        print("Label unchanged")
      else
        fs.setLabel(currentdrive, new)
        print("Set volume label to " .. new)
      end
    end
  end
end

if #args < 1 then
  proced(true)
elseif #args < 2 then
  checkArg(1, args[1], "string")
  currentdrive = args[1]
  currentlabel = fs.getLabel(currentdrive)
  driveaddr = fs.getAddress(currentdrive)
  proced(false)
else
  checkArg(1, args[1], "string")
  checkArg(2, args[2], "string")
  currentdrive = args[1]
  currentlabel = fs.getLabel(currentdrive)
  driveaddr = fs.getAddress(currentdrive)
  local newlabel = args[2]
  proced(true, newlabel)
end
