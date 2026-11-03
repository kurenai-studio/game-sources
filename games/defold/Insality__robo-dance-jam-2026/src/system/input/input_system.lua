local decore = require("decore.decore")
local input_command = require("system.input.input_command")

---@class system.input.event: action

---@class system.input: system
local M = {}


---@return system.input
function M.create()
	local self = decore.system(M, "input")
	input_command.register(self)
	return self
end


---@protected
function M:onAddToWorld()
	msg.post(".", "acquire_input_focus")
end


return M
