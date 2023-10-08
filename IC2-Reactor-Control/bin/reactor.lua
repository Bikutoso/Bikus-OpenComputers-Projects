local component = require("component")
local sides = require("sides")
local colors = require("colors")
local os = require("os")
local math = require("math")

--
-- Config
--

-- Reactor Redstone
local cfgRedAddr = "1cfe82dc-4a53-4f58-b311-0b21ef815135"
local cfgRedSide = sides.left
-- Reactor Controller
local cfgRecUpLimit = 0.2
local cfgRecOverheatProtect = true
local cfgRecOverheatMaxCount = 4
-- Battery
-- 
local cfgBatComponent = "energy_device"
local cfgBatType = "RF" -- IC2, RF
local cfgBatUpLimit = 0.9
local cfgBatLowLimt= 0.1

--
-- Setup Components
--
local gpu = component.gpu
local cmpRedstone = component.proxy(cfgRedAddr)
local cmpReactor = component.reactor
local cmpBattery = component[cfgBatComponent]

if cfgBatType == "IC2" then
  --print("IC")
  cmpBatteryStored = "getEnergy"
  cmpBatteryMax = "getCapacity"
elseif cfgBatType == "RF" then
  --print("RF")
  cmpBatteryStored = "getEnergyStored"
  cmpBatteryMax = "getMaxEnergyStored"
end

--
-- Variables
--
local recRunning = false
local recHot = false
local recHotCount = 0
local recFlop = false
local recCur = 0
local recMax = cmpReactor.getMaxHeat()
local recLimit = math.floor(recMax * cfgRecUpLimit)
local recLow = math.floor(recMax * 0.01)
local recOutput = 0
local batFull = false
local batCur = 0
local batMax = cmpBattery[cmpBatteryMax]()
local batUpper = math.floor(batMax * cfgBatUpLimit)
local batLower = math.floor(batMax * cfgBatLowLimt)
local termWidth, termHeight = gpu.getResolution()

local function initScreen ()
  gpu.fill(1, 1, termWidth, termHeight, " ")
  gpu.setForeground(colors.white, true)
  gpu.setBackground(colors.black, true)
  
  gpu.set(1,2, "IC2 Reactor Control (by Bikutoso)")
  
  gpu.set(1,3, string.rep("=", termWidth))
  gpu.set(1,4, "Status:  Unknown")
  gpu.set(1,5, "Safety:  Unknown")
  
  gpu.set(1,7, "Reactor: 0/0 (Limit: 0)")
  gpu.set(10,8, "0 EU/t")
  
  gpu.set(1,10, "Battery: 0/0 (High: 0, Low: 0)")
end

local function updateScreen ()
  --clear screen
  gpu.fill(10, 4, termWidth, 7, " ")
  --gpu.fill(10, 10, termWidth, 1, "%")

  local status = "Unknown"
  if recHot then
    gpu.setForeground(colors.yellow, true)
    gpu.setBackground(colors.red, true)
    status = "Stopped (Thermal Overload)"
  elseif batFull then
    gpu.setForeground(colors.yellow, true)
    status = "Stopped (Battery Full)"
  elseif recRunning then
    gpu.setForeground(colors.green, true)
    status = "Running"
  end
  gpu.set(10,4, status)
  gpu.setBackground(colors.black, true)
  gpu.setForeground(colors.white, true)

  local safety = "Unknown"
  if cfgRecOverheatProtect then
    if recHotCount >= cfgRecOverheatMaxCount - 2 then
      gpu.setForeground(colors.red, true)
    end
    safety = recHotCount.."/"..cfgRecOverheatMaxCount
  else
    gpu.setForeground(colors.red, true)
    safety = "Disabled"
  end
  gpu.set(10,5, safety)
  gpu.setForeground(colors.white, true)
  
  local heat = recCur.."/"..recMax.." (Limit: "..recLimit..")"
  gpu.set(10,7, heat)
  
  local output = recOutput.." EU/t"
  gpu.set(10,8, output)
  
  local bat = math.floor(batCur).."/"..math.floor(batMax).." (High: "..batUpper..",  Low: "..batLower..")"
  gpu.set(10,10, bat)
end

local function RecError (msg)
  cmpRedstone.setOutput(cfgRedSide, 0)
  recRunning = false
  
  gpu.setBackground(colors.red, true)
  gpu.setForeground(colors.yellow, true)
  print("===CRITICAL===")
  print("Reactor Shutdown!!")
  print("Reason: "..msg)

  os.exit(1)
end

local function checkHeat ()
  recCur = cmpReactor.getHeat()
  
  if recCur > math.floor(recMax * 0.8) then -- Reactor Hard Limit
    RecError("Reactor temperature "..recCur.."/"..recMax)
  elseif recCur > recLimit and recRunning then -- Reactor Soft Limit
    cmpRedstone.setOutput(cfgRedSide, 0)
    if recRunning then
    end
    recRunning = false
    recHot = true

    -- Overheat Protection (if enabled)
    if cfgRecOverheatProtect and recHotCount >= cfgRecOverheatMaxCount - 1 then
      RecError("Abnormal temperature. Shutting down for safety")
    elseif cfgRecOverheatProtect then
      recHotCount = recHotCount + 1
    end
  elseif recHot and recCur < recLow then -- Reactor Cooled off
      recHot = false
  end
end

local function checkBatt ()
  batCur = cmpBattery[cmpBatteryStored]()
  if not batFull and batCur > batUpper then -- Battery High
    recRunning = false
    batFull = true
  elseif batFull and batCur < batLower then -- Battery Low
    batFull = false
  end
end

local function flopReactor ()
  recFlop = not recFlop
  cmpRedstone.setOutput(cfgRedSide, recFlop and 15 or 0)
end

-- Reset redstone to a default state
cmpRedstone.setOutput(cfgRedSide, 0)

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

  recOutput = cmpReactor.getReactorEUOutput()

  updateScreen()
  os.sleep(0.1)
end
