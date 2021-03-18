-- ls --

local args = {...}

local listDir = shell.pwd()

local fileColor = colors.white
local scriptColor = colors.green
local dirColor = colors.lightBlue

if #args >= 1 then
  listDir = args[1]
end

local files = fs.list(listDir)

table.sort(files)

for i=1, #files, 1 do
  if files[i]:sub(1,1) ~= "." or args[2] == "-a" then -- 'args[2] == "-a"' is a hack
    if fs.isDirectory(listDir .. "/" .. files[i]) then
      term.setTextColor(dirColor)
    elseif files[i]:sub(-4,-1) == ".lua" then
      term.setTextColor(scriptColor)
    else
      term.setTextColor(fileColor)
    end
    print(files[i])
  end
end
