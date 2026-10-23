---@class world
---@field game_manager system.game_manager.command

---@class system.game_manager.command
---@field game_manager system.game_manager
local M = {}


---@return system.game_manager.command
function M.create(game_manager)
	return setmetatable({ game_manager = game_manager }, { __index = M })
end


function M:start_game()
	self.game_manager:load_current_level()
end


function M:create_menu_gui()
	self.game_manager:create_menu_gui()
end


return M
