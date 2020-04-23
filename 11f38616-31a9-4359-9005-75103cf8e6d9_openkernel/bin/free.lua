print("Used:", tostring((computer.totalMemory() - computer.freeMemory()) / 1024):sub(1,4) .. "k", "/", tostring(computer.totalMemory()/1024) .. "k")
