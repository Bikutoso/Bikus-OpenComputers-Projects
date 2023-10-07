local battery  = {}
local component = require("component")

battery.list = {}
battery.address = nil

function battery.refresh()
  -- Reset
  battery.list = {}
  battery.address = nil
  
  local devices = component.list()
  for addr, _ in pairs(devices) do
    devicemethods = component.methods(addr)

    if devicemethods["getEnergyStored"] ~= nil then
      battery.list[addr] = "RF"
      if battery.address == nil then battery.address = addr end
    elseif devicemethods["getEnergy"] ~= nil then
      battery.list[addr] = "EU"
      if battery.address == nil then battery.address = addr end
    end
  end

  return battery.address
end

function battery.getEnergyStored()
  -- TODO
  return 0
end
function battery.getMaxEnergyStored()
  -- TODO
  return 0
end

return battery
