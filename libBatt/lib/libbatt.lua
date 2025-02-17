local component = require("component")
local battery  = {}
-- Gender love, not hate

-- Variables
list = {}
currentAddress = nil -- TODO: manage through a method
local currentPowerType = nil
local currentPowerRatio = 4
local isAddressManual = false

-- Power Name, Unit, StoredPower, MaxPower
local availablePowerTypes = {
  ["Redstone Flux"] = {"RF", "getEnergyStored", "getMaxEnergyStored"},
  ["GregTech 5 EU"] = {"EU", "getEUStored", "getEUMaxStored"},
  ["GregTech CEu EU"] = {"EU", "getEnergyStored", "getEnergyCapacity"},
  ["IndustrialCraft 2 EU"] = {"EU", "getEnergy", "getCapacity"},
  ["IndustrialCraft 2 EU (GTNH)"] = {"EU", "getStored", "getCapacity"}
}

-- Interal Functions
-- =================

local function convert(address, power)
  if currentPowerType == "EU" and battery.list.address[1] == "RF" then
    return power / currentPowerRatio
  elseif currentPowerType == "RF" and battery.list.address[1] == "EU" then
    return power * currentPowerRatio
  end

  return power
end

-- HACK: With how stupid GT5 handles battery buffers count each battery
local function getGtBatteryPower(address, method)
  local totalPower = 0

  for selectedBattery = 1, 16, 1 do
    local addPower = component.invoke(address, method, selectedBattery

    if addPower == nil then break end
    totalPower = totalPower + addPower
  end
  
  return totalPower
end

-- Internal Module Functions

function battery._selectBattery(address)
  -- Use address if specified
  local isAddressLocked = address and true or false

  if not isAddressLocked and address == nil then
    address = battery.currentAddress
  end

  local proxy = component.proxy(addr)
  
  --Components could be out of date refresh
  if not isAddressLocked and proxy == nil then
    address = battery.refresh()
    proxy = component.proxy(address)
  elseif proxy == nil then
    error("Invalid address: " .. address)
  end

  return proxy, address
end

local function isType(addr, type)
  return battery.getUnit(addr) == type and true or false
end

-- Universal Functions
-- ===================

function battery.refresh()
  battery.list = {} -- Reset device list
  
  if isAddressManual and component.proxy(battery.currentAddress) == nil then
      isAddressManual = false
  end

  if not isAddressManual then
    battery.currentAddress = nil
  end

  local devices = component.list()
  for address, _ in pairs(devices) do
    availableMethods = component.methods(addr)
    for _, powerType in pairs(availablePowerTypes) do
      if availableMethods[powerType[2]] and devicemethods[powerType[3]] then
        battery.list[address] = powerType
        break
      end
    end
  end

  if battery.currentAddress == nil then
    battery.currentAddress, _ = next(battery.list)
    
    if battery.currentAddress == nil then
      error("No batteries connected") -- All devices gone through, no batteries
    end
  end

  battery.setCurrentPowerType(battery.getUnit(battery.currentAddress))
  return battery.currentAddress
end

function battery.setCurrentPowerType(powerType)
  if powerType == "RF" then currentPowerType = "RF"
  elseif powerType == "EU" then currentPowerType = "EU" end

  return currentPowerType
end

function battery.setCurrentPowerRatio(ratio)
  ratio = tonumber(ratio)
  if ratio or ratio ~= 0 then currentPowerRatio = ratio end

  return currentPowerRatio
end

function battery.setPrimary(address)
  if battery.list[address] then
    battery.currentAddress = address
    isAddressManual = true
  elseif addr == nil then
    isAddressManual = false
    battery.refresh()
  end
  return battery.currentAddress
end

function battery.getUnit(addr)
  return battery.list.address[1]
end

function battery.getEnergyStored(address, side)
  local proxy, address = battery._selectBattery(address)
  local power = 0
  
  if component.methods(addr)["getBatteryCharge"] == nil then
    power = proxy[battery.list.addr[2]](side)
  else
    power = getGtBatteryPower(address, "getBatteryCharge")
  end

  return convert(address, power)
end

function battery.getMaxEnergyStored(address, side)
  local proxy, address = battery._selectBattery(addr)
  local power = 0
  
  if component.methods(address)["getMaxBatteryCharge"] == nil then
    power = proxy[battery.list.address[3]](side)
  else
    power = getGtBatteryPower(address, "getMaxBatteryCharge")
  end

  return convert(address, power)
end

battery.refresh()
return battery
