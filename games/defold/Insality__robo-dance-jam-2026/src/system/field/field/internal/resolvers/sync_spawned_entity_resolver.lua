local decore = require("decore.decore")
local abilities = require("game.abilities")
local turn_result = require("system.field.field.field_turn_result")
local world = require("game.world")

local level_manager_command = require("system.level_manager.level_manager_command")
local transform_command = require("system.transform.transform_command")
local turn_list_command = require("system.turn_list.turn_list_command")

---@class field.resolver.sync_spawned_entity
local M = {}


---@return field.resolver.sync_spawned_entity
function M.create()
	local self = setmetatable({}, { __index = M })

	return self
end


---@param spawn_turn_results field.turn_result[]
---@param actions table<string, field.turn_action[]> keys: turn_step (move, attack, …)
---@return field.turn_result[]
function M:resolve(spawn_turn_results, actions)
	for index = 1, #spawn_turn_results do
		local result = spawn_turn_results[index]
		if result.type == turn_result.TURN_RESULT_TYPE.SPAWN and result.prefab_id and result.spawned_entity_id then

			local entity = decore.create_prefab(result.prefab_id, nil, {
				id = result.spawned_entity_id
			})
			local x, y = level_manager_command.get_xy(result.target_i, result.target_j)
			transform_command.set_position(entity, x, y)
			level_manager_command.add_entity_as_level_child(entity)

			-- Grab next actions from turn_list sequences
			self:_fill_next_actions(entity, actions)
		end
	end

	world:refresh()

	return {}
end



---@param entity entity
---@param actions table<string, field.turn_action[]> keys: turn_step (move, attack, …)
function M:_fill_next_actions(entity, actions)
	local next_turn = turn_list_command.get_next_turn(entity)
	if not next_turn then
		return
	end

	local ability = abilities[next_turn.ability_id]
	if not ability or not ability.get_turn_action then
		return
	end

	local turn_actions = ability.get_turn_action(entity.id, next_turn.side, next_turn.params)
	for index = 1, #turn_actions do
		local turn_action = turn_actions[index]
		table.insert(actions[turn_action.turn_step], turn_action)
	end
end

return M
