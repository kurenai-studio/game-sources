local decore = require("decore.decore")
local const = require("system.field.field.const")
local field_helper = require("system.field.field.internal.field_helper")
local turn_result = require("system.field.field.field_turn_result")
local level_manager_command = require("system.level_manager.level_manager_command")
local transform_command = require("system.transform.transform_command")
local world = require("game.world")
local turn_list_command = require("system.turn_list.turn_list_command")
local abilities = require("game.abilities")


---@class field.resolver.spawn_entity
---@field _field field
---@field _grid field.grid
local M = {}


---@param field field
---@return field.resolver.spawn_entity
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._field = field
	self._grid = field:get_grid()

	return self
end


function M:clear()
end


---@param spawn_entity_actions field.turn_action[]
---@param actions table<string, field.turn_action[]>
---@return field.turn_result[]
function M:resolve(spawn_entity_actions, actions)
	local spawn_results = {}

	for index = 1, #spawn_entity_actions do
		local action = spawn_entity_actions[index]
		local source_entity = self._grid:get_entity(action.entity_id)
		if source_entity then

			local params = action.turn_params
			local delta_i = params.delta_i or 0
			local delta_j = params.delta_j or 0
			local facing_side = params.side or action.turn_side or const.TURN_SIDE.NONE
			local target_i, target_j = field_helper.cell_from_facing_delta(
				source_entity.i,
				source_entity.j,
				facing_side,
				delta_i,
				delta_j
			)

			local in_bounds = target_i >= const.GRID_INDEX_MIN and target_i <= const.GRID_INDEX_MAX
				and target_j >= const.GRID_INDEX_MIN and target_j <= const.GRID_INDEX_MAX

			if in_bounds then
				local entity = decore.create_prefab(params.prefab_id)
				local x, y = level_manager_command.get_xy(target_i, target_j)

				transform_command.set_position(entity, x, y)
				if entity.turn_list then
					entity.turn_list.inherited_side = facing_side
				end
				level_manager_command.add_entity_as_level_child(entity)

				local spawned_field_entity = field_helper.get_entity_by_id(self._grid, entity.id)
				if spawned_field_entity then
					spawned_field_entity.last_move_side = facing_side
				end

				self:_fill_next_actions(entity, actions)

				table.insert(spawn_results, turn_result.spawn(
					action.entity_id,
					target_i,
					target_j,
					facing_side,
					params.prefab_id,
					entity.id
				))
			end
		end
	end

	world:refresh()

	return spawn_results
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
