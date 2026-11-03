local decore = require("decore.decore")
local audio = require("audio.audio")
local panthera = require("panthera.panthera")
local field_turn_result = require("system.field.field.field_turn_result")

local panthera_command = require("system.panthera.panthera_command")
local music_command = require("system.music.music_command")

---@class entity
---@field object_turret_visual boolean|nil

---@class entity.object_turret_visual: entity
---@field object_turret_visual boolean
---@field game_object component.game_object
---@field transform component.transform
---@field panthera component.panthera

---@class component.object_turret_visual
decore.register_component("object_turret_visual", false)

---@class system.object_turret_visual: system
---@field entities entity.object_turret_visual[]
local M = {}


---@return system.object_turret_visual
function M.create()
	local self = decore.system(M, "object_turret_visual", { "object_turret_visual", "game_object", "transform", "panthera" })
	return self
end


function M:postWrap()
	self.world.event_bus:process("field_turn_visual_event", self.process_field_turn_visual_event, self)
end


---@param event { entity: entity, turn: field.turn_result }
function M:process_field_turn_visual_event(event)
	local entity = event.entity
	local turn = event.turn
	for i = 1, #self.entities do
		if self.entities[i] == entity then
			if turn.type == field_turn_result.TURN_RESULT_TYPE.SET_STATE then
				if turn.state.prepare_attack then
					panthera_command.play(self.entities[i], "on_attack_prepare")
				end
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.SPAWN then
				panthera_command.play(self.entities[i], "on_attack")

				audio.play("fx_turret")
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
				timer.delay(0.6 + 0.6 - 0.5, false, function()
					panthera_command.play(self.entities[i], "on_die")
				end)
			end
		end
	end
end


function M:onAddToWorld()
	music_command.on_beat:subscribe(self.on_beat, self)
end


function M:onRemoveFromWorld()
	music_command.on_beat:unsubscribe(self.on_beat, self)
end


---@param bar_beat_counter integer
function M:on_beat(bar_beat_counter)
	for i = 1, #self.entities do
		if bar_beat_counter == 1 or bar_beat_counter == 3 then
			panthera_command.play_track(self.entities[i], "on_beat", 2, panthera.OPTIONS_SKIP_INIT)
		end
	end
end


return M
