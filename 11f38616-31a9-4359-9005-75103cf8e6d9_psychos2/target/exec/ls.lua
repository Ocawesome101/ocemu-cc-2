local tA = {...}
tA[1] = tA[1] or "."
for _,d in ipairs(tA) do
 if #tA > 1 then
  print(d..":")
 end
 for _,f in ipairs(fs.list(d)) do
  print(" "..f)
 end
end
