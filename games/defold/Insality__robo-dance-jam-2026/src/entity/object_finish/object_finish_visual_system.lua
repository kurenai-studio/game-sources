local decore = require("decore.decore")

local field_turn_result = require("system.field.field.field_turn_result")
local panthera_command = require("system.panthera.panthera_command")
local music_command = require("system.music.music_command")
local game_manager_command = require("system.game_manager.game_manager_command")
local level_manager_command = require("system.level_manager.level_manager_command")
local turn_execution_command = require("system.turn_execution.turn_execution_command")

---@class entity
---@field object_finish_visual boolean|nil

---@class entity.object_finish_visual: entity
---@field object_finish_visual boolean
---@field game_object component.game_object
---@field transform component.transform
---@field panthera component.panthera

---@class component.object_finish_visual
decore.register_component("object_finish_visual", false)

---@class system.object_finish_visual: system
---@field entities entity.object_finish_visual[]
local M = {}


---@return system.object_finish_visual
function M.create()
	local self = decore.system(M, "object_finish_visual", { "object_finish_visual", "game_object", "transform", "panthera" })
	self.is_level_complete_processing = false
	return self
end


function M:onAddToWorld()
	music_command.on_beat:subscribe(self.on_beat, self)
end


function M:onRemoveFromWorld()
	music_command.on_beat:unsubscribe(self.on_beat, self)
end


function M:postWrap()
	self.world.event_bus:process("field_turn_visual_event", self.process_field_turn_visual_event, self)
end


---@param event { entity: entity, turn: field.turn_result }
function M:process_field_turn_visual_event(event)
	if self.is_level_complete_processing then
		return
	end

	local turn = event.turn
	if turn.type ~= field_turn_result.TURN_RESULT_TYPE.ENTITY_COLLISION then
		return
	end

	local collision_entity = event.entity
	if not collision_entity.object_player_visual then
		return
	end

	for index = 1, #self.entities do
		if self.entities[index].id == turn.other_entity_id then
			self.is_level_complete_processing = true
			game_manager_command.on_level_complete()
			turn_execution_command.set_running(false)
			timer.delay(music_command.BEAT_TIME * 2, false, function()
				game_manager_command.load_next_level()
			end)
			return
		end
	end
end



function M:onAdd(entity)
	self.is_level_complete_processing = false
end

---@param bar_beat_counter integer
function M:on_beat(bar_beat_counter)
	for i = 1, #self.entities do
		if bar_beat_counter == 1 or bar_beat_counter == 3 then
			panthera_command.play(self.entities[i], "on_beat")
		end
	end
end


return M
