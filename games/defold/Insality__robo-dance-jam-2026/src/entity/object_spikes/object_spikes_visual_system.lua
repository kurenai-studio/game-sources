local color = require("druid.color")
local audio = require("audio.audio")
local decore = require("decore.decore")
local panthera = require("panthera.panthera")
local field_turn_result = require("system.field.field.field_turn_result")

local music_command = require("system.music.music_command")
local panthera_command = require("system.panthera.panthera_command")

---@class entity
---@field object_spikes component.object_spikes|nil

---@class entity.object_spikes: entity
---@field object_spikes component.object_spikes

---@class component.object_spikes
---@field is_light_floor boolean

decore.register_component("object_spikes", {})

---@class system.object_spikes: system
---@field entities entity.object_spikes[]
local M = {}


---@return system.object_spikes
function M.create()
	local self = decore.system(M, "object_spikes", { "object_spikes" })
	return self
end



function M:postWrap()
	self.world.event_bus:process("field_turn_visual_event", self.process_field_turn_visual_event, self)
end



---@param entity entity
function M:onAdd(entity)
	if entity.object_spikes.is_light_floor then
		go.set(msg.url(nil, entity.game_object.object["/bot"], "sprite"), "color", color.get_color("#4A91C0"))
		go.set(msg.url(nil, entity.game_object.object["/middle"], "sprite"), "color", color.get_color("#4A91C0"))
		go.set(msg.url(nil, entity.game_object.object["/top"], "sprite"), "color", color.get_color("#4A91C0"))
	end
end


---@param event { entity: entity, turn: field.turn_result }
function M:process_field_turn_visual_event(event)
	local entity = event.entity
	local turn = event.turn
	for i = 1, #self.entities do
		-- If we did that action
		if self.entities[i].id == entity.id then
			if turn.type == field_turn_result.TURN_RESULT_TYPE.SET_STATE then
				if turn.state.prepare_attack then
					panthera_command.play(self.entities[i], "on_prepare_attack")
				end
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.ATTACK_CELL then
				panthera_command.play(self.entities[i], "on_attack")
				timer.delay(music_command.BEAT_TIME, false, function()
					audio.play("fx_spikes")
				end)
			end

			if turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
				if turn.die_type == field_turn_result.DIE_TYPE.FALL or turn.die_type == field_turn_result.DIE_TYPE.OOB then
					panthera_command.play(self.entities[i], "on_prepare_attack")
				else
					panthera_command.play(self.entities[i], "on_attack")
				end
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


function M:on_beat(bar_beat_counter)
	for i = 1, #self.entities do
		if bar_beat_counter == 1 or bar_beat_counter == 3 then
			panthera_command.play(self.entities[i], "on_beat", panthera.OPTIONS_SKIP_INIT)
		end
	end
end


return M
