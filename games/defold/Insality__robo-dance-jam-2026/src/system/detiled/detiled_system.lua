local decore = require("decore.decore")

---@class entity
---@field name string?
---@field tiled_id number?
---@field tiled_layer_id string?
---@field image string?
---@field object_type string?
---@field polyline table?
---@field polygon table?
decore.register_component("name", "")
decore.register_component("tiled_id", 0)
decore.register_component("tiled_layer_id", "")
decore.register_component("image", "")
decore.register_component("object_type", "")
decore.register_component("polyline", {})
decore.register_component("polygon", {})

---@class system.detiled: system
local M = {}


---@return system.detiled
function M.create()
	return decore.system(M, "detiled")
end


return M
