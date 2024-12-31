battery = require("libbatt")
battery.ic2 = {}

-- TODO: Add guard clause for non IC2 batteries
function battery.ic2.getSinkTier(addr)
  local proxy, addr = battery._selectBattery(addr)
  
  return proxy.getSinkTier()
end

return battery.ic2
