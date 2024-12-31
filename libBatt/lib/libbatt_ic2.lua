battery = require("libbatt")
battery.ic2 = {}

-- TODO: Add guard clause for non IC2 batteries
function battery.ic2.getSinkTier(address)
  local proxy, address = battery._selectBattery(address)
  
  return proxy.getSinkTier()
end

return battery.ic2
