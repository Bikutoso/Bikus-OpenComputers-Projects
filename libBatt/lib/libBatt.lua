local component = require("component")

-- Modules
local battery  = {}
battery.IC2 = {}
battery.GT = {}

-- Variables
list = {}
address = nil
local manualAddress = false
local convertPowerType = nil

-- Power Name, Unit, StoredPower, MaxPower
local PowerTypes = {
  ["Redstone Flux"] = {"RF", "getEnergyStored", "getMaxEnergyStored"},
  ["GregTech 5 EU"] = {"EU", "getEUStored", "getEUMaxStored"},
  ["GregTech CEu EU"] = {"EU", "getEnergyStored", "getEnergyCapacity"},
  ["IndustrialCraft 2 EU"] = {"EU", "getEnergy", "getCapacity"},
  ["IndustrialCraft 2 EU (GTNH)"] = {"EU", "getStored", "getCapacity"}
}

-- Interal Functions
-- =================
local function selectBattery(addr)
  --If address is slected use that, otherwise select the default
  local manAddr = true
  if addr == nil then
    addr = battery.address
    manAddr = false
  end
  
  local proxy = component.proxy(addr)
  --Components could be out of date refresh
  if not manAddr and proxy == nil then
    addr = battery.refresh()
    proxy = component.proxy(addr)
  elseif proxy == nil then
    error("Invalid address: "..addr)
  end
  
  return proxy, addr
end

local function convertPower(addr, power)
  -- TODO: Make ratio user configurable, since CEu supports user set ones
  pType = battery.getUnit(addr)
  if convertPowerType == "EU" and battery.list[addr][1] == "RF" then
    return power / 4
  elseif convertPowerType == "RF" and battery.list[addr][1] == "EU" then
    return power * 4
  end

  return power
end

local function isType(addr, type)
  if battery.getUnit(addr) == type then
    print("true")
    return true
  end
  print("false")
  return false
end

-- HACK: With how stupid GT5 handles battery buffers count each battery
local function getBattPower(addr, method)
  local curCount = 0
  local newCount = 0
  for iBatt = 1, 16, 1 do
    newCount = component.invoke(addr, method, iBatt)
    if newCount == nil then
      break
    end

    curCount = curCount + newCount
  end
  return curCount
end

-- Universal Functions
-- ===================

function battery.refresh()
  -- Reset
  battery.list = {}
  if manualAddress and component.proxy(battery.address) == nil then
      manualAddress = false
  end
  
  if not manualAddress then
    battery.address = nil
  end

  local devices = component.list()
  for addr, _ in pairs(devices) do
    devicemethods = component.methods(addr)
    for _, pType in pairs(PowerTypes) do
      if devicemethods[pType[2]] ~= nil and devicemethods[pType[3]] ~= nil then
        battery.list[addr] = pType
        break
      end
    end
  end

  if battery.address == nil then
    battery.address, _ = next(battery.list)
    if battery.address == nil then error("No batteries connected") end
  end

  battery.convert(battery.getUnit(battery.address))
  return battery.address
end

function battery.convert(type)
  if type == "RF" then convertPowerType = "RF"
  elseif type == "EU" then convertPowerType = "EU" end
  return convertPowerType
end

function battery.setPrimary(addr)
  if battery.list[addr] ~= nil then
    battery.address = addr
    manualAddress = true
  elseif addr == nil then
    manualAddress = false
    battery.refresh()
  end
  return battery.address
end

function battery.getUnit(addr)
  return battery.list[addr][1]
end

function battery.getEnergyStored(addr, side)
  local proxy, addr = selectBattery(addr)
  local power = 0
  if component.methods(addr)["getBatteryCharge"] == nil then
    power = proxy[battery.list[addr][2]](side)
  else
    power = getBattPower(addr, "getBatteryCharge")
  end
  return convertPower(addr, power)
end

function battery.getMaxEnergyStored(addr, side)
  local proxy, addr = selectBattery(addr)
  local power = 0
  if component.methods(addr)["getMaxBatteryCharge"] == nil then
    power = proxy[battery.list[addr][3]](side)
  else
    power = getBattPower(addr, "getMaxBatteryCharge")
  end

  return convertPower(addr, power)
end

-- Mod Specific Functions
-- ======================

-- IC2
function battery.IC2.getSinkTier(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end
  
  return proxy.getSinkTier()
end

-- GregTech CEu
-- TODO: Make Generic between CEu and GT5
function battery.GT.getInputAmperage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end
  
  return proxy.getInputAmperage()
end

function battery.GT.getInputPerSec(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end

  return proxy.getInputPerSec()
end

function battery.GT.getInputVoltage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end

  return proxy.getInputVoltage()
end

function battery.GT.getOutputAmperage(addr)
 local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end

  return proxy.getOutputAmperage()
end

function battery.GT.getOutputPerSec(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end

  return proxy.getOutputPerSec()
end

function battery.GT.getOutputVoltage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "EU") then return 0 end

  return proxy.getOutputVoltage()
end

function battery.GT.getCover(addr)
  local proxy, addr = selectBattery(addr, side)
  if not isType(addr, "EU") then return 0 end

  return proxy.getCover(side)
end

battery.refresh()
return battery
