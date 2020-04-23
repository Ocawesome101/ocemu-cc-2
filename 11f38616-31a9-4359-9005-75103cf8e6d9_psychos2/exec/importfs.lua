local rpc = require "rpc"
local tA = {...}
local host, rpath, lpath = tA[1], tA[2], tA[3]

local px = rpc.proxy(host,rpath.."_")
function px.getLabel()
 return host..":"..rpath
end
fs.mount(lpath,px)
