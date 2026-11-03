local decore = require("decore.decore")
local camera_command = require("system.camera.camera_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")
local music_command = require("system.music.music_command")

---@class system.camera_battle: system
local M = {}

local SHAKE_POWER_MAIN_BEAT = 3
local SHAKE_POWER_BEAT = 2
local SHAKE_TIME = 0.3

---@return system.camera_battle
function M.create()
	local self = decore.system(M, "camera_battle")
	self._is_battle = false
	return self
end


function M:onAddToWorld()
	turn_execution_command.on_running_changed:subscribe(self.set_battle_state, self)
	music_command.on_beat:subscribe(self.on_music_beat, self)
end


function M:onRemoveFromWorld()
	turn_execution_command.on_running_changed:unsubscribe(self.set_battle_state, self)
	music_command.on_beat:unsubscribe(self.on_music_beat, self)
end


---@param is_battle boolean
function M:set_battle_state(is_battle)
	self._is_battle = is_battle
	if is_battle then
		camera_command.set_offset_zoom(-0.08, 0.6)
	else
		camera_command.set_offset_zoom(0, 1.2)
	end
end


---@param bar_beat_counter integer
function M:on_music_beat(bar_beat_counter)
	if not self._is_battle then
		return
	end

	if bar_beat_counter == 1 then
		camera_command.shake(SHAKE_POWER_MAIN_BEAT, SHAKE_TIME)
	else
		camera_command.shake(SHAKE_POWER_BEAT, SHAKE_TIME)
	end
end


return M
