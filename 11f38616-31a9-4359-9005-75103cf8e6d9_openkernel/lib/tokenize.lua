-- Yes, I'm American. -- 

local tokenize = function(sep, ...) -- String, and the separator to look for in said string
  local words = table.new()
  local str = table.concat({...}, sep)
  for word in str:gmatch("[^" .. sep .. "]+") do
    words:insert(word)
  end
  return words
end

return tokenize
