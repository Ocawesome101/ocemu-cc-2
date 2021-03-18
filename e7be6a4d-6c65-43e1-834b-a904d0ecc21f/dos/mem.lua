-- Free / used / total memory --

local args, options = cmd.parse(...)

local w,h = term.getSize()

local sep1 = "  "
local sep2 = " "

local used  = math.floor((dos.totalMemory() - dos.freeMemory()) / 1024)
local total = math.floor(dos.totalMemory() / 1024)
local free  = math.floor(total - used)

if total >= 1000 then
  sep1 = " "
end

if used >= 1000 then
  sep2 = ""
end

if used < 100 then
  sep2 = "  "
end

print("Memory type   Total = Used + Free")
print("--------------   -----   ----   ----")
print("Conventional    ", tostring(total) .. "k", sep1, tostring(used) .. "k", sep2, tostring(free) .. "k")
print("--------------   -----   ----   ----")
print("Total memory    ", tostring(total) .. "k", sep1, tostring(used) .. "k", sep2, tostring(free) .. "k")
