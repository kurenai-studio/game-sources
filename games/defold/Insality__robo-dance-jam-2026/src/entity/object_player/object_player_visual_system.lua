local audio = require("audio.audio")

local field_turn_result = require("system.field.field.field_turn_result")
local decore = require("decore.decore")

local field_command = require("system.field.field_command")
local game_manager_command = require("system.game_manager.game_manager_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")
local panthera_command = require("system.panthera.panthera_command")
local music_command = require("system.music.music_command")

---@class entity
---@field object_player_visual boolean|nil

---@class entity.object_player_visual: entity
---@field object_player_visual boolean
---@field game_object component.game_object
---@field transform component.transform
---@field panthera component.panthera

---@class component.object_player_visual
decore.register_component("object_player_visual", false)

---@class system.object_player_visual: system
---@field entities entity.object_player_visual[]
local M = {}


---@return system.object_player_visual
function M.create()
	local self = decore.system(M, "object_player_visual", { "object_player_visual", "game_object", "transform", "panthera" })
	return self
end


function M:postWrap()
	self.world.event_bus:process("field_turn_visual_event", self.process_field_turn_visual_event, self)
end


---@param event { entity: entity, turn: field.turn_result }
function M:process_field_turn_visual_event(event)
	local entity = event.entity
	if not self.indices[entity] then
		return
	end

	local turn = event.turn
	-- when knockback - play damage animation
	if turn.type == field_turn_result.TURN_RESULT_TYPE.MOVE then
		if turn.resolver_id == "teleport" then
			panthera_command.play(entity, "on_teleport")
			audio.play("fx_teleport")
		else
			audio.play("fx_movement")
		end
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.MOVE_BLOCKED then
		if turn.resolver_id == "teleport" then
			panthera_command.play(entity, "on_teleport")
			audio.play("fx_teleport_blocked")
		end
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
		timer.delay(0.6 + 0.6 - 0.5, false, function()
			panthera_command.play(entity, "on_knockback")
		end)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE_BLOCKED then
		timer.delay(0.6 + 0.6 - 0.5, false, function()
			panthera_command.play(entity, "on_knockback")
		end)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.DAMAGE then
		timer.delay(0.6 + 0.6 - 0.5, false, function()
			panthera_command.play(entity, "on_damage")
			audio.play("fx_damage")
		end)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL then
		panthera_command.play(entity, "on_attack")
		audio.play("fx_attack")
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
		timer.delay(0.6 + 0.6, false, function()
			panthera_command.play(entity, "on_die")

			turn_execution_command.set_running(false)
			timer.delay(music_command.BEAT_TIME * 2, false, function()
				game_manager_command.reload_level()
			end)
		end)
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
				panthera_command.play(self.entities[i], "on_beat")
			end
		end
	end
end


return M
