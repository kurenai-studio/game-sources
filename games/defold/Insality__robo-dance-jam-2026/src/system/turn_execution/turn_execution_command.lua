---@class system.turn_execution.command
---@field turn_execution system.turn_execution
---@field on_running_changed event
local M = {}


---@param turn_execution system.turn_execution
function M.register(turn_execution)
	M.turn_execution = turn_execution
	M.on_running_changed = turn_execution.on_running_changed
end


---@param is_running boolean
function M.set_running(is_running)
	M.turn_execution:set_running(is_running)
end


---@param is_auto boolean
function M.set_auto(is_auto)
	M.turn_execution:set_auto(is_auto)
end


---@return boolean
function M.is_running()
	return M.turn_execution.is_running
end


---@return boolean
function M.is_auto()
	return M.turn_execution.is_auto
end


---@return number
function M.get_running_time_progress()
	if M.turn_execution.running_time_total <= 0 then
		return 1
	end

	return 1 - (M.turn_execution.running_time_left / M.turn_execution.running_time_total)
end


---Instant next turns process
function M.process_turns()
	M.turn_execution:process_turns()
end


return M
