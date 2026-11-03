local log = require("log.log")

---@class game.const.level
---@field level_id string "level_1"
---@field path string "/tiled/level_1.json"
---@field index number 1

---@class game.levels
local M = {}

M.LEVELS = {
	{ level_id = "level_1", path = "/tiled/levels/level_simple_saw.json", index = 1 },
	{ level_id = "level_2", path = "/tiled/levels/level_saw_spiral.json", index = 2 },
	{ level_id = "level_3", path = "/tiled/levels/level_saw_spikes_line.json", index = 3 },
	{ level_id = "level_4", path = "/tiled/levels/level_saw_attack.json", index = 4 },
	{ level_id = "level_5", path = "/tiled/levels/level_enemy_attack.json", index = 5 },

	{ level_id = "level_6", path = "/tiled/levels/level_enemy_saw_throw.json", index = 6 },
	{ level_id = "level_7", path = "/tiled/levels/level_first_turret.json", index = 7 },
	{ level_id = "level_8", path = "/tiled/levels/level_turret_spikes_puzzle.json", index = 8 },
	{ level_id = "level_9", path = "/tiled/levels/level_teleport.json", index = 9 },
	{ level_id = "level_10", path = "/tiled/levels/level_teleport_bridge.json", index = 10 },

	{ level_id = "level_11", path = "/tiled/levels/level_teleport_assasin.json", index = 11 },
	{ level_id = "level_12", path = "/tiled/levels/level_boxes_simple.json", index = 12 },
	{ level_id = "level_13", path = "/tiled/levels/level_boxes_line.json", index = 13 },
	{ level_id = "level_14", path = "/tiled/levels/level_field_massive.json", index = 14 },
	{ level_id = "level_15", path = "/tiled/levels/level_15.json", index = 15 },
}


---@class game.level.state
---@field completed boolean

---@class game.levels.state
---@field levels table<string, game.level.state>
---@field current_level_id string

---@type game.levels.state
M.state = {
	levels = {},
	current_level_id = "level_1",
}


---@return string
function M.get_current_level_id()
	return M.state.current_level_id
end


---@return number
function M.get_current_level_index()
	return M.get_level_index(M.LEVELS, M.state.current_level_id) or 1
end


---@param level_id string
function M.set_current_level_id(level_id)
	assert(M.get_level_by_id(level_id), "Level not found " .. level_id)
	M.state.current_level_id = level_id
end


function M.get_level_by_id(level_id)
	for _, level in pairs(M.LEVELS) do
		if level.level_id == level_id then
			return level
		end
	end

	log:warn("Level not found", level_id)
	return nil
end


function M.on_level_started(level_id)
	M.set_current_level_id(level_id)
	M.state.levels[M.state.current_level_id] = M.state.levels[M.state.current_level_id] or {}
end


---@param levels_array table
---@param value any
---@return number|nil
function M.get_level_index(levels_array, value)
	for index, array_value in pairs(levels_array) do
		if value == array_value.level_id then
			return index
		end
	end

	return nil
end


---@return game.const.level
function M.get_next_level()
	local current_level_id = M.get_current_level_id()
	local current_index = M.get_level_index(M.LEVELS, current_level_id) or 1

	local next_index = current_index + 1
	if next_index > #M.LEVELS then
		next_index = 1
	end

	return M.LEVELS[next_index]
end


---@return game.const.level
function M.get_previous_level()
	local current_level_id = M.get_current_level_id()
	local current_index = M.get_level_index(M.LEVELS, current_level_id) or 1

	local previous_index = current_index - 1
	if previous_index < 1 then
		previous_index = #M.LEVELS
	end

	return M.LEVELS[previous_index]
end


function M.is_prev_level_available()
	local previous_level = M.get_previous_level()
	local state = M.state.levels[previous_level.level_id]
	local is_completed = state and state.completed
	return is_completed
end


function M.is_next_level_available()
	local next_level = M.get_next_level()
	local state = M.state.levels[next_level.level_id]
	local is_completed = state and state.completed
	return is_completed
end


function M.on_level_completed()
	local level_id = M.state.current_level_id

	M.state.levels[level_id] = M.state.levels[level_id] or {}
	M.state.levels[level_id].completed = true
end


return M
