local panthera = require("panthera.panthera")
local field_turn_result = require("system.field.field.field_turn_result")
local decore = require("decore.decore")
local audio = require("audio.audio")

local transform_command = require("system.transform.transform_command")
local panthera_command = require("system.panthera.panthera_command")
local music_command = require("system.music.music_command")
local field_command = require("system.field.field_command")

---@class entity
---@field projectile_laser_visual boolean|nil

---@class entity.projectile_laser_visual: entity
---@field projectile_laser_visual boolean
---@field game_object component.game_object
---@field transform component.transform
---@field panthera component.panthera

---@class component.projectile_laser_visual
decore.register_component("projectile_laser_visual", false)

---@class system.projectile_laser_visual: system
---@field entities entity.projectile_laser_visual[]
local M = {}


---@return system.projectile_laser_visual
function M.create()
	local self = decore.system(M, "projectile_laser_visual", { "projectile_laser_visual", "game_object", "transform", "panthera" })
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
			if turn.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL then
				panthera_command.play_track(entity, "on_attack", 2)
				timer.delay(music_command.BEAT_TIME, false, function()
					audio.play("fx_laser_attack")
				end)
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.MOVE then
				audio.play("fx_laser_movement")
				self:_check_rotation(entity, turn.side)
				self:_check_shadow(entity, turn)
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.MOVE_BLOCKED then
				panthera_command.play_track(entity, "on_attack", 2)
			end


			if turn.type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
				--audio.play("fx_laser_movement")
				timer.delay(0.6 + 0.6 - 0.5, false, function()
					self:_check_rotation(entity, turn.side)
					self:_check_shadow(entity, turn)
				end)
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
				timer.delay(0.6 + 0.6, false, function()
					panthera_command.play_track(entity, "on_die", 2)
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


function M:onAdd(entity)
	--panthera_command.play_track(entity, "disable_shadow", 4, panthera.OPTIONS_SKIP_INIT)
	panthera_command.set_progress(entity, "disable_shadow", 1, 4)
end


---@param bar_beat_counter integer
function M:on_beat(bar_beat_counter)
	for i = 1, #self.entities do
		if bar_beat_counter == 1 or bar_beat_counter == 3 then
			panthera_command.play(self.entities[i], "on_beat")
		end
	end
end


---@param entity entity
---@param side string
function M:_check_rotation(entity, side)
	if side == "up" or side == "down" then
		panthera_command.play_track(entity, "set_vertical", 3, panthera.OPTIONS_SKIP_INIT)
	else
		panthera_command.play_track(entity, "set_horizontal", 3, panthera.OPTIONS_SKIP_INIT)
	end
end


---@param entity entity
---@param turn field.turn_result
function M:_check_shadow(entity, turn)
	local is_floor_under = field_command.is_floor_under(entity, turn)
	if is_floor_under then
		panthera_command.play_track(entity, "enable_shadow", 4, panthera.OPTIONS_SKIP_INIT)
	else
		panthera_command.play_track(entity, "disable_shadow", 4, panthera.OPTIONS_SKIP_INIT)
	end
end


return M

