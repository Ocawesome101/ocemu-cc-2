 -- Erroring stuff --

function printError(err)
  local oldColor = term.getTextColor()
  term.setTextColor(colors.red)
  print(err)
  term.setTextColor(oldColor)
end

function error(err)
  printError(err)
end
