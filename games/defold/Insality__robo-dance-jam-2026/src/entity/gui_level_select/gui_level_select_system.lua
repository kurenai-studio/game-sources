local event = require("event.event")
local decore = require("decore.decore")
local levels = require("game.levels")

---@class entity
---@field gui_level_select component.gui_level_select|nil

---@class entity.gui_level_select: entity
---@field gui_level_select component.gui_level_select

---@class component.gui_level_select
---@field on_menu event
---@field on_level_click event
---@field on_back event
decore.register_component("gui_level_select", {
	on_menu = event.create(),
	on_back = event.create(),
	on_level_click = event.create(),
})

---@class system.gui_level_select: system
---@field entities entity.gui_level_select[]
local M = {}


---@return system.gui_level_select
function M.create()
	return decore.system(M, "gui_level_select", { "gui_level_select" })
end


function M:onAdd(entity)
	self.widget = entity.druid_widget.widget --[[@as widget.gui_level_select]]

	local levels_data = {}

	for _, level in pairs(levels.LEVELS) do
		local state = "blocked"
		if level.level_id == levels.get_current_level_id() then
			state = "current"
		end
		if levels.state.levels[level.level_id] and levels.state.levels[level.level_id].completed then
			state = "completed"
		end
		table.insert(levels_data, {
			level = level.index,
			level_id = level.level_id,
			state = state,
		})
	end

	self.widget:set_levels(levels_data)
end


return M
