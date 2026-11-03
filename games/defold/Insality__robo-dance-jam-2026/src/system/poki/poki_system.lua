local log = require("log.log")
local decore = require("decore.decore")

---@class system.poki: system
---@field is_started boolean
local M = {}


---@return system.poki
function M.create()
	local self = decore.system(M, "poki")
	self.is_started = false

	return self
end


function M:postWrap()
	self.world.event_bus:process("game_active", self.process_game_active, self)
end


function M:process_game_active(event)
	if event.is_active then
		self:gameplay_start()
	else
		self:gameplay_stop()
	end
end


function M:gameplay_start()
	if self.is_started or not poki_sdk then
		return
	end

	self.is_started = true
	poki_sdk.gameplay_start()
	log:debug("Poki gameplay started")
end


function M:gameplay_stop()
	if not self.is_started or not poki_sdk then
		return
	end

	self.is_started = false
	poki_sdk.gameplay_stop()
	log:debug("Poki gameplay stopped")
end


return M
