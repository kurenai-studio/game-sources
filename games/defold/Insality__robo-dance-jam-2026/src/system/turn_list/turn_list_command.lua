local log = require("log.log")
local const = require("system.field.field.const")
local field_command = require("system.field.field_command")

local M = {}

local RELATIVE_SIDE_RING = {
	const.TURN_SIDE.UP,
	const.TURN_SIDE.RIGHT,
	const.TURN_SIDE.DOWN,
	const.TURN_SIDE.LEFT,
}

local RELATIVE_SIDE_INDEX = {
	[const.TURN_SIDE.UP] = 1,
	[const.TURN_SIDE.RIGHT] = 2,
	[const.TURN_SIDE.DOWN] = 3,
	[const.TURN_SIDE.LEFT] = 4,
}


---@param entity entity
---@return string|nil
local function resolve_current_side(entity)
	local field_sys = field_command.field_system
	if field_sys then
		local fe = field_sys.field:get_grid():get_entity(entity.id)
		if fe and fe.last_move_side and fe.last_move_side ~= const.TURN_SIDE.NONE then
			return fe.last_move_side
		end
	end

	if entity.field_actor and entity.field_actor.initial_side and entity.field_actor.initial_side ~= const.TURN_SIDE.NONE then
		return entity.field_actor.initial_side
	end

	local turn_list = entity.turn_list
	if turn_list and turn_list.inherited_side ~= nil then
		return turn_list.inherited_side
	end

	return nil
end


---@param current_side string|nil
---@param relative_side string
---@return string
local function resolve_relative_side(current_side, relative_side)
	local relative_index = RELATIVE_SIDE_INDEX[relative_side]
	if not relative_index then
		return relative_side
	end

	local current_index = RELATIVE_SIDE_INDEX[current_side]
	if not current_index then
		return relative_side
	end

	local resolved_index = ((current_index - 1) + (relative_index - 1)) % 4 + 1
	return RELATIVE_SIDE_RING[resolved_index]
end


--- Explicit step side, else `field.entity.last_move_side` (if not none), else `turn_list.inherited_side`.
---@param entity entity
---@param explicit string|nil
---@return string|nil
local function resolve_turn_side(entity, explicit)
	if explicit ~= nil then
		if type(explicit) == "string" and explicit:sub(1, 1) == "+" then
			local relative_side = explicit:sub(2)
			local current_side = resolve_current_side(entity)
			return resolve_relative_side(current_side, relative_side)
		end

		return explicit
	end

	return resolve_current_side(entity)
end


---@param entity entity
---@param ability_id string
---@param side "up" | "down" | "left" | "right" | nil
---@param index integer|nil
---@return boolean
function M.add_turn(entity, ability_id, side, index)
	assert(entity.turn_list, "Entity does not have a turn_list component.")

	if #entity.turn_list.scheduled >= entity.turn_list.scheduled_length_max then
		return false
	end

	---@type component.turn_list.turn
	local turn = {
		ability_id = ability_id,
		side = side,
	}

	if index then
		table.insert(entity.turn_list.scheduled, index, turn)
	else
		table.insert(entity.turn_list.scheduled, turn)
	end

	log:debug("Scheduled turn", { name = entity.name, id = ability_id, side = side, index = index })

	entity.turn_list.on_changed:trigger()
	return true
end


---@param entity entity.turn_list
function M.clear_turns(entity)
	entity.turn_list.scheduled = {}
	entity.turn_list.on_changed:trigger()
end


---@param entity entity
---@param index integer
---@return component.turn_list.turn|nil
function M.remove_turn(entity, index)
	local turn = table.remove(entity.turn_list.scheduled, index)
	entity.turn_list.on_changed:trigger()
	return turn
end


---@param entity entity
---@param index integer
---@return component.turn_list.turn|nil
function M.get_turn(entity, index)
	return entity.turn_list.scheduled[index]
end


---@param entity entity
---@return component.turn_list.turn|nil, boolean turn Next turn and is it from scheduled user list
function M.get_next_turn(entity)
	local scheduled_turn = entity.turn_list.scheduled[1]
	if scheduled_turn then
		M.remove_turn(entity, 1)
		scheduled_turn.side = resolve_turn_side(entity, scheduled_turn.side)
		return scheduled_turn, true
	end

	local intro_list = entity.turn_list.intro_sequence_list
	if intro_list and #intro_list > 0 and entity.turn_list.intro_last_index < #intro_list then
		entity.turn_list.intro_last_index = entity.turn_list.intro_last_index + 1
		local next_intro = intro_list[entity.turn_list.intro_last_index]
		return {
			ability_id = next_intro[1],
			side = resolve_turn_side(entity, next_intro[2]),
			params = next_intro[3],
		}, false
	end

	local sequence_list = entity.turn_list.sequence_list
	if #sequence_list == 0 then
		return nil, false
	end

	local next_index = entity.turn_list.sequence_last_index + 1
	if next_index > #sequence_list then
		next_index = 1
	end

	entity.turn_list.sequence_last_index = next_index
	local next_turn = sequence_list[next_index]
	return {
		ability_id = next_turn[1],
		side = resolve_turn_side(entity, next_turn[2]),
		params = next_turn[3],
	}, false
end


return M
