-- EEPROM flasher --

local args = {...} 

if #args < 1 then
  error("usage: eeprom <contents|flash> [<filename>] [<label>]")
  error("contents:    print the contents of the currently installed EEPROM")
  error("flash:       flash the specified file to an EEPROM")
  error("  filename:  file to flash")
  error("  label:     label to assign to the flashed EEPROM")
  return false
end

local function writeEEPROM(data, label)
  write("Insert the EEPROM you want to flash. Type Y when ready, N to cancel [y/N]: ")
  repeat
    local input = read()
    if input:lower() == "n" then
      error("Not flashing. Have a good day.")
      return false
    end
  until input:lower() == "y" or "n"
  local eeprom = component.list("eeprom")()
  if not eeprom then
    error("No EEPROM is currently in your system")
    return false
  end
  component.invoke(eeprom, "set", data)
  if not label then
    write("Enter a label for the EEPROM you have just flashed (current label is " .. component.invoke(eeprom, "getLabel") .. "): ")
    local input = read()
    component.invoke(eeprom, "setLabel", input)
  else
    component.invoke(eeprom, "setLabel", label)
  end
  print("Done.")
end

local function EEPROMData()
  local eeprom = component.list("eeprom")()
  print(component.invoke(eeprom, "get"))
end

if args[1] == "list" then
  EEPROMData()
elseif args[1] == "flash" then
  if fs.exists(args[2]) then
    local handle = fs.open(args[2], "r")
    local data = handle.readAll()
    handle.close()
    writeEEPROM(data, args[3])
  else
    error("Specified file does not exist")
  end
end
