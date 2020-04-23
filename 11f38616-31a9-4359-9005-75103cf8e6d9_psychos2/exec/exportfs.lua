local rpcs = require "rpc"
local ufs = require "unionfs"

local tA = {...}
local path = "/"..table.concat(fs.segments(tA[1]),"/")

local px = ufs.create(path)
for k,v in pairs(px) do
 rpcs.register(path.."_"..k,v)
 print(path.."_"..k)
end
