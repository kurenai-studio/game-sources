-- District registry. The module table IS the built District 07 map, so every
-- legacy require('game.map') field and dot-call helper keeps referring to
-- District 07 permanently; Map.get/Map.list select among the cached built-ins
-- without ever switching the default. Construction is deterministic and
-- consumes no randomness.
local build=require('game.maps.build')
local district07=require('game.maps.district07')
local waterfront=require('game.maps.waterfront')

local Map=build(district07)
local built={district07=Map}
built.waterfront=build(waterfront)

local order={built.district07,built.waterfront}

function Map.build(definition) return build(definition) end
function Map.get(id)
 local m=built[id]
 if m then return m end
 return nil,'unknown district id "'..tostring(id)..'"'
end
function Map.list()
 local out={}
 for _,m in ipairs(order) do out[#out+1]=m end
 return out
end

return Map
