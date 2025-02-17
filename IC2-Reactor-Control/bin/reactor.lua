local component = require("component")
local misc = require("libKitsune")
local math = require("math")
local os = require("os")
local sides = require("sides")
-- Gender love, not hate

-- Early setup
local env, reason = misc.loadConfig("/etc/reactor.cfg")
if reason then error(reason) end

-- Setup variable tables and components
local gpu = component.gpu
local termWidth, termHeight = gpu.getResolution()

local reactor = {}
do
  local tmpreactor = nil
  if component.isAvailable("reactor") then
    tmpreactor = component.reactor
  elseif component.isAvailable("reactor_chamber") then
    tmpreactor = component.reactor_chamber
  else
    error("No reactors found")
  end
    
  reactor = {
    reactor = tmpreactor,
    redstone = component.proxy(env.reactor.redstone.address),
    state = "Stopped",
    tick = false,
    output = 0,
    heat = {
      current = 0,
      max = tmpreactor.getMaxHeat(),
      critical = tmpreactor.getMaxHeat() * env.reactor.limitCritical,
      limit = tmpreactor.getMaxHeat() * env.reactor.limitUpper,
      low = tmpreactor.getMaxHeat() * env.reactor.limitLower
    },
    protect = {
      count = 0
    }
  }

  -- Check if Redstone is avaiable
  if reactor.redstone == nil then
    error("Invalid or missing redstone I/O")
  end
end

local battery = {}
do
  tmpbatt = require("libBatt")
  battery = {
    battery = tmpbatt,
    current = 0,
    max = tmpbatt.getMaxEnergyStored(),
    high = tmpbatt.getMaxEnergyStored() * env.battery.limitUpper,
    low = tmpbatt.getMaxEnergyStored() * env.battery.limitLower
  }
end
battery.battery.convert("RF")

-- Screen related functions
local function setColor(fore, back)
  gpu.setForeground(fore)
  gpu.setBackground(back)
end

local function initScreen ()
  gpu.fill(1, 1, termWidth, termHeight, " ")
  setColor(0xFFFFFF, 0x000000)
  gpu.set(1,2, "IC2 Reactor Control (by Bikutoso)")

  gpu.set(1,3, string.rep("=", termWidth))
  gpu.set(1,4, "Status:  Unknown")
  gpu.set(1,5, "Safety:  Unknown")

  gpu.set(1,7, "Reactor: 0/0 (Limit: 0)")
  gpu.set(10,8, "0 EU/t")

  gpu.set(1,10, "Battery: 0/0 (High: 0, Low: 0)")
end

local function updateScreen()
  -- Clear screen
  gpu.fill(10, 4, termWidth, 7, " ")

  local status = "Unknown"
  if reactor.state == "Hot" then
    setColor(0xFFFF00, 0xFF0000)
    status = "Stopped (Thermal Overload)"
  elseif reactor.state == "Batt" then
    setColor(0xFFFF00, 0x000000)
    status = "Stopped (Battery Full)"
  elseif reactor.state == "Running" then
    setColor(0x00FF00, 0x000000)
    status = "Running"
  else
    setColor(0xFFFF00, 0x000000)
    status = "Stopped"
  end
  gpu.set(10,4, status)
  setColor(0xFFFFFF, 0x000000)

  local safety = "Unknown"
  if env.reactor.protection.enabled then
    if reactor.protect.count >= env.reactor.protection.maxCount - 2 then
      gpu.setForeground(0xFF0000)
    end
    safety = reactor.protect.count.."/"..env.reactor.protection.maxCount
  else
    setColor(0xFF0000, 0x000000)
    safety = "Disabled"
  end
  gpu.set(10,5, safety)
  setColor(0xFFFFFF, 0x000000)

  local heat = misc.format_thousand(reactor.heat.current).."/"..misc.format_thousand(reactor.heat.max)
  .." (Limit: "..misc.format_thousand(reactor.heat.limit)..")"
  gpu.set(10,7, heat)

  local output = misc.format_thousand(reactor.output).." RF/t"
  gpu.set(10,8, output)

  local bat = misc.format_thousand(battery.current).."/"..misc.format_thousand(battery.max)
  .." RF (High: "..misc.format_thousand(battery.high)..",  Low: "..misc.format_thousand(battery.low)..")"
  gpu.set(10,10, bat)
end

-- Battery related functions
local function batteryLevelCheck()
  if reactor.state == "Running" and battery.current > battery.high then -- Battery High
    reactor.state = "Batt"
  elseif reactor.state == "Batt" and battery.current < battery.low then -- Battery Low
    reactor.state = "Running"
  end
end

-- Reactor related functions

local function reactorOutput(value)
  reactor.redstone.setOutput(sides[env.reactor.redstone.side], value)
end

local function reactorTick()
  reactor.tick = not reactor.tick
  reactorOutput(reactor.tick and 15 or 0)
end

local function criticalError(msg)
  reactorOutput(0)
  reactor.state = "Critical"

  setColor(0xFFFF00, 0xFF0000)
  gpu.fill(1, 1, termWidth, termHeight, " ")
  print("===CRITICAL===")
  print("Reactor Shutdown!!")
  print("Reason: "..msg)

  os.exit(1)
end

local function reactorHeatProtect()
  reactor.protect.count = reactor.protect.count + 1

  if reactor.protect.count >= env.reactor.protection.maxCount then
    criticalError("Abnormal temperature. Shutdown down for safety")
  end
end

local function reactorHeatCheck()
  if reactor.heat.current > reactor.heat.critical then -- Reactor Hard Limit
    criticalError("Reactor temperature "..reactor.heat.current.."/"..reactor.heat.max)
  elseif reactor.state == "Running" and reactor.heat.current > reactor.heat.limit then -- Reactor Soft Limit
    reactorOutput(0)
    reactor.tick = false
    reactor.state = "Hot"
    -- Overheat Protection (if enabled)
    if env.reactor.protection.enabled then reactorHeatProtect() end
  elseif reactor.state == "Hot" and reactor.heat.current < reactor.heat.low then
    reactor.state = "Running"
  end
end

-- Final stuff before main loop
initScreen()
reactor.state = "Running"
while true do
  reactor.heat.current = reactor.reactor.getHeat()
  battery.current = battery.battery.getEnergyStored()
  reactor.output = reactor.reactor.getReactorEUOutput() * 4 -- to RF

  reactorHeatCheck()
  batteryLevelCheck()

  if reactor.state == "Running" then
    reactorTick()
  end

  updateScreen()
  os.sleep(0.1)
end
