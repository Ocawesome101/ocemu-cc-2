-- A term API very similar to ComputerCraft's. --

-- GPU and screen proxies --
_G.gpu = component.list("gpu")()
local screen = component.list("screen")()

component.invoke(gpu, "bind", screen)
gpu = component.proxy(gpu)

local w,h = gpu.maxResolution()
local x,y = 1,1
gpu.setResolution(w,h)
local cursorVisible = false

local pullSignal = computer.pullSignal
local function update() -- Force a screen refresh
  pullSignal(0)
end

_G.term = {}

term.connectedGPUs = {}

function term.clearLine()
  gpu.set(1,y,(" "):rep(w))
  update()
end

function term.clear()
  gpu.fill(1,1,w,h," ")
  update()
end

function term.getCursorPos()
  return x, y
end

function term.setCursorPos(newX,newY)
  if type(newX) == "number" and type(newY) == "number" then
    x = newX
    y = newY
  else
    return
  end
end

function term.getBackgroundColor()
  return gpu.getBackground()
end

function term.setBackgroundColor(color)
  return gpu.setBackground(color)
end

function term.getTextColor()
  return gpu.getForeground()
end

function term.setTextColor(color)
  return gpu.setForeground(color)
end

term.getPaletteColor = gpu.getPaletteColor
term.setPaletteColor = gpu.setPaletteColor

function term.isColor() -- Returns true or false and the color depth
  local depth = gpu.maxDepth()
  if depth == 1 then
    return false, 1
  else
    return true, depth
  end
end

function term.setSize(newW,newH)
  if type(newW) == "number" and type(newH) == "number" then
    return gpu.setResolution(newW, newH)
  end
end

function term.getSize()
  local w,h = gpu.getResolution()
  return w,h
end

function term.maxSize()
  return gpu.maxResolution()
end

function term.write(str)
  gpu.set(x,y,str)
  x = x + #str
end

function term.disableGPU(addr) -- Mostly called by the event library when a GPU is removed from the system
  if gpuAddress == addr then
    gpu = {
      set = function()end,
      maxResolution = function()return 1,1 end,
      setResolution = function()end,
      getResolution = function()return 1,1 end,
      maxDepth = function()return 1 end,
      getDepth = function()return 1 end,
      setDepth = function()end,
      setPaletteColor = function()end,
      getPaletteColor = function()end,
      setForeground = function()end,
      getForeground = function()end,
      fill = function()end
    }
  end
end

function term.enableGPU(addr)
  if gpu.maxResolution() == 1 then -- If we don't have a primary GPU, add one
    gpu = component.proxy(addr)
  else
    for i=1, #term.connectedGPUs, 1 do
      if term.connectedGPUs[i].address then
        if term.connectedGPUs[i].address() == addr then
          return true
        end
      end
    end
    table.insert(term.connectedGPUs, component.proxy(addr))
  end
end

function term.scroll()
  gpu.copy(1,2,w,h-1,0,-1)
  gpu.fill(1,h,w,1," ")
  update()
end

function term.update()
  update()
end
