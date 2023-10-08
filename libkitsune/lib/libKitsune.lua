local math = require("math")

api = {}

-- OpenComputers Code
function api.loadConfig(filename)
  checkArg(1, filename, "string")
  local env = {}
  local result, reason = loadfile(filename, "t", env)
  if result then
    result, reason = xpcall(result, debug.traceback)
    if result then
      return env
    end
  end
  return nil, reason
end

--https://www.computercraft.info/forums2/index.php?/topic/8065-lua-thousand-separator
function api.format_thousand(value)
  local s = string.format("%d", math.floor(value))
  local pos = string.len(s) % 3
  if pos == 0 then pos = 3 end
  return string.sub(s, 1, pos)
  .. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
end

return api
