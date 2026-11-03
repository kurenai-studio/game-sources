local const = require("system.field.field.const")

---@class field.turn_action
---@field public entity_id string
---@field public turn_step string
---@field public turn_action string
---@field public turn_side string?
---@field public turn_params table

local M = {}

---@param entity_id string
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.move(entity_id, distance, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.MOVE,
		turn_action = const.TURN_ACTIONS.MOVE,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			distance = distance,
		},
	}
end


---@param entity_id string
---@param distance integer Cells along `side`; intermediate cells are ignored.
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.teleport(entity_id, distance, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.MOVE,
		turn_action = const.TURN_ACTIONS.TELEPORT,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			distance = distance,
		},
	}
end


---@param entity_id string
---@param distance integer
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.knockback_move(entity_id, distance, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.KNOCKBACK,
		turn_action = const.TURN_ACTIONS.MOVE,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			distance = distance,
		},
	}
end


---@param entity_id string
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.wait(entity_id, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.MOVE,
		turn_action = const.TURN_ACTIONS.MOVE,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			distance = 0,
		},
	}
end


---@param entity_id string
---@param damage number
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.damage(entity_id, damage, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.ATTACK,
		turn_action = const.TURN_ACTIONS.ATTACK,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			damage = damage,
		},
	}
end


---@param entity_id string
---@param damage number
---@param side "up" | "down" | "left" | "right" | "none"?
---@return field.turn_action
function M.support_damage(entity_id, damage, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.SUPPORT,
		turn_action = const.TURN_ACTIONS.ATTACK,
		turn_side = side,
		turn_params = {
			damage = damage,
		},
	}
end


---@param entity_id string
---@param side "up" | "down" | "left" | "right" | "none"
---@param prefab_id string
---@param extra_params table|nil e.g. { delta_i, delta_j, side? } — offset in facing frame; optional `side` overrides facing for that spawn (default: action side)
---@return field.turn_action
function M.spawn_entity(entity_id, side, prefab_id, extra_params)
	local turn_params = {
		prefab_id = prefab_id,
	}
	if extra_params then
		for key, value in pairs(extra_params) do
			turn_params[key] = value
		end
	end

	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.MOVE,
		turn_action = const.TURN_ACTIONS.SPAWN_ENTITY,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = turn_params,
	}
end


---@param entity_id string
---@param distance integer
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.knockback_attack(entity_id, distance, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.ATTACK,
		turn_action = const.TURN_ACTIONS.KNOCKBACK_ATTACK,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			distance = distance,
		},
	}
end


---@param entity_id string
---@param distance integer
---@param side "up" | "down" | "left" | "right" | "none"
---@return field.turn_action
function M.support_knockback(entity_id, distance, side)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.SUPPORT,
		turn_action = const.TURN_ACTIONS.SUPPORT_KNOCKBACK,
		turn_side = side or const.TURN_SIDE.NONE,
		turn_params = {
			distance = distance,
		},
	}
end


---@param entity_id string
---@param params table
---@return field.turn_action
function M.set_state(entity_id, params)
	return {
		entity_id = entity_id,
		turn_step = const.TURN_STEPS.MOVE,
		turn_action = const.TURN_ACTIONS.SET_STATE,
		turn_params = params,
	}
end


return M
