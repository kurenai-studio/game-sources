---@class action
---@field action_id hash

---@class system.input.command
---@field input system.input
local M = {}


---@param input system.input
function M.register(input)
	M.input = input
end


---@param action_id hash
---@param action action
---@return boolean
function M.on_input(action_id, action)
	action.action_id = action_id
	M.input.world.event_bus:trigger("input_event", action)
	return false
end


return M
