-- cd --

local args = {...} 

if #args < 1 then
  shell.setPwd("/")
else
  local newPwd = shell.resolvePath(args[1])
  if fs.exists(newPwd) and fs.isDirectory(newPwd) then
    shell.setPwd(newPwd)
  else
    error(args[1] .. " is not a directory")
  end
end
