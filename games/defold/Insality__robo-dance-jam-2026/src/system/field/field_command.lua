local field_turn_animator_command = require("system.field_turn_animator.field_turn_animator_command")

---@class system.field.command
---@field field_system system.field
local M = {}


---@param field_system system.field
function M.register(field_system)
	M.field_system = field_system
end


---@param turn_actions field.turn_action[]
function M.process_turns(turn_actions)
	--M.field_system.field:print_debug_field()

	--M.debug_print_turn_actions(turn_actions)

	local result_actions = M.field_system.field:resolve_turn(turn_actions)
	field_turn_animator_command.animate_turns(result_actions)

	--M.debug_print_result_actions(result_actions)
end


---@param entity_id number
---@return field.entity|nil
function M.get_field_entity(entity_id)
	return M.field_system:get_field_entity(entity_id)
end


---@param entity entity
---@return field.entity
function M.build_field_entity(entity)
	return M.field_system:build_field_entity(entity)
end


---@param turn_actions field.turn_action[]
function M.debug_print_turn_actions(turn_actions)
	print("Turn actions:")
	for _, turn_action in ipairs(turn_actions) do
		local entity = M.field_system.world:findEntity("id", tonumber(turn_action.entity_id))
		local name = entity and (entity.name or entity.prefab_id or "|removed|")

		print("  -", turn_action.entity_id, name, turn_action.turn_action, turn_action.turn_side)
	end
end


---@param result_actions field.turn_result[]
function M.debug_print_result_actions(result_actions)
	print("Result actions:")
	for _, result_action in ipairs(result_actions) do
		local entity = M.field_system.world:findEntity("id", tonumber(result_action.entity_id))
		local name = entity and (entity.name or entity.prefab_id or "|removed|")

		print("  -", result_action.entity_id, name, result_action.type, result_action.target_i, result_action.target_j, result_action.side)
	end
end


---@param entity entity
---@param turn field.turn_result
function M.is_floor_under(entity, turn)
	local target_i, target_j = turn.target_i, turn.target_j

	local field_entity = M.get_field_entity(entity.id)
	local entities = M.field_system.field:get_grid():get_entities_at(target_i, target_j)

	if not field_entity then
		return false
	end

	local entity_z = field_entity.z
	for _, other_entity in ipairs(entities) do
		if other_entity.entity_id ~= field_entity.entity_id then
			local is_solid = other_entity.solid
			local top_z = other_entity.z + other_entity.height

			if is_solid and top_z <= entity_z then
				return true
			end
		end
	end

	return false
end



return M
