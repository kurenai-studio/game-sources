local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

local M = {}


---@param grid field.grid
---@return table<string, { i: integer, j: integer }>
function M.snapshot_entity_positions_by_id(grid)
	local out = {}
	for entity in pairs(grid.entities) do
		out[entity.entity_id] = { i = entity.i, j = entity.j }
	end
	return out
end


---@param grid field.grid
---@param i integer
---@param j integer
---@param entity field.entity
---@return boolean
local function cell_has_other_solid_at_z(grid, i, j, entity)
	local entities = grid:get_entities_at(i, j)
	for _, other in ipairs(entities) do
		local is_box_overlaps = entity.z > other.z and entity.z < other.z + other.height

		if other.entity_id ~= entity.entity_id and other.solid and (is_box_overlaps) then
			return true
		end
	end

	return false
end


---@param grid field.grid
---@param move_entity field.entity
---@param target_i integer
---@param target_j integer
---@return boolean
local function non_solid_has_floor(grid, move_entity, target_i, target_j)
	local entities = grid:get_entities_at(target_i, target_j)
	for _, target_entity in ipairs(entities) do
		local is_this_entity = target_entity.entity_id == move_entity.entity_id
		if not is_this_entity and target_entity.solid and move_entity.z > target_entity.z + target_entity.height then
			return true
		end
	end

	return false
end


---@param grid field.grid Grid state after solid move phase (same as in `resolve`).
---@param initial_pos_by_id table<string, { i: integer, j: integer }>
---@param move_actions field.turn_action[]
---@param projectile_entity field.entity
---@param proj_action field.turn_action
---@return boolean
function M.is_mutual_adjacent_swap(grid, initial_pos_by_id, move_actions, projectile_entity, proj_action)
	local proj_id = projectile_entity.entity_id
	local p0 = initial_pos_by_id[proj_id]
	if not p0 then
		return false
	end

	local Pi, Pj = p0.i, p0.j
	local proj_side = proj_action.turn_side or const.TURN_SIDE.NONE
	local psd = const.TURN_SIDE_DATA[proj_side]
	if not psd or proj_side == const.TURN_SIDE.NONE then
		return false
	end

	local p_next_i = Pi + psd.i
	local p_next_j = Pj + psd.j

	for index = 1, #move_actions do
		local action = move_actions[index]
		if action.entity_id ~= proj_id then
			local solid = grid:get_entity(action.entity_id)
			if solid and solid.movable and solid.solid then
				local s0 = initial_pos_by_id[action.entity_id]
				if s0 then
					local Si, Sj = s0.i, s0.j
					local solid_side = action.turn_side or const.TURN_SIDE.NONE
					local ssd = const.TURN_SIDE_DATA[solid_side]
					if ssd and solid_side ~= const.TURN_SIDE.NONE then
						local s_next_i = Si + ssd.i
						local s_next_j = Sj + ssd.j
						if s_next_i == Pi and s_next_j == Pj and p_next_i == Si and p_next_j == Sj then
							local solid_now = grid:get_entity(action.entity_id)
							if solid_now and solid_now.i == Pi and solid_now.j == Pj then
								return true
							end
						end
					end
				end
			end
		end
	end

	return false
end


---@param grid field.grid
---@param move_actions field.turn_action[]
---@param initial_pos_by_id table<string, { i: integer, j: integer }>
---@param is_knockback boolean
---@param updates_last_move_side boolean
---@return field.turn_result[]
function M.resolve(grid, move_actions, initial_pos_by_id, is_knockback, updates_last_move_side)
	local out = {}

	for index = 1, #move_actions do
		local action = move_actions[index]
		local entity = grid:get_entity(action.entity_id)
		if entity and entity.movable and not entity.solid then
			local side = action.turn_side or const.TURN_SIDE.NONE
			if side ~= const.TURN_SIDE.NONE then
				local side_data = const.TURN_SIDE_DATA[side] or const.TURN_SIDE_DATA[const.TURN_SIDE.NONE]
				local max_dist = action.turn_params.distance or 0
				if max_dist > 0 then
					if M.is_mutual_adjacent_swap(grid, initial_pos_by_id, move_actions, entity, action) then
						local start_i, start_j = entity.i, entity.j
						if is_knockback then
							table.insert(out, turn_result.knockback_move_blocked(action.entity_id, start_i, start_j, side))
						else
							table.insert(out, turn_result.move_blocked(action.entity_id, start_i, start_j, side))
						end
					else
						local start_i, start_j = entity.i, entity.j
						local cur_i, cur_j = start_i, start_j
						local starts_in_collision = cell_has_other_solid_at_z(grid, start_i, start_j, entity)

						for step = 0, max_dist do
							local is_collide = cell_has_other_solid_at_z(grid, cur_i, cur_j, entity)
							local is_initial_overlap_step = starts_in_collision and step == 0
							if is_collide and not is_initial_overlap_step then
								break
							end

							if not entity.flying and not non_solid_has_floor(grid, entity, cur_i, cur_j) then
								break
							end
							if step < max_dist then
								cur_i = cur_i + side_data.i
								cur_j = cur_j + side_data.j
							end
						end

						if cur_i == start_i and cur_j == start_j then
							if is_knockback then
								table.insert(out, turn_result.knockback_move_blocked(action.entity_id, start_i, start_j, side))
							else
								table.insert(out, turn_result.move_blocked(action.entity_id, start_i, start_j, side))
							end
						else
							grid:move_entity(entity, cur_i, cur_j)
							if updates_last_move_side then
								entity.last_move_side = side
							end
							if is_knockback then
								table.insert(out, turn_result.knockback_move(action.entity_id, cur_i, cur_j, side))
							else
								table.insert(out, turn_result.move(action.entity_id, cur_i, cur_j, side))
							end
						end
					end
				end
			end
		end
	end

	return out
end


return M
