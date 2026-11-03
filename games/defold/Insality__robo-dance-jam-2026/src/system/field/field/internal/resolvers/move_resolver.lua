local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

---@class field.resolver.move_intention
---@field side string

---@class field.resolver.move_mark
---@field entity_id string
---@field side string

---@class field.resolver.move
---@field _field field
---@field _grid field.grid
---@field _move_intentions table<string, field.resolver.move_intention[]>
---@field _is_knockback boolean
---@field _updates_last_move_side boolean
local M = {}


---@param field field
---@param is_knockback boolean|nil If true, emit knockback_* turn results instead of move/move_blocked
---@return field.resolver.move
function M.create(field, is_knockback)
	local self = setmetatable({}, { __index = M })
	self._field = field
	self._grid = field:get_grid()
	self._move_intentions = {}
	self._is_knockback = is_knockback == true
	self._updates_last_move_side = not self._is_knockback

	return self
end


function M:clear()
	self._move_intentions = {}
end


---@param move_actions field.turn_action[] Only move actions
---@return field.turn_result[]
function M:resolve_solids(move_actions)
	self:clear()
	self:_fill_move_intentions(move_actions)

	local move_result_actions = {}

	while not self:_is_intentions_empty() do
		local move_marks = self:_mark_move_intentions()
		local step_result_temp = self:_proceed_movement(move_marks)
		self:_apply_step_result(move_result_actions, step_result_temp)
	end

	local step_result = {}
	for _, result in pairs(move_result_actions) do
		table.insert(step_result, result)
	end

	return step_result
end


---@param move_actions field.turn_action[]
function M:_fill_move_intentions(move_actions)
	for index = 1, #move_actions do
		local action = move_actions[index]
		local entity = self._grid:get_entity(action.entity_id)
		if entity and entity.movable and entity.solid then
			self._move_intentions[action.entity_id] = self._move_intentions[action.entity_id] or {}

			local step_length = action.turn_params.distance
			for _ = 1, step_length do
				table.insert(self._move_intentions[action.entity_id], {
					side = action.turn_side,
				})
				self:_append_push_intentions(entity, action.turn_side, {})
			end
		end
	end
end


---@param entity field.entity
---@param side string
---@param visited table<string, boolean>
function M:_append_push_intentions(entity, side, visited)
	if visited[entity.entity_id] then
		return
	end
	visited[entity.entity_id] = true

	local side_data = const.TURN_SIDE_DATA[side]
	if not side_data or side == const.TURN_SIDE.NONE then
		return
	end

	local target_i = entity.i + side_data.i
	local target_j = entity.j + side_data.j
	local target_entities = self._grid:get_entities_at(target_i, target_j)

	for index = 1, #target_entities do
		local target_entity = target_entities[index]
		local is_same_entity = target_entity.entity_id == entity.entity_id
		local is_push_candidate = target_entity.solid and target_entity.movable and target_entity.pushable and target_entity.z == entity.z
		if not is_same_entity and is_push_candidate then
			self._move_intentions[target_entity.entity_id] = self._move_intentions[target_entity.entity_id] or {}
			table.insert(self._move_intentions[target_entity.entity_id], { side = side })
			self:_append_push_intentions(target_entity, side, visited)
		end
	end
end


---@return boolean
function M:_is_intentions_empty()
	return next(self._move_intentions) == nil
end


---@return table<number, string[]>
function M:_mark_move_intentions()
	local move_marks = {}

	for entity_id, move_intention_list in pairs(self._move_intentions) do
		local move_intention = move_intention_list[1]
		local entity = self._grid:get_entity(entity_id)
		if entity then
			local side_data = const.TURN_SIDE_DATA[move_intention.side]
			local target_i = entity.i + side_data.i
			local target_j = entity.j + side_data.j
			local field_key = self._grid:ij_to_key(target_i, target_j)
			self:_add_move_mark(entity, field_key, move_intention.side, move_marks)
		end
	end

	return move_marks
end


---@param move_marks table<number, string[]>
---@return table<string, field.turn_result>
function M:_proceed_movement(move_marks)
	local step_result_temp = {}
	local step_intentions = {}

	for entity_id, move_intention_list in pairs(self._move_intentions) do
		local move_intention = move_intention_list[1]
		if move_intention then
			step_intentions[entity_id] = move_intention.side
		end
	end

	for entity_id, move_intention_list in pairs(self._move_intentions) do
		local move_intention = move_intention_list[1]
		local entity = self._grid:get_entity(entity_id)
		if entity then
			local side_data = const.TURN_SIDE_DATA[move_intention.side]
			local target_i = entity.i + side_data.i
			local target_j = entity.j + side_data.j
			local is_can_step_on = self:_is_can_step_on(entity, move_marks, side_data, step_intentions)

			if is_can_step_on then
				table.remove(move_intention_list, 1)
				local hit_solid = not entity.solid and self:_cell_has_other_solid_at_z(target_i, target_j, entity)
				if hit_solid or #move_intention_list == 0 then
					self._move_intentions[entity_id] = nil
				end

				if self._is_knockback then
					step_result_temp[entity_id] = turn_result.knockback_move(entity_id, target_i, target_j, move_intention.side)
				else
					step_result_temp[entity_id] = turn_result.move(entity_id, target_i, target_j, move_intention.side)
				end
			else
				self._move_intentions[entity_id] = nil
				if self._is_knockback then
					step_result_temp[entity_id] = turn_result.knockback_move_blocked(entity_id, entity.i, entity.j, move_intention.side)
				else
					step_result_temp[entity_id] = turn_result.move_blocked(entity_id, entity.i, entity.j, move_intention.side)
				end

				local stay_field_key = self._grid:ij_to_key(entity.i, entity.j)
				self:_add_move_mark(entity, stay_field_key, const.TURN_SIDE.NONE, move_marks)
				self:_remove_conflict_move_mark(move_marks, step_result_temp, entity_id, entity.i, entity.j)
			end
		end
	end

	return step_result_temp
end


---@param move_marks table<number, field.resolver.move_mark[]>
---@param step_result_temp table<string, field.turn_result>
---@param entity_id string
---@param cell_i integer
---@param cell_j integer
function M:_remove_conflict_move_mark(move_marks, step_result_temp, entity_id, cell_i, cell_j)
	for conflict_entity_id, conflict_result in pairs(step_result_temp) do
		local is_same_entity = conflict_entity_id == entity_id
		local t = conflict_result.type
		local is_move_result = t == turn_result.TURN_RESULT_TYPE.MOVE or t == turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE
		local is_same_cell = conflict_result.target_i == cell_i and conflict_result.target_j == cell_j

		if not is_same_entity and is_move_result and is_same_cell then
			local conflict_entity = self._grid:get_entity(conflict_entity_id)
			if conflict_entity then
				if t == turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
					step_result_temp[conflict_entity_id] = turn_result.knockback_move_blocked(
						conflict_entity_id,
						conflict_entity.i,
						conflict_entity.j,
						conflict_result.side
					)
				else
					step_result_temp[conflict_entity_id] = turn_result.move_blocked(
						conflict_entity_id,
						conflict_entity.i,
						conflict_entity.j,
						conflict_result.side
					)
				end
				self._move_intentions[conflict_entity_id] = nil

				local conflict_field_key = self._grid:ij_to_key(conflict_entity.i, conflict_entity.j)
				self:_add_move_mark(conflict_entity, conflict_field_key, const.TURN_SIDE.NONE, move_marks)
				self:_remove_conflict_move_mark(
					move_marks,
					step_result_temp,
					conflict_entity_id,
					conflict_entity.i,
					conflict_entity.j
				)
			end
		end
	end
end


---@param step_result_map table<string, field.turn_result>
---@param step_result_temp table<string, field.turn_result>
function M:_apply_step_result(step_result_map, step_result_temp)
	for entity_id, step_result in pairs(step_result_temp) do
		local entity = self._grid:get_entity(entity_id)
		if entity then
			self._grid:move_entity(entity, step_result.target_i, step_result.target_j)
			if step_result.type == turn_result.TURN_RESULT_TYPE.KNOCKBACK_MOVE then
				entity.last_move_side = step_result.side
			elseif self._updates_last_move_side and step_result.type == turn_result.TURN_RESULT_TYPE.MOVE then
				entity.last_move_side = step_result.side
			end
		end

		step_result_map[entity_id] = step_result
	end
end


---@param entity field.entity
---@param field_key integer
---@param side string
---@param move_marks table<number, field.resolver.move_mark[]>
function M:_add_move_mark(entity, field_key, side, move_marks)
	move_marks[field_key] = move_marks[field_key] or {}

	if not entity.solid then
		return false
	end

	for _, mark in ipairs(move_marks[field_key]) do
		if mark.entity_id == entity.entity_id then
			mark.side = side
			return false
		end
	end

	table.insert(move_marks[field_key], {
		entity_id = entity.entity_id,
		side = side
	})

	return true
end


---@param entity field.entity
---@param move_marks table<number, field.resolver.move_mark[]>
---@param side_data field.turn_side_data
---@param step_intentions table<string, string>
---@return boolean
function M:_is_can_step_on(entity, move_marks, side_data, step_intentions)
	local entity_i, entity_j = entity.i, entity.j
	local current_field_key = self._grid:ij_to_key(entity_i, entity_j)
	local current_marks = move_marks[current_field_key]

	local target_i, target_j = entity_i + side_data.i, entity_j + side_data.j
	local target_field_key = self._grid:ij_to_key(target_i, target_j)
	local target_marks = move_marks[target_field_key]

	local can_step_by_mark = false
	if not entity.solid then
		can_step_by_mark = true
	elseif target_marks then
		can_step_by_mark = true
		for _, mark in ipairs(target_marks) do
			if mark.entity_id ~= entity.entity_id then
				local mark_entity = self._grid:get_entity(mark.entity_id)
				if mark_entity and mark_entity.solid and mark_entity.z == entity.z then
					can_step_by_mark = false
					break
				end
			end
		end
	end

	local is_cell_walkable = self:_is_cell_walkable_by_entity(entity, target_i, target_j, step_intentions)

	local is_blocks_by_towards_direction = false
	if current_marks then
		if #current_marks == 1 and
			current_marks[1].side == side_data.opposite and
			current_marks[1].entity_id ~= entity.entity_id then
			is_blocks_by_towards_direction = true
		end
	end

	return can_step_by_mark and
			is_cell_walkable and
			not is_blocks_by_towards_direction
end


---@param i integer
---@param j integer
---@param entity field.entity
---@return boolean
function M:_cell_has_other_solid_at_z(i, j, entity)
	local entities = self._grid:get_entities_at(i, j)
	for _, other in ipairs(entities) do
		local is_box_overlaps = entity.z > other.z and entity.z < other.z + other.height

		if other.entity_id ~= entity.entity_id and other.solid and (is_box_overlaps) then
			return true
		end
	end

	return false
end


---@param move_entity field.entity
---@param target_i integer
---@param target_j integer
---@param step_intentions table<string, string>
---@return boolean
function M:_is_cell_walkable_by_entity(move_entity, target_i, target_j, step_intentions)
	local is_blocked_by_someone = false

	local entities = self._grid:get_entities_at(target_i, target_j)
	for _, target_entity in ipairs(entities) do
		local is_this_entity = target_entity.entity_id == move_entity.entity_id
		local is_solid = target_entity.solid

		local is_collide = is_solid and target_entity.z == move_entity.z
		local has_step_intention = step_intentions[target_entity.entity_id] ~= nil
		if is_collide and move_entity.solid then
			if not has_step_intention then
				is_blocked_by_someone = true
			end
		end
	end

	return not is_blocked_by_someone
end


return M
