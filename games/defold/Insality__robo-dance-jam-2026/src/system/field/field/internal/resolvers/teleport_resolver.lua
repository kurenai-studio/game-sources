local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

---@class field.resolver.teleport
---@field _grid field.grid
local M = {}


---@param results field.turn_result[]
---@param result field.turn_result
local function add_teleport_result(results, result)
	result.resolver_id = "teleport"
	table.insert(results, result)
end


---@param field field
---@return field.resolver.teleport
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._grid = field:get_grid()

	return self
end


---@param teleport_actions field.turn_action[]
---@return field.turn_result[]
function M:resolve(teleport_actions)
	local results = {}

	for index = 1, #teleport_actions do
		local action = teleport_actions[index]
		local entity = self._grid:get_entity(action.entity_id)
		if entity and entity.movable and entity.solid then
			local side = action.turn_side or const.TURN_SIDE.NONE
			local side_data = const.TURN_SIDE_DATA[side]
			local dist = action.turn_params and action.turn_params.distance or 1

			if not side_data or side == const.TURN_SIDE.NONE then
				add_teleport_result(results, turn_result.move_blocked(action.entity_id, entity.i, entity.j, side))
			else
				local target_i = entity.i + side_data.i * dist
				local target_j = entity.j + side_data.j * dist

				if not self:_is_in_bounds(target_i, target_j) then
					add_teleport_result(results, turn_result.move_blocked(action.entity_id, entity.i, entity.j, side))
				elseif not self:_is_cell_walkable(entity, target_i, target_j) then
					add_teleport_result(results, turn_result.move_blocked(action.entity_id, entity.i, entity.j, side))
				else
					add_teleport_result(results, turn_result.move(action.entity_id, target_i, target_j, side))
					self._grid:move_entity(entity, target_i, target_j)
					entity.last_move_side = side
				end
			end
		elseif entity then
			add_teleport_result(results, turn_result.move_blocked(action.entity_id, entity.i, entity.j, action.turn_side or const.TURN_SIDE.NONE))
		end
	end

	return results
end


---@param i integer
---@param j integer
---@return boolean
function M:_is_in_bounds(i, j)
	return i >= const.GRID_INDEX_MIN and i <= const.GRID_INDEX_MAX and
			j >= const.GRID_INDEX_MIN and j <= const.GRID_INDEX_MAX
end


---@param move_entity field.entity
---@param target_i integer
---@param target_j integer
---@return boolean
function M:_is_cell_walkable(move_entity, target_i, target_j)
	local entities = self._grid:get_entities_at(target_i, target_j)

	for e = 1, #entities do
		local target_entity = entities[e]
		local is_this_entity = target_entity.entity_id == move_entity.entity_id
		if not is_this_entity then
			local is_collide = target_entity.solid and target_entity.z == move_entity.z
			if is_collide and move_entity.solid then
				return false
			end
		end
	end

	return true
end


return M
