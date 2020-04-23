-- A lua interpreter --

local args = {...} 

if #args > 1 then
  dofile(args[1])
  return
end

term.setTextColor(colors.yellow)
print(_VERSION)

local exit = false
local env = {}

function env.exit()
  exit = true
end

setmetatable(env, {__index=_ENV})

while not exit do
  term.setTextColor(colors.yellow)
  write("> ")
  local exec = read()
  local ok, err = load(exec, "=lua", "t", env)
  if not ok then
    printError(err)
  else
    if ok then
      local ok, err = pcall(ok)
      if not ok then
        printError(err)
      else
        print(err)
      end
    end
  end
end
