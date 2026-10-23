local decore = require("decore.decore")
local command_input = require("system.input.input_command")

---@class system.input.event: action

---@class system.input: system
---@field entities entity[]
local M = {}


---@return system.input
function M.create_system()
	return decore.system(M, "input")
end


function M:onAddToWorld()
	msg.post(".", "acquire_input_focus")
	self.world.input = command_input.create(self)
end


function M:onRemoveFromWorld()
	msg.post(".", "release_input_focus")
end


return M
