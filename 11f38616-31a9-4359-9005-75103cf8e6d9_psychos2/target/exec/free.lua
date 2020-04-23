print("Total  Used  Free")
print(string.format("%4iK %4iK %4iK",math.floor(computer.totalMemory()/1024),math.floor((computer.totalMemory()-computer.freeMemory())/1024),math.floor(computer.freeMemory()/1024)))
