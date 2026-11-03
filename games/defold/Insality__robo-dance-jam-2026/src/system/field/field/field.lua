local const = require("system.field.field.const")
local field_resolver = require("system.field.field.internal.field_resolver")
local field_grid = require("system.field.field.internal.field_grid")

---@class field
---@field _field_resolver field.field_resolver
---@field _grid field.grid
local M = {}


---@return field
function M.create()
	local self = setmetatable({}, { __index = M })
	self._grid = field_grid.create()
	self._field_resolver = field_resolver.create(self)

	return self
end


---@return field.grid
function M:get_grid()
	return self._grid
end


---@param entity field.entity
---@return field.entity
function M:add_entity(entity)
	return self._grid:add_entity(entity)
end


---@param entity field.entity
function M:remove_entity(entity)
	return self._grid:remove_entity(entity)
end


---@param turn_actions field.turn_action[]
---@return field.turn_result[]
function M:resolve_turn(turn_actions)
	local result_actions = {}

	local step_actions = self:_split_actions_by_steps(turn_actions)

	-- Step 1: Movement step
	local move_result_actions = self._field_resolver:step_move(step_actions, result_actions)
	self:table_add(result_actions, move_result_actions)

	-- Step 2: Attack step (includes damage_on_collide before normal damage)
	local attack_result_actions = self._field_resolver:step_attack(step_actions, result_actions)
	self:table_add(result_actions, attack_result_actions)

	-- Step 3: Knockback step
	local knockback_result_actions = self._field_resolver:step_knockback(step_actions, result_actions)
	self:table_add(result_actions, knockback_result_actions)

	-- Step 4: Support step
	local support_result_actions = self._field_resolver:step_support(step_actions, result_actions)
	self:table_add(result_actions, support_result_actions)

	return result_actions
end


---@param target table
---@param values table|nil
function M:table_add(target, values)
	if not values then
		return
	end

	for index = 1, #values do
		table.insert(target, values[index])
	end
end


function M:print_debug_field()
	self._grid:print_debug_grid()
end


---@param turn_actions field.turn_action[]
---@return table<string, field.turn_action[]> split actions by steps
function M:_split_actions_by_steps(turn_actions)
	local step_actions = {
		[const.TURN_STEPS.MOVE] = {},
		[const.TURN_STEPS.ATTACK] = {},
		[const.TURN_STEPS.KNOCKBACK] = {},
		[const.TURN_STEPS.SUPPORT] = {},
	}

	for _, turn_action in ipairs(turn_actions) do
		local step = turn_action.turn_step
		table.insert(step_actions[step], turn_action)
	end

	return step_actions
end


return M
