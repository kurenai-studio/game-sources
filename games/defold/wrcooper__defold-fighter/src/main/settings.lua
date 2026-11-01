-- Player settings that persist between sessions (currently just the volume).
-- Uses Defold APIs, so it lives here rather than in modules/ (which stays engine-free).
local M = {}

M.VOLUME_STEPS = 10
M.volume = 8   -- 0..VOLUME_STEPS

local APP_ID = "defold_fighter"
local save_path = nil

-- the "master" mixer group covers every sound component that doesn't set its own group;
-- its gain is on a decibel scale (1 = 0 dB, 0.5 = -30 dB), so even steps sound even
local function apply()
	sound.set_group_gain("master", M.volume / M.VOLUME_STEPS)end

function M.load()
	local ok, path = pcall(sys.get_save_file, APP_ID, "settings")
	if ok then
		save_path = path
		local loaded, data = pcall(sys.load, path)
		if loaded and type(data.volume) == "number" then
			M.volume = math.max(0, math.min(M.VOLUME_STEPS, math.floor(data.volume)))
		end
	end
	apply()
end

-- returns true if the volume changed
function M.change_volume(delta)
	local v = math.max(0, math.min(M.VOLUME_STEPS, M.volume + delta))
	if v == M.volume then return false end
	M.volume = v
	apply()
	if save_path then pcall(sys.save, save_path, { volume = M.volume }) end
	return true
end

function M.volume_label()
	return M.volume == 0 and "OFF" or (M.volume * 100 / M.VOLUME_STEPS) .. "%"
end

return M
