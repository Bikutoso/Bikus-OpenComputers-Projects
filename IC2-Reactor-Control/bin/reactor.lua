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
local reactor = {
  state = "Stopped",
  tick = false,
  output = 0,
  heat = {
    current = 0,
    max = cmpReactor.getMaxHeat(),
    critical = cmpReactor.getMaxHeat() * env.reactorCriticalLimit,
    limit = cmpReactor.getMaxHeat() * env.reactorUpperLimit,
    low = cmpReactor.getMaxHeat() * env.batteryLowerLimit
  },
  protect = {
    count = 0
  }
}

local battery = {
  current = 0,
  max = batt.getMaxEnergyStored(),
  high = batt.getMaxEnergyStored() * env.batteryUpperLimit,
  low = batt.getMaxEnergyStored() * env.batteryLowerLimit
}

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
  if reactor.state == "Hot" then
    gpu.setForeground(0xFFFF00)
    gpu.setBackground(0xFF0000)
    status = "Stopped (Thermal Overload)"
  elseif reactor.state == "Batt" then
    gpu.setForeground(0xFFFF00)
    status = "Stopped (Battery Full)"
  elseif reactor.state == "Running" then
    gpu.setForeground(0x00FF00)
    status = "Running"
  else
    gpu.setForeground(0xFFFF00)
    status = "Stopped"
  end
  gpu.set(10,4, status)
  gpu.setForeground(0xFFFFFF)
  gpu.setBackground(0x000000)

  local safety = "Unknown"
  if env.reactorOverheatProtection then
    if reactor.protect.count >= env.reactorOverheatMaxCount - 2 then
      gpu.setForeground(0xFF0000)
    end
    safety = reactor.protect.count.."/"..env.reactorOverheatMaxCount
  else
    gpu.setForeground(0xFF0000)
    safety = "Disabled"
  end
  gpu.set(10,5, safety)
  gpu.setForeground(0xFFFFFF)
  
  local heat = misc.format_thousand(reactor.heat.current).."/"..misc.format_thousand(reactor.heat.max)
  .." (Limit: "..misc.format_thousand(reactor.heat.limit)..")"
  gpu.set(10,7, heat)
  
  local output = misc.format_thousand(reactor.output).." RF/t"
  gpu.set(10,8, output)
  
  local bat = misc.format_thousand(battery.current).."/"..misc.format_thousand(battery.max)
  .." RF (High: "..misc.format_thousand(battery.high)..",  Low: "..misc.format_thousand(battery.low)..")"
  gpu.set(10,10, bat)
end

local function RecError(msg)
  cmpRedstone.setOutput(sides[env.redstoneSide], 0)
  reactor.state = "Critical"

  gpu.setBackground(0xFF0000)
  gpu.setForeground(0xFFFF00)
  print("===CRITICAL===")
  print("Reactor Shutdown!!")
  print("Reason: "..msg)

  os.exit(1)
end

local function increaseProtect()
  reactor.protect.count = reactor.protect.count + 1
  
  if reactor.protect.count >= env.reactorOverheatMaxCount then
    RecError("Abnormal temperature. Shutdown down for safety")
  end
end

local function checkHeat()
  reactor.heat.current = cmpReactor.getHeat()

  
  if reactor.heat.current > reactor.heat.critical then -- Reactor Hard Limit
    RecError("Reactor temperature "..reactor.heat.current.."/"..reactor.heat.max)
  elseif reactor.state == "Running" and reactor.heat.current > reactor.heat.limit then -- Reactor Soft Limit
    cmpRedstone.setOutput(sides[env.redstoneSide], 0)
    reactor.state = "Hot"
    -- Overheat Protection (if enabled)
    if env.reactorOverheatProtection then increaseProtect() end
  elseif status == "Hot" and reactor.heat.current < reactor.heat.low then
    reactor.state = "Running"
  end

end

local function checkBatt()
  battery.current = batt.getEnergyStored()
  if reactor.state == "Running" and battery.current > battery.high then -- Battery High
    reactor.state = "Batt"
  elseif reactor.state == "Batt" and battery.current < battery.low then -- Battery Low
    reactor.state = "Running"
  end
end

local function flopReactor()
  reactor.tick = not reactor.tick
  cmpRedstone.setOutput(sides[env.redstoneSide], reactor.tick and 15 or 0)
end

-- Reset redstone to a default reactor.state
cmpRedstone.setOutput(sides[env.redstoneSide], 0)

initScreen()
reactor.state = "Running"
while true do

  checkHeat()
  checkBatt()
 
  -- Startup
  if reactor.state == "Running" then
    flopReactor()
  end

  reactor.output = cmpReactor.getReactorEUOutput() * 4

  updateScreen()
  os.sleep(0.1)
end
