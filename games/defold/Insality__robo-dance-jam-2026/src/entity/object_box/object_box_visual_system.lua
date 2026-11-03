local decore = require("decore.decore")
local field_turn_result = require("system.field.field.field_turn_result")

local panthera_command = require("system.panthera.panthera_command")

---@class entity
---@field object_box_visual boolean|nil

---@class entity.object_box_visual: entity
---@field object_box_visual boolean
---@field game_object component.game_object
---@field transform component.transform
---@field panthera component.panthera

---@class component.object_box_visual
decore.register_component("object_box_visual", false)

---@class system.object_box_visual: system
---@field entities entity.object_box_visual[]
local M = {}


---@return system.object_box_visual
function M.create()
	local self = decore.system(M, "object_box_visual", { "object_box_visual", "game_object", "transform", "panthera" })
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
	if turn.type == field_turn_result.TURN_RESULT_TYPE.DAMAGE then
		timer.delay(0.6 + 0.6 - 0.5, false, function()
			panthera_command.play(entity, "on_damage")
		end)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE_BLOCKED then
		timer.delay(0.6 + 0.6 - 0.5, false, function()
			panthera_command.play(entity, "on_move_blocked")
		end)
	elseif turn.type == field_turn_result.TURN_RESULT_TYPE.DIE then
		timer.delay(0.6 + 0.6, false, function()
			panthera_command.play(entity, "on_die")
		end)
	end
end


return M
