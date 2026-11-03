local M = {}

M.TURN_RESULT_TYPE = {
	MOVE = "move",
	MOVE_BLOCKED = "move_blocked",
	KNOCKBACK_MOVE = "knockback_move",
	KNOCKBACK_MOVE_BLOCKED = "knockback_move_blocked",
	SET_STATE = "set_state",
	ATTACK_CELL = "attack_cell",
	DAMAGE = "damage",
	DIE = "die",
	SPAWN = "spawn",
	ENTITY_COLLISION = "entity_collision",
	REMOVE_ENTITY = "remove_entity",
}

M.DIE_TYPE = {
	DAMAGE = "damage",
	FALL = "fall",
	OOB = "oob",
}

---@class field.turn_result
---@field entity_id string Attacker for ATTACK_CELL; damaged entity for DAMAGE; mover for MOVE; first id for ENTITY_COLLISION.
---@field other_entity_id string|nil Second entity for ENTITY_COLLISION.
---@field target_i integer
---@field target_j integer
---@field side string?
---@field type string
---@field damage number|nil ATTACK_CELL / DAMAGE amount
---@field source_entity_id string|nil DIE source entity id
---@field die_type string|nil DIE reason from DIE_TYPE
---@field state table|nil SET_STATE payload
---@field prefab_id string|nil SPAWN prefab id for ECS spawn
---@field spawned_entity_id string|number|nil SPAWN spawned entity id
---@field resolver_id string|nil Resolver source id (e.g. "teleport")

---@param entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@return field.turn_result
function M.move(entity_id, target_i, target_j, side)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.MOVE,
		target_i = target_i,
		target_j = target_j,
		side = side,
	}
end


function M.move_blocked(entity_id, target_i, target_j, side)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.MOVE_BLOCKED,
		target_i = target_i,
		target_j = target_j,
		side = side,
	}
end


---@param entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@return field.turn_result
function M.knockback_move(entity_id, target_i, target_j, side)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.KNOCKBACK_MOVE,
		target_i = target_i,
		target_j = target_j,
		side = side,
	}
end


---@param entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@return field.turn_result
function M.knockback_move_blocked(entity_id, target_i, target_j, side)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.KNOCKBACK_MOVE_BLOCKED,
		target_i = target_i,
		target_j = target_j,
		side = side,
	}
end


---@param entity_id string
---@param state table
---@return field.turn_result
function M.set_state(entity_id, state)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.SET_STATE,
		state = state,
	}
end


---@param attacker_entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@param damage number
---@return field.turn_result
function M.attack_cell(attacker_entity_id, target_i, target_j, side, damage)
	return {
		entity_id = attacker_entity_id,
		type = M.TURN_RESULT_TYPE.ATTACK_CELL,
		target_i = target_i,
		target_j = target_j,
		side = side,
		damage = damage,
	}
end


---@param entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@param damage number
---@return field.turn_result
function M.damage(entity_id, target_i, target_j, side, damage)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.DAMAGE,
		target_i = target_i,
		target_j = target_j,
		side = side,
		damage = damage,
	}
end


---@param entity_id string
---@param source_entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@param die_type string|nil
---@return field.turn_result
function M.die(entity_id, source_entity_id, target_i, target_j, side, die_type)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.DIE,
		source_entity_id = source_entity_id,
		target_i = target_i,
		target_j = target_j,
		side = side,
		die_type = die_type or M.DIE_TYPE.DAMAGE,
	}
end


---@param entity_id string
---@return field.turn_result
function M.remove_entity(entity_id)
	return {
		entity_id = entity_id,
		type = M.TURN_RESULT_TYPE.REMOVE_ENTITY,
	}
end


---@param who_spawn_entity_id string
---@param target_i integer
---@param target_j integer
---@param side string
---@param prefab_id string|nil
---@param spawned_entity_id string|number|nil
---@return field.turn_result
function M.spawn(who_spawn_entity_id, target_i, target_j, side, prefab_id, spawned_entity_id)
	return {
		entity_id = who_spawn_entity_id,
		type = M.TURN_RESULT_TYPE.SPAWN,
		target_i = target_i,
		target_j = target_j,
		side = side,
		prefab_id = prefab_id,
		spawned_entity_id = spawned_entity_id,
	}
end


---@param entity_id string
---@param other_entity_id string
---@param target_i integer
---@param target_j integer
---@return field.turn_result
function M.entity_collision(entity_id, other_entity_id, target_i, target_j)
	return {
		entity_id = entity_id,
		other_entity_id = other_entity_id,
		type = M.TURN_RESULT_TYPE.ENTITY_COLLISION,
		target_i = target_i,
		target_j = target_j,
	}
end


return M
