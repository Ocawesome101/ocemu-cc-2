-- Better tables --

function table.new(...)
  local returnTable = {...} or {}
  return setmetatable(returnTable, {__index=table}) --Why this isn't just done by default for all tables I have no idea.
end

function table.copy(tbl)
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end
  return rtn
end
