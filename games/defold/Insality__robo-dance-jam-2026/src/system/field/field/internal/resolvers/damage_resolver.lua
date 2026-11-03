local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

---@class field.resolver.damage
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
---@return field.resolver.damage
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._grid = field:get_grid()

	return self
end


---@param attack_actions field.turn_action[]
---@param actions table<string, field.turn_action[]>
---@return field.turn_result[]
function M:resolve(attack_actions, actions)
	local result_actions = {}

	for index = 1, #attack_actions do
		local action = attack_actions[index]
		local entity_id = action.entity_id
		local entity = self._grid:get_entity(entity_id)
		if entity then
			local entity_i = entity.i
			local entity_j = entity.j
			local resolved_side = action.turn_side or const.TURN_SIDE.NONE
			local target_i = entity_i
			local target_j = entity_j
			local damage_amount = action.turn_params.damage

			table.insert(result_actions, turn_result.attack_cell(
				entity_id,
				target_i,
				target_j,
				resolved_side,
				damage_amount
			))

			local target_entities = self._grid:get_entities_at(target_i, target_j)
			for entity_index = 1, #target_entities do
				local target_entity = target_entities[entity_index]
				local is_other_entity = target_entity.entity_id ~= entity_id
				local can_take_damage = target_entity.health and target_entity.health > 0
				if is_other_entity and can_take_damage and field_entities_overlap_z(entity, target_entity) then
					local applied_damage = math.min(damage_amount, target_entity.health)
					if applied_damage > 0 then
						target_entity.health = target_entity.health - applied_damage

						table.insert(result_actions, turn_result.damage(
							target_entity.entity_id,
							target_i,
							target_j,
							resolved_side,
							applied_damage
						))

						if target_entity.health <= 0 then
							table.insert(result_actions, turn_result.die(
								target_entity.entity_id,
								entity_id,
								target_i,
								target_j,
								resolved_side,
								turn_result.DIE_TYPE.DAMAGE
							))
						end
					end
				end
			end

		end
	end

	return result_actions
end


return M
