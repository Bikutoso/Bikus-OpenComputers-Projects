local battery  = {}
local component = require("component")

battery.list = {}
battery.address = nil
local manualAddress = false

local getEnergyStoredMethods = {
  RF = "getEnergyStored",
  EU = "getEnergy"
}
local getMaxEnergyStoredMethods = {
  RF = "getMaxEnergyStored",
  EU = "getCapacity"
}

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

    if devicemethods["getEnergyStored"] ~= nil then
      battery.list[addr] = "RF"
    elseif devicemethods["getEnergy"] ~= nil then
      battery.list[addr] = "EU"
    end
  end

  if battery.address == nil then
    battery.address, _ = next(battery.list)
    if battery.address == nil then error("No batteries connected") end
  end
  
  return battery.address
end

function battery.setPrimary(addr)
  if battery.list[addr] ~= nil then
    battery.address = addr
    manualAddress = true
  elseif addr == nil then
    --Doesn't set a new address but allow a new one to be slected on refresh
    manualAddress = false
  end
  return battery.address, addr
end

function battery.getEnergyStored(addr)
  local proxy, addr = selectBattery(addr)
  local power = proxy[getEnergyStoredMethods[battery.list[addr]]]()
  return power
end

function battery.getMaxEnergyStored(addr)
  local proxy, addr = selectBattery(addr)
  local power = proxy[getMaxEnergyStoredMethods[battery.list[addr]]]()
  return power
end

function battery.getSinkTier(addr)
  local proxy, addr = selectBattery(addr)
  if battery.list[addr] == "RF" then return 0 end

  local tier = proxy.getSinkTier()
  return tier
end

battery.refresh()
return battery
