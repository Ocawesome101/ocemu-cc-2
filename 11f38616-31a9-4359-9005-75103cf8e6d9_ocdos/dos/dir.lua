-- dir -- 

local args, switches = cmd.parse(...)

local w,h = term.getSize()
local x,y = term.getCursorPos()

local dir = args[1] or cmd.pwd()

print("Volume in drive " .. fs.getDrive() .. " is " .. (fs.getLabel(fs.getDrive()) or "nil"))
print("Volume serial number is " .. fs.getAddress(fs.getDrive()):sub(1,6))

local function printFiles(tFiles)
  local linesPrinted = 2
  if switches.p then
    for i=1, #tFiles, 1 do
      print(tFiles[i])
      linesPrinted = linesPrinted + 1
      if linesPrinted+1 >= h then
        linesPrinted = 0
        print("Press any key to continue...")
        dos.pull("key_down")
      end
    end
  else
    for i=1, #tFiles, 1 do
      print(tFiles[i])
    end
  end
end

local files = fs.list(dir)

for i=1, #files, 1 do
  files[i] = files[i]
end

printFiles(files)
