local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

---@class field.resolver.damage_on_collide
---@field _grid field.grid
local M = {}


---@param grid field.grid
---@param entity field.entity
---@return boolean
local function entity_overlaps_solid_at_z(grid, entity)
	local entities = grid:get_entities_at(entity.i, entity.j)
	for _, other in ipairs(entities) do
		if other.entity_id ~= entity.entity_id and other.solid then
			local is_box_overlaps = entity.z > other.z and entity.z < other.z + other.height
			if is_box_overlaps then
				return true
			end
		end
	end

	return false
end


---@param grid field.grid
---@param entity field.entity
---@return string|nil
local function first_overlapping_solid_id(grid, entity)
	local entities = grid:get_entities_at(entity.i, entity.j)
	for _, other in ipairs(entities) do
		if other.entity_id ~= entity.entity_id and other.solid then
			local is_box_overlaps = entity.z > other.z and entity.z < other.z + other.height
			if is_box_overlaps then
				return other.entity_id
			end
		end
	end

	return nil
end


---@param field field
---@return field.resolver.damage_on_collide
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._grid = field:get_grid()

	return self
end


--- Runs at the start of the attack phase (after movement): non-solids with `damage_on_collide` hurt themselves when overlapping a solid at their z-band.
--- Extend later for other collide hooks (e.g. finish) by scanning different flags in the same pass.
---
---@return field.turn_result[]
function M:resolve()
	local results = {}

	for entity in pairs(self._grid.entities) do
		local amount = entity.damage_on_collide
		if amount and amount > 0 and not entity.solid and entity.health and entity.health > 0 then
			if entity_overlaps_solid_at_z(self._grid, entity) then
				local applied = math.min(amount, entity.health)
				entity.health = entity.health - applied

				table.insert(results, turn_result.damage(
					entity.entity_id,
					entity.i,
					entity.j,
					const.TURN_SIDE.NONE,
					applied
				))

				if entity.health <= 0 then
					local source_id = first_overlapping_solid_id(self._grid, entity) or entity.entity_id
					table.insert(results, turn_result.die(
						entity.entity_id,
						source_id,
						entity.i,
						entity.j,
						const.TURN_SIDE.NONE,
						turn_result.DIE_TYPE.DAMAGE
					))
				end
			end
		end
	end

	return results
end


return M
