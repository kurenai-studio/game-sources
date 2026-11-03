local turn_result = require("system.field.field.field_turn_result")

local PREFAB_PLAYER = "object_player"
local PREFAB_FINISH = "object_finish"

---@class field.resolver.collide
---@field _grid field.grid
local M = {}


---@param a field.entity
---@param b field.entity
---@return boolean
local function field_entities_overlap_z(a, b)
	local a_top = a.z + a.height
	local b_top = b.z + b.height
	return a.z < b_top and b.z < a_top
end


---@param field field
---@return field.resolver.collide
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._grid = field:get_grid()

	return self
end



---@param actions table<string, field.turn_action[]>
---@return field.turn_result[]
function M:resolve(actions)
	local results = {}
	local player_field_entity
	local finish_field_entities = {}

	for field_entity in pairs(self._grid.entities) do
		if field_entity.name == PREFAB_PLAYER then
			player_field_entity = field_entity
		elseif field_entity.name == PREFAB_FINISH then
			table.insert(finish_field_entities, field_entity)
		end
	end

	if player_field_entity then
		local pi, pj = player_field_entity.i, player_field_entity.j
		for index = 1, #finish_field_entities do
			local finish_fe = finish_field_entities[index]
			if finish_fe.i == pi and finish_fe.j == pj and field_entities_overlap_z(player_field_entity, finish_fe) then
				local collisions = turn_result.entity_collision(player_field_entity.entity_id, finish_fe.entity_id, pi, pj)
				table.insert(results, collisions)
				break
			end
		end
	end

	return results
end


return M
