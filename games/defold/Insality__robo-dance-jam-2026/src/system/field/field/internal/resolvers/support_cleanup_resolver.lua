local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

---@class field.resolver.support_cleanup
---@field _grid field.grid
local M = {}


---@param field field
---@return field.resolver.support_cleanup
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._grid = field:get_grid()

	return self
end


---@param actions table<string, field.turn_action[]>
---@return field.turn_result[]
function M:resolve(actions)
	local results = {}
	local entities_to_remove = {}

	for entity in pairs(self._grid.entities) do
		if entity.health and entity.health > 0 then
			if self:_is_out_of_field_bounds(entity) then
				entity.health = 0

				table.insert(results, turn_result.die(
					entity.entity_id,
					entity.entity_id,
					entity.i,
					entity.j,
					const.TURN_SIDE.NONE,
					turn_result.DIE_TYPE.OOB
				))
			elseif entity.z > 0 and not entity.flying and not self:_has_floor_below(entity) then
				entity.health = 0

				table.insert(results, turn_result.die(
					entity.entity_id,
					entity.entity_id,
					entity.i,
					entity.j,
					const.TURN_SIDE.NONE,
					turn_result.DIE_TYPE.FALL
				))
			end
		end

		if entity.health and entity.health <= 0 then
			table.insert(entities_to_remove, entity)
		end
	end

	for index = 1, #entities_to_remove do
		local entity = entities_to_remove[index]

		self._grid:remove_entity(entity)
		table.insert(results, turn_result.remove_entity(entity.entity_id))
	end

	return results
end


---@param entity field.entity
---@return boolean
function M:_is_out_of_field_bounds(entity)
	return entity.i < const.GRID_INDEX_MIN or entity.i > const.GRID_INDEX_MAX
		or entity.j < const.GRID_INDEX_MIN or entity.j > const.GRID_INDEX_MAX
end


---@param entity field.entity
---@return boolean
function M:_has_floor_below(entity)
	local entities = self._grid:get_entities_at(entity.i, entity.j)
	for _, target_entity in ipairs(entities) do
		local is_this_entity = target_entity.entity_id == entity.entity_id
		local is_floor = target_entity.solid and (target_entity.z + target_entity.height) <= entity.z
		if not is_this_entity and is_floor then
			return true
		end
	end

	return false
end


return M
