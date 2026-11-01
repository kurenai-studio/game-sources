local M = {}
local state = {}

M.key = {
	LEVEL_BOUNDS = "level_bounds",
	LEVEL_HUD = "level_hud",
	LEVEL_CURRENT = "level_current",
	IS_WIN = "is_win",
	LEVEL_MIN = "level_min",
	LOADING = "loading",
	MUSIC_ENABLED = "music_enabled",
	SOUND_ENABLED = "sound_enabled"
}

function M.set(key, value)
	state[key] = value
end

function M.get(key)
	return state[key]
end

function M.remove(key)
	state[key] = nil
end

function M.has(key)
	return state[key] ~= nil
end

return M