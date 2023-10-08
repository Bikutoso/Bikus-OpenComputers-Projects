local component = require("component")
local batt = require("libBatt")
local misc = require("libKitsune")
local math = require("math")
local os = require("os")
local sides = require("sides")

--
-- Setup Components
--
local env = misc.loadConfig("/etc/reactor.cfg")
local gpu = component.gpu
local cmpRedstone = component.proxy(env.redstoneAddress)
if cmpRedstone == nil then error("Invalid or missing redstone I/O") end

local cmpReactor = nil
if component.isAvailable("reactor") then
  cmpReactor = component.reactor
elseif component.isAvailable("reactor_chamber") then
  cmpReactor = component.reactor_chamber
else
  error("No reactors found")
end

batt.convert("RF")

--
-- Variables
--
local recRunning = false
local recHot = false
local recHotCount = 0
local recFlop = false
local recCur = 0
local recMax = cmpReactor.getMaxHeat()
local recLimit = math.floor(recMax * env.reactorUpperLimit)
local recLow = math.floor(recMax * 0.01)
local recOutput = 0
local batFull = false
local batCur = 0
local batMax = batt.getMaxEnergyStored()
local batUpper = math.floor(batMax * env.batteryUpperLimit)
local batLower = math.floor(batMax * env.batteryLowerLimit)
local termWidth, termHeight = gpu.getResolution()

local function initScreen ()
  gpu.fill(1, 1, termWidth, termHeight, " ")
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x000000)
  
  gpu.set(1,2, "IC2 Reactor Control (by Bikutoso)")
  
  gpu.set(1,3, string.rep("=", termWidth))
  gpu.set(1,4, "Status:  Unknown")
  gpu.set(1,5, "Safety:  Unknown")
  
  gpu.set(1,7, "Reactor: 0/0 (Limit: 0)")
  gpu.set(10,8, "0 EU/t")
  
  gpu.set(1,10, "Battery: 0/0 (High: 0, Low: 0)")
end

local function updateScreen()
  --clear screen
  gpu.fill(10, 4, termWidth, 7, " ")
  --gpu.fill(10, 10, termWidth, 1, "%")

  local status = "Unknown"
  if recHot then
    gpu.setForeground(0xFFFF00)
    gpu.setBackground(0xFF0000)
    status = "Stopped (Thermal Overload)"
  elseif batFull then
    gpu.setForeground(0xFFFF00)
    status = "Stopped (Battery Full)"
  elseif recRunning then
    gpu.setForeground(0x00FF00)
    status = "Running"
  end
  gpu.set(10,4, status)
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x000000)

  local safety = "Unknown"
  if env.reactorOverheatProtection then
    if recHotCount >= env.reactorOverheatMaxCount - 2 then
      gpu.setForeground(0xFF0000)
    end
    safety = recHotCount.."/"..env.reactorOverheatMaxCount
  else
    gpu.setForeground(0xFF0000)
    safety = "Disabled"
  end
  gpu.set(10,5, safety)
  gpu.setForeground(0xFFFFFF)
  
  local heat = misc.format_thousand(recCur).."/"..misc.format_thousand(recMax)
  .." (Limit: "..misc.format_thousand(recLimit)..")"
  gpu.set(10,7, heat)
  
  local output = misc.format_thousand(recOutput).." RF/t"
  gpu.set(10,8, output)
  
  local bat = misc.format_thousand(batCur).."/"..misc.format_thousand(batMax)
  .." RF (High: "..misc.format_thousand(batUpper)..",  Low: "..misc.format_thousand(batLower)..")"
  gpu.set(10,10, bat)
end

local function RecError(msg)
  cmpRedstone.setOutput(sides[env.redstoneSide], 0)
  recRunning = false

  gpu.setBackground(colors.red, true)
  gpu.setForeground(colors.yellow, true)
  print("===CRITICAL===")
  print("Reactor Shutdown!!")
  print("Reason: "..msg)

  os.exit(1)
end

local function checkHeat()
  recCur = cmpReactor.getHeat()
  
  if recCur > math.floor(recMax * 0.8) then -- Reactor Hard Limit
    RecError("Reactor temperature "..recCur.."/"..recMax)
  elseif recCur > recLimit and recRunning then -- Reactor Soft Limit
    cmpRedstone.setOutput(sides[env.redstoneSide], 0)
    if recRunning then
    end
    recRunning = false
    recHot = true

    -- Overheat Protection (if enabled)
    if env.reactorOverheatProtection and recHotCount >= env.reactorOverheatMaxCount - 1 then
      RecError("Abnormal temperature. Shutting down for safety")
    elseif env.reactorOverheatProtection then
      recHotCount = recHotCount + 1
    end
  elseif recHot and recCur < recLow then -- Reactor Cooled off
      recHot = false
  end
end

local function checkBatt()
  batCur = batt.getEnergyStored()
  if not batFull and batCur > batUpper then -- Battery High
    recRunning = false
    batFull = true
  elseif batFull and batCur < batLower then -- Battery Low
    batFull = false
  end
end

local function flopReactor()
  recFlop = not recFlop
  cmpRedstone.setOutput(sides[env.redstoneSide], recFlop and 15 or 0)
end

-- Reset redstone to a default state
cmpRedstone.setOutput(sides[env.redstoneSide], 0)

initScreen()
while true do

  checkHeat()
  checkBatt()
 
  -- Startup
  if not recHot and not batFull then
    if not recRunning then
      recRunning = true
    end
    flopReactor()
  end

  recOutput = cmpReactor.getReactorEUOutput() * 4

  updateScreen()
  os.sleep(0.1)
end
