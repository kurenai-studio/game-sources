local events = require("event.events")

---@class world
---@field field_movable system.field_movable.command

---@class system.field_movable.command
---@field field_movable system.field_movable
local M = {}


---@return system.field_movable.command
function M.create(field_movable)
	return setmetatable({ field_movable = field_movable }, { __index = M })
end


---@param movement_side string
function M:move_to_direction(movement_side)
	for _, entity in ipairs(self.field_movable.entities) do
		if entity.user_controlled then
			self.field_movable:move_to_direction(entity, movement_side)
		end
	end

	events.trigger("game.make_turn")
end


return M
