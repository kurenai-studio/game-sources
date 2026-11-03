local decore = require("decore.decore")

local level_manager_command = require("system.level_manager.level_manager_command")
local transform_command = require("system.transform.transform_command")

---@class entity
---@field field_appear boolean|nil
---@field distance_to_player number|nil
---@field distance_to_finish number|nil

---@class entity.field_appear: entity
---@field field_appear boolean

decore.register_component("field_appear", false)

local SCALE_ZERO = vmath.vector3(0.0001, 0.0001, 1)
local SCALE_ONE = vmath.vector3(1, 1, 1)

---@class system.field_appear: system
---@field entities entity.field_appear[]
local M = {}


---@return system.field_appear
function M.create()
	return decore.system(M, "field_appear", { "field_appear", "game_object" })
end


---@param entity entity.field_appear
function M:onAdd(entity)
	entity.game_object.remove_delay = 0.6

	local root = entity.game_object.root
	local i, j = level_manager_command.get_ij(entity.transform.position_x, entity.transform.position_y)
	local delay = (8 - j) / 16
	go.set_scale(SCALE_ZERO, root)
	go.animate(root, "scale.xy", go.PLAYBACK_ONCE_FORWARD, SCALE_ONE, gui.EASING_OUTSINE, 0.15, delay)

	local x, y = level_manager_command.get_xy(i, j)
	transform_command.set_position(entity, x, y)
end


function M:onRemove(entity)
	local root = entity.game_object.root
	local i, j = level_manager_command.get_ij(entity.transform.position_x, entity.transform.position_y)
	local delay = j / 16
	go.animate(root, "scale.xy", go.PLAYBACK_ONCE_FORWARD, SCALE_ZERO, gui.EASING_OUTSINE, 0.15, delay)
end


return M
