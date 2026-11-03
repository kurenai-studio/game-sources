local const = require("system.field.field.const")
local turn_result = require("system.field.field.field_turn_result")

local spawn_entity_resolver = require("system.field.field.internal.resolvers.spawn_entity_resolver")
local sync_spawned_entity_resolver = require("system.field.field.internal.resolvers.sync_spawned_entity_resolver")
local damage_resolver = require("system.field.field.internal.resolvers.damage_resolver")
local knockback_resolver = require("system.field.field.internal.resolvers.knockback_resolver")
local move_resolver = require("system.field.field.internal.resolvers.move_resolver")
local teleport_resolver = require("system.field.field.internal.resolvers.teleport_resolver")
local collide_resolver = require("system.field.field.internal.resolvers.collide_resolver")
local support_cleanup_resolver = require("system.field.field.internal.resolvers.support_cleanup_resolver")
local non_solid_slide_resolver = require("system.field.field.internal.resolvers.non_solid_slide_resolver")
local damage_on_collide_resolver = require("system.field.field.internal.resolvers.damage_on_collide_resolver")

---@class field.field_resolver
---@field _field field
---@field _grid field.grid
---@field _move_resolver field.resolver.move
---@field _teleport_resolver field.resolver.teleport
---@field _knockback_move_resolver field.resolver.move
---@field _damage_resolver field.resolver.damage
---@field _knockback_resolver field.resolver.knockback
---@field _spawn_entity_resolver field.resolver.spawn_entity
---@field _sync_spawned_entity_resolver field.resolver.sync_spawned_entity
---@field _collide_resolver field.resolver.collide
---@field _support_cleanup_resolver field.resolver.support_cleanup
---@field _damage_on_collide_resolver field.resolver.damage_on_collide
local M = {}


---@param action field.turn_action
---@return string
function M:get_action_side(action)
	if action.turn_side ~= nil then
		return action.turn_side
	end

	local entity = self._grid:get_entity(action.entity_id)
	if entity and entity.last_move_side then
		return entity.last_move_side
	end

	return const.TURN_SIDE.NONE
end


---@param set_state_actions field.turn_action[]
---@return field.turn_result[]
local function get_set_state_results(set_state_actions, actions)
	local result_actions = {}
	for index = 1, #set_state_actions do
		local action = set_state_actions[index]
		table.insert(result_actions, turn_result.set_state(action.entity_id, action.turn_params))
	end
	return result_actions
end


---@param field field
---@return field.field_resolver
function M.create(field)
	local self = setmetatable({}, { __index = M })
	self._field = field
	self._grid = field:get_grid()

	self._spawn_entity_resolver = spawn_entity_resolver.create(field)
	self._sync_spawned_entity_resolver = sync_spawned_entity_resolver.create()
	self._move_resolver = move_resolver.create(field)
	self._teleport_resolver = teleport_resolver.create(field)
	self._knockback_move_resolver = move_resolver.create(field, true)
	self._damage_resolver = damage_resolver.create(field)
	self._knockback_resolver = knockback_resolver.create(field)
	self._collide_resolver = collide_resolver.create(field)
	self._support_cleanup_resolver = support_cleanup_resolver.create(field)
	self._damage_on_collide_resolver = damage_on_collide_resolver.create(field)

	return self
end


---@param actions table<string, field.turn_action[]>
---@param result_actions field.turn_result[]
---@return field.turn_result[]
function M:step_move(actions, result_actions)
	local step = const.TURN_STEPS.MOVE

	local result_turn_actions = {}

	local spawn_entity_actions = self:action_filter(actions[step], const.TURN_ACTIONS.SPAWN_ENTITY)
	local spawn_result_data = self._spawn_entity_resolver:resolve(spawn_entity_actions, actions)
	self:merge_turn_actions(result_turn_actions, spawn_result_data)

	--self._sync_spawned_entity_resolver:resolve(result_turn_actions, actions)

	local set_state_actions = self:action_filter(actions[step], const.TURN_ACTIONS.SET_STATE)
	local set_state_result_data = get_set_state_results(set_state_actions, actions)
	self:merge_turn_actions(result_turn_actions, set_state_result_data)

	local move_actions = self:action_filter(actions[step], const.TURN_ACTIONS.MOVE)
	local initial_pos_by_id = non_solid_slide_resolver.snapshot_entity_positions_by_id(self._grid)

	local solid_move_results = self._move_resolver:resolve_solids(move_actions)
	self:merge_turn_actions(result_turn_actions, solid_move_results)

	local non_solid_move_results = non_solid_slide_resolver.resolve(self._grid, move_actions, initial_pos_by_id, false, true)
	self:merge_turn_actions(result_turn_actions, non_solid_move_results)

	local teleport_actions = self:action_filter(actions[step], const.TURN_ACTIONS.TELEPORT)
	local teleport_result_data = self._teleport_resolver:resolve(teleport_actions)
	self:merge_turn_actions(result_turn_actions, teleport_result_data)

	return result_turn_actions
end


---@param actions table<string, field.turn_action[]>
---@param result_actions field.turn_result[]
---@return field.turn_result[]
function M:step_attack(actions, result_actions)
	local step = const.TURN_STEPS.ATTACK

	local result_turn_actions = {}

	local attack_actions = self:action_filter(actions[step], const.TURN_ACTIONS.ATTACK)
	local attack_result_data = self._damage_resolver:resolve(attack_actions, actions)
	self:merge_turn_actions(result_turn_actions, attack_result_data)

	local collide_damage_data = self._damage_on_collide_resolver:resolve()
	self:merge_turn_actions(result_turn_actions, collide_damage_data)

	local knockback_actions = self:action_filter(actions[step], const.TURN_ACTIONS.KNOCKBACK_ATTACK)
	local knockback_result_data = self._knockback_resolver:resolve(knockback_actions, actions)
	self:merge_turn_actions(result_turn_actions, knockback_result_data)

	local collide_damage_data = self._damage_on_collide_resolver:resolve()
	self:merge_turn_actions(result_turn_actions, collide_damage_data)

	return result_turn_actions
end


---@param actions table<string, field.turn_action[]>
---@param result_actions field.turn_result[]
---@return field.turn_result[]
function M:step_knockback(actions, result_actions)
	local step = const.TURN_STEPS.KNOCKBACK

	local result_turn_actions = {}

	local move_actions = self:action_filter(actions[step], const.TURN_ACTIONS.MOVE)
	local initial_pos_by_id = non_solid_slide_resolver.snapshot_entity_positions_by_id(self._grid)

	local solid_move_results = self._knockback_move_resolver:resolve_solids(move_actions)
	self:merge_turn_actions(result_turn_actions, solid_move_results)

	local non_solid_move_results = non_solid_slide_resolver.resolve(self._grid, move_actions, initial_pos_by_id, true, true)
	self:merge_turn_actions(result_turn_actions, non_solid_move_results)

	return result_turn_actions
end


---@param actions table<string, field.turn_action[]>
---@param result_actions field.turn_result[]
---@return field.turn_result[]
function M:step_support(actions, result_actions)
	local step = const.TURN_STEPS.SUPPORT

	local result_turn_actions = {}

	local knockback_actions = self:action_filter(actions[step], const.TURN_ACTIONS.SUPPORT_KNOCKBACK)
	local knockback_result_data = self._knockback_resolver:resolve(knockback_actions, actions, const.TURN_STEPS.SUPPORT)
	self:merge_turn_actions(result_turn_actions, knockback_result_data)

	local move_actions = self:action_filter(actions[step], const.TURN_ACTIONS.MOVE)
	local initial_pos_by_id = non_solid_slide_resolver.snapshot_entity_positions_by_id(self._grid)

	local solid_move_results = self._knockback_move_resolver:resolve_solids(move_actions)
	self:merge_turn_actions(result_turn_actions, solid_move_results)

	local non_solid_move_results = non_solid_slide_resolver.resolve(self._grid, move_actions, initial_pos_by_id, true, true)
	self:merge_turn_actions(result_turn_actions, non_solid_move_results)

	local attack_actions = self:action_filter(actions[step], const.TURN_ACTIONS.ATTACK)
	local attack_result_data = self._damage_resolver:resolve(attack_actions, actions)
	self:merge_turn_actions(result_turn_actions, attack_result_data)

	local collide_damage_data = self._damage_on_collide_resolver:resolve()
	self:merge_turn_actions(result_turn_actions, collide_damage_data)

	local support_cleanup_result_data = self._support_cleanup_resolver:resolve(actions)
	self:merge_turn_actions(result_turn_actions, support_cleanup_result_data)

	local collide_result_data = self._collide_resolver:resolve(actions)
	self:merge_turn_actions(result_turn_actions, collide_result_data)

	return result_turn_actions
end


---@param actions field.turn_action[]
---@param action_type string
---@return field.turn_action[]
function M:action_filter(actions, action_type)
	local result_actions = {}
	if not actions then
		return result_actions
	end

	for index = 1, #actions do
		local action = actions[index]
		if action.turn_action == action_type then
			action.turn_side = self:get_action_side(action)
			table.insert(result_actions, action)
		end
	end

	return result_actions
end


---@param result_turn_actions field.turn_result[]
---@param turn_actions field.turn_result[]
function M:merge_turn_actions(result_turn_actions, turn_actions)
	for index = 1, #turn_actions do
		table.insert(result_turn_actions, turn_actions[index])
	end
end


return M
