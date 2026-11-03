---@class entity.gui_game.command
---@field gui_game system.gui_game|nil
local M = {}


---@param gui_game system.gui_game
function M.register(gui_game)
	M.gui_game = gui_game
end


---@param entity entity
function M.select_character(entity)
	M.gui_game:select_character(entity)
end


return M
