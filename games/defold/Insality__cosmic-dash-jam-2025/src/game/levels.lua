local log = require("log.log")

---@class game.const.level
---@field level_id string "level_1_1"
---@field text string "level_header_1_1"
---@field path string "/tiled/export/level_1_1.json"
---@field text_hint string "level_hint_1_1"
---@field background string "bg_stars"
---@field index number 1
---@field color color "level_1"

---@class game.const.level[]


local M = {
	{ level_id = "level_1_1", path = "/tiled/export/level_1_1.json", text = "level_header_1_1", text_hint = "level_hint_1_1", index = 1, color = "level_1" },
	{ level_id = "level_1_2", path = "/tiled/export/level_1_2.json", text = "level_header_1_2", text_hint = "level_hint_1_2", index = 2, color = "level_1" },
	{ level_id = "level_1_3", path = "/tiled/export/level_1_3.json", text = "level_header_1_3", text_hint = "level_hint_1_3", index = 3, color = "level_1" },
	{ level_id = "level_1_4", path = "/tiled/export/level_1_4.json", text = "level_header_1_4", text_hint = "level_hint_1_4", index = 4, color = "level_1" },
	{ level_id = "level_1_5", path = "/tiled/export/level_1_5.json", text = "level_header_1_5", text_hint = "level_hint_1_5", index = 5, color = "level_1" },

	{ level_id = "level_2_1", path = "/tiled/export/level_2_1.json", text = "level_header_2_1", text_hint = "level_hint_2_1", index = 1, color = "level_2" },
	{ level_id = "level_2_2", path = "/tiled/export/level_2_2.json", text = "level_header_2_2", text_hint = "level_hint_2_2", index = 2, color = "level_2" },
	{ level_id = "level_2_3", path = "/tiled/export/level_2_3.json", text = "level_header_2_3", text_hint = "level_hint_2_3", index = 3, color = "level_2" },
	{ level_id = "level_2_4", path = "/tiled/export/level_2_4.json", text = "level_header_2_4", text_hint = "level_hint_2_4", index = 4, color = "level_2" },
	{ level_id = "level_2_5", path = "/tiled/export/level_2_5.json", text = "level_header_2_5", text_hint = "level_hint_2_5", index = 5, color = "level_2" },

	{ level_id = "level_3_1", path = "/tiled/export/level_3_1.json", text = "level_header_3_1", text_hint = "level_hint_3_1", index = 1, color = "level_3" },
	{ level_id = "level_3_2", path = "/tiled/export/level_3_2.json", text = "level_header_3_2", text_hint = "level_hint_3_2", index = 2, color = "level_3" },
	{ level_id = "level_3_3", path = "/tiled/export/level_3_3.json", text = "level_header_3_3", text_hint = "level_hint_3_3", index = 3, color = "level_3" },
	{ level_id = "level_3_4", path = "/tiled/export/level_3_4.json", text = "level_header_3_4", text_hint = "level_hint_3_4", index = 4, color = "level_3" },
	{ level_id = "level_3_5", path = "/tiled/export/level_3_5.json", text = "level_header_3_5", text_hint = "level_hint_3_5", index = 5, color = "level_3" },

	{ level_id = "level_4_1", path = "/tiled/export/level_4_1.json", text = "level_header_4_1", text_hint = "level_hint_4_1", index = 1, color = "level_4" },
	{ level_id = "level_4_2", path = "/tiled/export/level_4_2.json", text = "level_header_4_2", text_hint = "level_hint_4_2", index = 2, color = "level_4" },
	{ level_id = "level_4_3", path = "/tiled/export/level_4_3.json", text = "level_header_4_3", text_hint = "level_hint_4_3", index = 3, color = "level_4" },
	{ level_id = "level_4_4", path = "/tiled/export/level_4_4.json", text = "level_header_4_4", text_hint = "level_hint_4_4", index = 4, color = "level_4" },
	{ level_id = "level_4_5", path = "/tiled/export/level_4_5.json", text = "level_header_4_5", text_hint = "level_hint_4_5", index = 5, color = "level_4" },

	{ level_id = "level_5_1", path = "/tiled/export/level_5_1.json", text = "level_header_5_1", text_hint = "level_hint_5_1", index = 1, color = "level_5" },
	{ level_id = "level_5_2", path = "/tiled/export/level_5_2.json", text = "level_header_5_2", text_hint = "level_hint_5_2", index = 2, color = "level_5" },
	{ level_id = "level_5_3", path = "/tiled/export/level_5_3.json", text = "level_header_5_3", text_hint = "level_hint_5_3", index = 3, color = "level_5" },
	{ level_id = "level_5_4", path = "/tiled/export/level_5_4.json", text = "level_header_5_4", text_hint = "level_hint_5_4", index = 4, color = "level_5" },
	{ level_id = "level_5_5", path = "/tiled/export/level_5_5.json", text = "level_header_5_5", text_hint = "level_hint_5_5", index = 5, color = "level_5" },
}


---@class game.level.state
---@field stars number[]
---@field completed boolean

---@class game.levels.state
---@field levels table<string, game.level.state>
---@field current_level_id string

---@type game.levels.state
M.state = {
	levels = {},
	current_level_id = "level_1_1",
}
M.runtime = {
	collected_stars = {}  -- Stars collected in current level session
}

---@param level_id string?
function M.get_stars_count(level_id)
	if not level_id then
		local count = 0
		for _, star_id in pairs(M.runtime.collected_stars) do
			count = count + 1
		end

		return count
	end

	level_id = level_id
	local level_state = M.state.levels[level_id]
	if level_state and level_state.stars then
		return #level_state.stars
	end

	return 0
end


---@return number, number
function M.get_total_stars_count()
	local count = 0
	local total_levels = #M * 3
	for _, level in pairs(M.state.levels) do
		if level.stars then
			local stars = #level.stars
			if stars > 3 then
				stars = 3
			end
			count = count + stars
		end
	end
	return count, total_levels
end


---@param tiled_id string|number
function M.collect_star(tiled_id)
	local level_id = M.state.current_level_id

	M.runtime.collected_stars[tiled_id] = true
	log:info("Collect star", { level_id = level_id, tiled_id = tiled_id })
end


---@return string
function M.get_current_level_id()
	return M.state.current_level_id
end


---@param level_id string
function M.set_current_level_id(level_id)
	assert(M.get_level_by_id(level_id), "Level not found " .. level_id)
	M.state.current_level_id = level_id
end


function M.get_level_by_id(level_id)
	for _, level in pairs(M) do
		if level.level_id == level_id then
			return level
		end
	end
end


---@param tiled_id string|number
function M.is_star_collected(tiled_id)
	local level_id = M.state.current_level_id
	local stars = M.state.levels[level_id] and M.state.levels[level_id].stars or {}
	for _, star_id in pairs(stars) do
		if star_id == tiled_id then
			return true
		end
	end
	return false
end


function M.on_level_started(level_id)
	M.set_current_level_id(level_id)

	M.runtime.collected_stars = {}

	M.state.levels[M.state.current_level_id] = M.state.levels[M.state.current_level_id] or {}
	local level_state = M.state.levels[M.state.current_level_id]

	if level_state.stars then
		for _, star_id in pairs(level_state.stars) do
			M.runtime.collected_stars[star_id] = true
		end
	end
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
	local current_index = M.get_level_index(M, current_level_id) or 1

	local next_index = current_index + 1
	if next_index > #M then
		next_index = 1
	end

	return M[next_index]
end


---@return game.const.level
function M.get_previous_level()
	local current_level_id = M.get_current_level_id()
	local current_index = M.get_level_index(M, current_level_id) or 1

	local previous_index = current_index - 1
	if previous_index < 1 then
		previous_index = #M
	end

	return M[previous_index]
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
	M.state.levels[level_id].completed = true

	M.state = M.state or {}
	M.state.levels = M.state.levels or {}
	M.state.levels[level_id] = M.state.levels[level_id] or {}
	M.state.levels[level_id].stars = M.state.levels[level_id].stars or {}

	local stars = M.state.levels[level_id].stars or {}

	local function add_star(new_star_id)
		for _, star_id in pairs(stars) do
			if star_id == new_star_id then
				return
			end
		end
		table.insert(stars, new_star_id)
	end

	for star_id in pairs(M.runtime.collected_stars) do
		add_star(star_id)
	end

	-- Max 3 stars
	while #stars > 3 do
		table.remove(stars, 1)
	end
end


return M
