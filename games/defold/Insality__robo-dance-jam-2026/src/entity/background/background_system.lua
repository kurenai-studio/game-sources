local decore = require("decore.decore")

local background_command = require("entity.background.background_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")
local music_command = require("system.music.music_command")

---@class entity
---@field background boolean|nil

---@class entity.background: entity
---@field background boolean

decore.register_component("background", false)

---@class system.background: system
---@field entities entity.background[]
local M = {}


---@return system.background
function M.create()
	local self = decore.system(M, "background", { "background" })
	background_command.register(self)
	self.widget = nil
	return self
end


function M:onAdd(entity)
	self.widget = entity.druid_widget.widget --[[@as widget.background]]
end


function M:onAddToWorld()
	turn_execution_command.on_running_changed:subscribe(self.set_battle_state, self)
	music_command.on_beat:subscribe(self.on_music_beat, self)
end


function M:onRemoveFromWorld()
	turn_execution_command.on_running_changed:unsubscribe(self.set_battle_state, self)
	music_command.on_beat:unsubscribe(self.on_music_beat, self)
end


function M:set_battle_state(is_battle)
	self._is_battle = is_battle
	self.widget:set_battle_state(is_battle)
end


function M:on_music_beat(bar_beat_counter)
	if self._is_battle then
		self.widget:on_beat(bar_beat_counter)
	end
end


return M
