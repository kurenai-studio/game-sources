local decore = require("decore.decore")

local field_turn_animator_command = require("system.field_turn_animator.field_turn_animator_command")

---@class system.field_turn_animator: system
local M = {}


---@return system.field_turn_animator
function M.create()
	local self = decore.system(M, "field_turn_animator")
	field_turn_animator_command.register(self)
	return self
end


return M
