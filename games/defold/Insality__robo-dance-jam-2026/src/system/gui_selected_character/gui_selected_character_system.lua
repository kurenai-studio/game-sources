local decore = require("decore.decore")

local gui_game_command = require("entity.gui_game.gui_game_command")

---@class entity
---@field gui_selected_character boolean|nil

---@class entity.gui_selected_character: entity
---@field gui_selected_character boolean
decore.register_component("gui_selected_character", false)

---@class system.gui_selected_character: system
---@field entities entity.gui_selected_character[]
local M = {}


---@return system.gui_selected_character
function M.create()
	return decore.system(M, "gui_selected_character", { "gui_selected_character" })
end


---@param entity entity.gui_selected_character
function M:onAdd(entity)
	gui_game_command.select_character(entity)
end


return M
