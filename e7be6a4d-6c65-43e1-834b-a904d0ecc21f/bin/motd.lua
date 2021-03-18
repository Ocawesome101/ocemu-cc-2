-- It's complicated. Not really. -- 

local motds = require("motd/motdlist")

local motd = motds[math.random(1,#motds)]

print(("-"):rep(16))
print(motd)
print(("-"):rep(16))
