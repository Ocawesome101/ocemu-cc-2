-- drives --

local drives = fs.drives()

for k,v in pairs(drives) do
  print(k)
end
