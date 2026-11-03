local audio = require("audio.audio")
local decore = require("decore.decore")
local panthera = require("panthera.panthera")

local field_turn_result = require("system.field.field.field_turn_result")
local panthera_command = require("system.panthera.panthera_command")
local music_command = require("system.music.music_command")
local field_command = require("system.field.field_command")

---@class entity
---@field object_enemy_visual boolean|nil

---@class entity.object_enemy_visual: entity
---@field object_enemy_visual boolean
---@field game_object component.game_object
---@field transform component.transform
---@field panthera component.panthera

---@class component.object_enemy_visual
decore.register_component("object_enemy_visual", false)

---@class system.object_enemy_visual: system
---@field entities entity.object_enemy_visual[]
local M = {}


---@return system.object_enemy_visual
function M.create()
	local self = decore.system(M, "object_enemy_visual", { "object_enemy_visual", "game_object", "transform", "panthera" })
	return self
end


function M:postWrap()
	self.world.event_bus:process("field_turn_visual_event", self.process_field_turn_visual_event, self)
end


---@param event { entity: entity, turn: field.turn_result }
function M:process_field_turn_visual_event(event)
	local entity = event.entity
	local turn = event.turn
	for index = 1, #self.entities do
		if self.entities[index] == entity then
			if turn.type == field_turn_result.TURN_RESULT_TYPE.SET_STATE and turn.state.prepare_attack then
				panthera_command.play(entity, "on_attack_prepare")
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL then
				panthera_command.play(entity, "on_attack", panthera.OPTIONS_SKIP_INIT)
				audio.play("fx_enemy_attack")
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
				timer.delay(0.6 + 0.6 - 0.5, false, function()
					panthera_command.play(entity, "on_die")
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
			local field_entity = field_command.get_field_entity(self.entities[i].id)
			local is_alive = field_entity and field_entity.health > 0
			if is_alive then
				panthera_command.play_track(self.entities[i], "on_beat", 2, panthera.OPTIONS_SKIP_INIT)
			end
		end
	end
end


return M
