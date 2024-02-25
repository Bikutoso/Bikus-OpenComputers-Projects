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

-- Power Types
-- ===========
-- RF: RF/FE
-- GT: GregTech CEu
-- IC: IndustrialCraft 2

local getEnergyStoredMethods = {
  RF = "getEnergyStored",
  GT = "getEnergyStored",
  IC = "getEnergy"
}
local getMaxEnergyStoredMethods = {
  RF = "getMaxEnergyStored",
  GT = "getEnergyCapacity",
  EU = "getCapacity"
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
  if convertPowerType == "EU" and battery.list[addr] == "RF" then
    return power / 4
  elseif convertPowerType == "RF" and battery.list[addr] == "EU" then
    return power * 4
  end

  return power
end

local function isType(addr, type)
  return battery.list[addr] == type and 1 or 0
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


    if devicemethods["getMaxEnergyStored"] ~= nil then
      battery.list[addr] = "RF"
    elseif devicemethods["getEnergyStored"] ~= nil then
      battery.list[addr] = "GT"
    elseif devicemethods["getEnergy"] ~= nil then
      battery.list[addr] = "IC"
    end
  end

  if battery.address == nil then
    battery.address, _ = next(battery.list)
    if battery.address == nil then error("No batteries connected") end
  end
  
  return battery.address
end

function battery.convert(type)
  if type == "RF" then convertPowerType = "RF"
  elseif type == "EU" then convertPowerType = "EU"
  else convertPowerType = nil end
  return convertPowerType
end

function battery.getUnit(addr)
  if convertPowerType ~= nil then
    return convertPowerType
  end

  local _, addr = selectBattery(addr)
  return battery.list[addr]
  
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

function battery.getEnergyStored(addr, side)
  local proxy, addr = selectBattery(addr)
  local power = proxy[getEnergyStoredMethods[battery.list[addr]]](side)
  return convertPower(addr, power)
end

function battery.getMaxEnergyStored(addr, side)
  local proxy, addr = selectBattery(addr)
  local power = proxy[getMaxEnergyStoredMethods[battery.list[addr]]](side)
  return convertPower(addr, power)
end

-- Mod Specific Functions
-- ======================

-- IC2
function battery.IC2.getSinkTier(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end
  
  return proxy.getSinkTier()
end

-- GregTech CEu
function battery.GT.getInputAmperage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end
  
  return proxy.getInputAmperage()
end

function battery.GT.getInputPerSec(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end

  return proxy.getInputPerSec()
end

function battery.GT.getInputVoltage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end

  return proxy.getInputVoltage()
end

function battery.GT.getOutputAmperage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end

  return proxy.getOutputAmperage()
end

function battery.GT.getOutputPerSec(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end

  return proxy.getOutputPerSec()
end

function battery.GT.getOutputVoltage(addr)
  local proxy, addr = selectBattery(addr)
  if not isType(addr, "IC") then return 0 end

  return proxy.getOutputVoltage()
end

function battery.GT.getCover(addr)
  local proxy, addr = selectBattery(addr, side)
  if not isType(addr, "IC") then return 0 end

  return proxy.getCover(side)
end

battery.refresh()
return battery
