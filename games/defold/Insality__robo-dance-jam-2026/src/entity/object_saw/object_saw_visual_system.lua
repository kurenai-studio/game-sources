local audio = require("audio.audio")
local decore = require("decore.decore")
local field_turn_result = require("system.field.field.field_turn_result")

local music_command = require("system.music.music_command")
local panthera_command = require("system.panthera.panthera_command")
local field_command = require("system.field.field_command")

---@class entity
---@field object_saw boolean|nil

---@class entity.object_saw: entity
---@field object_saw boolean

---@class component.object_saw
decore.register_component("object_saw", false)

---@class system.object_saw: system
---@field entities entity.object_saw[]
local M = {}


---@return system.object_saw
function M.create()
	local self = decore.system(M, "object_saw", { "object_saw" })
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
	if turn.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL then
		panthera_command.play(entity, "on_attack")
		audio.play("fx_saw_attack")
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
		timer.delay(0.6 + 0.6, false, function()
			panthera_command.play_track(entity, "on_die", 2)
		end)
	end
end


function M:onAddToWorld()
	music_command.on_beat:subscribe(self.on_beat, self)
end


function M:onRemoveFromWorld()
	music_command.on_beat:unsubscribe(self.on_beat, self)
end


function M:on_beat(bar_beat_counter)
	if bar_beat_counter ~= 1 and bar_beat_counter ~= 3 then
		return
	end

	for i = 1, #self.entities do
		local field_entity = field_command.get_field_entity(self.entities[i].id)
		local is_alive = field_entity and field_entity.health > 0
		if is_alive then
			panthera_command.play(self.entities[i], "on_beat")
		end
	end
end


return M
