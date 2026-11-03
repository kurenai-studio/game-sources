local decore = require("decore.decore")
local game_object_command = require("system.game_object.game_object_command")

---@class entity
---@field select_arrow_visual component.select_arrow_visual|nil

---@class entity.select_arrow_visual: entity
---@field select_arrow_visual component.select_arrow_visual
---@field game_object component.game_object

---@class component.select_arrow_visual
---@field side "up" | "down" | "left" | "right" | nil
---@field _current_side "up" | "down" | "left" | "right" | nil
decore.register_component("select_arrow_visual", {
	side = nil,
	_current_side = nil,
})

---@class system.select_arrow_visual: system
---@field entities entity.select_arrow_visual[]
local M = {}


---@return system.select_arrow_visual
function M.create()
	return decore.system(M, "select_arrow_visual", { "select_arrow_visual", "game_object" })
end


function M:update()
	for i = 1, #self.entities do
		local entity = self.entities[i]
		local select_arrow_visual = entity.select_arrow_visual
		if select_arrow_visual.side ~= select_arrow_visual._current_side then
			self:update_visual(entity)
		end
	end
end


---@param entity entity.select_arrow_visual
function M:update_visual(entity)
	local side = entity.select_arrow_visual.side
	game_object_command.set_object_enabled(entity, "/down", side == "down")
	game_object_command.set_object_enabled(entity, "/up", side == "up")
	game_object_command.set_object_enabled(entity, "/left", side == "left")
	game_object_command.set_object_enabled(entity, "/right", side == "right")
	entity.select_arrow_visual._current_side = side
end


return M
