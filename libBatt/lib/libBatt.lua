local battery  = {}
local component = require("component")

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
  -- TODO: Make ratio user configurable, since CEu supports custom ones
  if convertPowerType == "EU" and battery.list[addr] == "RF" then
    return power / 4
  elseif convertPowerType == "RF" and battery.list[addr] == "EU" then
    return power * 4
  end

  return power
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

function battery.getSinkTier(addr)
  local proxy, addr = selectBattery(addr)

  --default to 0 if a RF based compoment
  if battery.list[addr] == "RF" then return 0 end

  local tier = proxy.getSinkTier()
  return tier
end

battery.refresh()
return battery
