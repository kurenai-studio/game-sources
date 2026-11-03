---@class system.game_manager.command
---@field game_manager system.game_manager
local M = {}


---@param game_manager system.game_manager
function M.register(game_manager)
	M.game_manager = game_manager
end


function M.start_game()
	M.game_manager:start_game()
end


function M.on_level_complete()
	M.game_manager:on_level_complete()
end


function M.load_next_level()
	M.game_manager:load_next_level()
end


function M.load_previous_level()
	M.game_manager:load_previous_level()
end

function M.reload_level()
	M.game_manager:reload_level()
end


return M
