---@class system.background.command
---@field background system.background
local M = {}


---@param background system.background
function M.register(background)
	M.background = background
end


function M.set_battle_state(is_battle)
	M.background:set_battle_state(is_battle)
end


return M
