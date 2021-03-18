-- dir -- 

local args, switches = cmd.parse(...)

local w,h = term.getSize()
local x,y = term.getCursorPos()

local dir = args[1] or cmd.pwd()

print("Volume in drive " .. fs.getDrive() .. " is " .. (fs.getLabel(fs.getDrive()) or "nil"))
print("Volume serial number is " .. fs.getAddress(fs.getDrive()):sub(1,6))

local function printFiles(tFiles)
  local linesPrinted = 3
  local files = #tFiles
  if switches.p then
    for i=1, #tFiles, 1 do
      if tFiles[i]:sub(1,1) ~= "." or switches.a then
        print(((fs.isDirectory(dir .. "/" .. tFiles[i]) and "<DIR> ") or "<FILE>"), tFiles[i])
        linesPrinted = linesPrinted + 1
        if linesPrinted+2 >= h then
          linesPrinted = 0
          print("Press any key to continue....")
          dos.pull("key_down")
          print("[Continuing " .. fs.concat(fs.getDrive(), dir) .. "]")
        end
      end
    end
  else
    for i=1, #tFiles, 1 do
      if tFiles[i]:sub(1,1) ~= "." or switches.a then
        print(((fs.isDirectory(dir .. "/" .. tFiles[i]) and "<DIR> ") or "<FILE>"), tFiles[i])
      end
    end
  end
  print("\n", tostring(files), "file(s)")
end

local files = fs.list(dir)

table.sort(files)

print("Directory of " .. fs.concat(fs.getDrive(), dir))

printFiles(files)
