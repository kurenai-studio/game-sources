local decore = require("decore.decore")
--local command_field_appear = require("system.field_appear.command_field_appear")

---@class entity
---@field field_appear component.field_appear|nil
---@field distance_to_player number|nil
---@field distance_to_finish number|nil

---@class entity.field_appear: entity
---@field field_appear component.field_appear
---@field distance_to_player number|nil
---@field distance_to_finish number|nil

---@class component.field_appear
decore.register_component("field_appear", {
	delay = 0
})
decore.register_component("distance_to_player")
decore.register_component("distance_to_finish")

local SCALE_ZERO = vmath.vector3(0.0001, 0.0001, 1)
local SCALE_ONE = vmath.vector3(1, 1, 1)

---@class system.field_appear: system
---@field entities entity.field_appear[]
local M = {}


---@return system.field_appear
function M.create_system()
	return decore.system(M, "field_appear", { "field_appear", "field", "game_object" })
end


local MAX_DISTANCE = 128 * 7
local MAX_DELAY = 0.3

function M:onAdd(entity)
	local root = entity.game_object.root
	local delay = 0
	if entity.distance_to_player then
		delay = decore.clamp(entity.distance_to_player / MAX_DISTANCE, 0, 1) * MAX_DELAY
	end

	go.set_scale(SCALE_ZERO, root)
	go.animate(root, "scale", go.PLAYBACK_ONCE_FORWARD, SCALE_ONE, gui.EASING_OUTSINE, 0.3, delay)
end


function M:onRemove(entity)
	local root = entity.game_object.root
	local delay = 0
	if entity.distance_to_finish then
		-- Invert the delay calculation so entities at max distance scale faster
		delay = (1 - decore.clamp(entity.distance_to_finish / MAX_DISTANCE, 0, 1)) * MAX_DELAY
	end

	go.cancel_animations(root, "scale")
	go.animate(root, "scale", go.PLAYBACK_ONCE_FORWARD, SCALE_ZERO, gui.EASING_OUTSINE, 0.2, delay)
end


return M
