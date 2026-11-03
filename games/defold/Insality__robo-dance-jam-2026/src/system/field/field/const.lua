local M = {}

---Inclusive grid indices for field logic (knockback / support cleanup).
M.GRID_INDEX_MIN = 0
M.GRID_INDEX_MAX = 7

M.TURN_STEPS = {
	MOVE = "move",
	ATTACK = "attack",
	KNOCKBACK = "knockback",
	SUPPORT = "support",
}

M.TURN_ACTIONS = {
	MOVE = "move",
	TELEPORT = "teleport",
	ATTACK = "attack",
	KNOCKBACK_ATTACK = "knockback_attack",
	SUPPORT_KNOCKBACK = "support_knockback",
	SET_STATE = "set_state",
	SPAWN_ENTITY = "spawn_entity",
}

M.TURN_RESULT_ACTION = {
	MOVE = "move",
	MOVE_BLOCKED = "move_blocked",
}

M.TURN_SIDE = {
	NONE = "none",
	UP = "up",
	DOWN = "down",
	LEFT = "left",
	RIGHT = "right",
}

---@class field.turn_side_data
---@field i number
---@field j number
---@field opposite string
---@field id string
M.TURN_SIDE_DATA = {
	[M.TURN_SIDE.NONE] = { i = 0, j = 0, opposite = M.TURN_SIDE.NONE, id = M.TURN_SIDE.NONE },
	[M.TURN_SIDE.UP] = { i = 0, j = 1, opposite = M.TURN_SIDE.DOWN, id = M.TURN_SIDE.UP },
	[M.TURN_SIDE.DOWN] = { i = 0, j = -1, opposite = M.TURN_SIDE.UP, id = M.TURN_SIDE.DOWN },
	[M.TURN_SIDE.LEFT] = { i = -1, j = 0, opposite = M.TURN_SIDE.RIGHT, id = M.TURN_SIDE.LEFT },
	[M.TURN_SIDE.RIGHT] = { i = 1, j = 0, opposite = M.TURN_SIDE.LEFT, id = M.TURN_SIDE.RIGHT },
}

return M
