local const = require("system.field.field.const")
local field_turn_action = require("system.field.field.field_turn_action")
local turn_result = require("system.field.field.field_turn_result")

---@class field.resolver.knockback
---@field _grid field.grid
local M = {}


---@param a field.entity
---@param b field.entity
---@return boolean
local function field_entities_overlap_z(a, b)
	local a_top = a.z + a.height
	local b_top = b.z + b.height
	return a.z <= b_top and b.z <= a_top
end


---@param action field.turn_action
---@param attacker field.entity
---@param target_entity field.entity
---@return string
local function get_push_side(action, attacker, target_entity)
	local push_side = action.turn_side or const.TURN_SIDE.NONE
	if push_side == const.TURN_SIDE.NONE then
		if action.turn_action == const.TURN_ACTIONS.SUPPORT_KNOCKBACK then
			return attacker.last_move_side or const.TURN_SIDE.NONE
		end

		local last_move_side = target_entity.last_move_side or const.TURN_SIDE.NONE
		local last_move_side_data = const.TURN_SIDE_DATA[last_move_side]
		if last_move_side_data then
			push_side = last_move_side_data.opposite
		end
	end

	return push_side
end


---@param side string
---@param distance number
---@return integer
---@return integer
local function get_vector(side, distance)
	local side_data = const.TURN_SIDE_DATA[side]
	if not side_data then
		return 0, 0
	end
	return side_data.i * distance, side_data.j * distance
end


---@param actions table<string, field.turn_action[]>
---@param move_step string
---@param entity_id string
---@param side string
---@param distance integer
local function push_knockback_move(actions, move_step, entity_id, side, distance)
	if side ~= const.TURN_SIDE.NONE and distance > 0 then
		table.insert(actions[move_step], field_turn_action.move(
			entity_id,
			distance,
			side
		))
	end
end


---@param target_entity field.entity
---@param sum_i integer
---@param sum_j integer
---@return string
---@return integer
local function get_aggregated_knockback(target_entity, sum_i, sum_j)
	if sum_i == 0 and sum_j == 0 then
		return const.TURN_SIDE.NONE, 0
	end

	local abs_i = math.abs(sum_i)
	local abs_j = math.abs(sum_j)
	if abs_i > abs_j then
		if sum_i > 0 then
			return const.TURN_SIDE.RIGHT, abs_i
		end
		return const.TURN_SIDE.LEFT, abs_i
	end

	if abs_j > abs_i then
		if sum_j > 0 then
			return const.TURN_SIDE.UP, abs_j
		end
		return const.TURN_SIDE.DOWN, abs_j
	end

	local side = target_entity.last_move_side or const.TURN_SIDE.NONE
	if side == const.TURN_SIDE.LEFT and sum_i < 0 then
		return const.TURN_SIDE.LEFT, abs_i
	end
	if side == const.TURN_SIDE.RIGHT and sum_i > 0 then
		return const.TURN_SIDE.RIGHT, abs_i
	end
	if side == const.TURN_SIDE.UP and sum_j > 0 then
		return const.TURN_SIDE.UP, abs_j
	end
	if side == const.TURN_SIDE.DOWN and sum_j < 0 then
		return const.TURN_SIDE.DOWN, abs_j
	end

	return const.TURN_SIDE.NONE, 0
end


---@param field field
---@return field.resolver.knockback
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._grid = field:get_grid()

	return self
end


---@param knockback_actions field.turn_action[]
---@param actions table<string, field.turn_action[]>
---@param move_step string|nil
---@return field.turn_result[]
function M:resolve(knockback_actions, actions, move_step)
	local aggregated_by_target = {}
	local results = {}
	move_step = move_step or const.TURN_STEPS.KNOCKBACK

	for index = 1, #knockback_actions do
		local action = knockback_actions[index]
		local attacker = self._grid:get_entity(action.entity_id)
		if attacker then
			local target_i = attacker.i
			local target_j = attacker.j
			local distance = action.turn_params.distance

			local target_entities = self._grid:get_entities_at(target_i, target_j)
			for target_index = 1, #target_entities do
				local target_entity = target_entities[target_index]
				local is_other_entity = target_entity.entity_id ~= action.entity_id
				local can_be_pushed = target_entity.movable and is_other_entity
				if can_be_pushed and field_entities_overlap_z(attacker, target_entity) then
					local push_side = get_push_side(action, attacker, target_entity)
					if push_side ~= const.TURN_SIDE.NONE then
						local delta_i, delta_j = get_vector(push_side, distance)
						local state = aggregated_by_target[target_entity.entity_id]
						if not state then
							state = {
								entity = target_entity,
								sum_i = 0,
								sum_j = 0,
								last_push_side = const.TURN_SIDE.NONE,
							}
							aggregated_by_target[target_entity.entity_id] = state
						end
						state.sum_i = state.sum_i + delta_i
						state.sum_j = state.sum_j + delta_j
						state.last_push_side = push_side
					end
				end
			end
		end
	end

	for _, state in pairs(aggregated_by_target) do
		if state.sum_i == 0 and state.sum_j == 0 then
			table.insert(results, turn_result.knockback_move_blocked(
				state.entity.entity_id,
				state.entity.i,
				state.entity.j,
				state.last_push_side
			))
		end

		local abs_i = math.abs(state.sum_i)
		local abs_j = math.abs(state.sum_j)
		if abs_i > 0 and abs_j > 0 and abs_i == abs_j then
			local horizontal_side = state.sum_i > 0 and const.TURN_SIDE.RIGHT or const.TURN_SIDE.LEFT
			local vertical_side = state.sum_j > 0 and const.TURN_SIDE.UP or const.TURN_SIDE.DOWN

			push_knockback_move(actions, move_step, state.entity.entity_id, horizontal_side, abs_i)
			push_knockback_move(actions, move_step, state.entity.entity_id, vertical_side, abs_j)
		else
			local side, distance = get_aggregated_knockback(state.entity, state.sum_i, state.sum_j)
			push_knockback_move(actions, move_step, state.entity.entity_id, side, distance)
		end
	end

	return results
end


return M
