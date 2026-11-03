local audio_state = require("audio.internal.audio_state")
local audio_logger = require("audio.internal.audio_logger")
local audio_internal = require("audio.internal.audio_internal")

---@class audio
local M = {}

local DEFAULT_PLAY_COOLDOWN = 4 / 60


---@param sounds table<string, audio.sound>|nil
function M.init(sounds)
	audio_internal.set_sounds(sounds)

	for group, value in pairs(audio_state.get_state().groups) do
		sound.set_group_gain(group, audio_internal.to_engine_gain(value))
	end
end


---@return audio.state
function M.get_state()
	return audio_state.get_state()
end


---@param new_state audio.state
function M.set_state(new_state)
	audio_state.set_state(new_state)
end


function M.reset_state()
	audio_state.reset()
	audio_internal.reset_runtime()
end


---@param logger_instance audio.logger|table|nil
function M.set_logger(logger_instance)
	audio_logger.set_logger(logger_instance)
end


---@param group string
---@param linear_value number|nil
function M.set_gain(group, linear_value)
	local value = audio_internal.clamp01(linear_value)
	audio_state.set_group_gain(group, value)
	sound.set_group_gain(group, audio_internal.to_engine_gain(value))
end


---@param group string
---@return number
function M.get_gain(group)
	return audio_state.get_group_gain(group)
end


---@param id string
---@param gain number|nil
function M.play(id, gain)
	local runtime = audio_internal.get_runtime()
	local sound_config = audio_internal.get_sound_config(id)
	if not sound_config then
		return
	end

	local play_cooldown = sound_config.play_cooldown
	if play_cooldown == nil then
		play_cooldown = DEFAULT_PLAY_COOLDOWN
	end

	local max_instances = sound_config.max_instances
	local playing_instances = runtime.playing[id] or 0
	if max_instances and max_instances > 0 and playing_instances >= max_instances then
		M.stop(id)
		playing_instances = 0
	end

	if play_cooldown > 0 then
		local now = socket.gettime()
		local last_play_time = runtime.last_play_time[id]
		if last_play_time and (now - last_play_time) < play_cooldown then
			return
		end
		runtime.last_play_time[id] = now
	end

	local url = audio_internal.choose_url(sound_config)
	local engine_gain = runtime.last_gains[id] or audio_internal.to_engine_gain(1)
	local speed = 1

	if gain ~= nil then
		engine_gain = audio_internal.to_engine_gain(audio_internal.clamp01(gain))
	end

	if sound_config.random_pitch and sound_config.random_pitch > 0 then
		speed = 1 + (math.random() * 2 - 1) * sound_config.random_pitch
	end

	runtime.props.gain = engine_gain
	runtime.props.speed = speed
	local play_generation = runtime.playing_generation[id] or 0
	runtime.playing[id] = playing_instances + 1
	sound.play(url, runtime.props, function()
		if (runtime.playing_generation[id] or 0) ~= play_generation then
			return
		end
		local current_instances = runtime.playing[id] or 0
		runtime.playing[id] = math.max(0, current_instances - 1)
	end)

	audio_internal.set_sound_gain_engine(id, engine_gain)
end


---@param id string
---@param target_gain number
---@param time number|nil
function M.fade(id, target_gain, time)
	local runtime = audio_internal.get_runtime()
	local sound_config = audio_internal.get_sound_config(id)
	if not sound_config then
		return
	end

	local from = runtime.last_gains[id]
	if not from then
		from = audio_internal.to_engine_gain(1)
		audio_internal.set_sound_gain_engine(id, from)
	end

	local target = audio_internal.to_engine_gain(audio_internal.clamp01(target_gain))
	if not time or time <= 0 then
		runtime.fades[id] = nil
		audio_internal.set_sound_gain_engine(id, target)
		return
	end

	local step = math.abs(target - from) * audio_internal.get_fade_dt() / time
	if step <= 0 then
		runtime.fades[id] = nil
		audio_internal.set_sound_gain_engine(id, target)
		return
	end

	runtime.fades[id] = {
		id = id,
		value = from,
		target = target,
		step = step,
	}

	audio_internal.ensure_fade_timer()
end


---@param id string
---@return boolean
function M.is_playing(id)
	return (audio_internal.get_runtime().playing[id] or 0) > 0
end


---@param id string
function M.stop(id)
	local runtime = audio_internal.get_runtime()
	local sound_config = audio_internal.get_sound_config(id)
	if not sound_config then
		return
	end

	runtime.fades[id] = nil
	runtime.playing_generation[id] = (runtime.playing_generation[id] or 0) + 1

	local urls = sound_config.url
	if type(urls) == "table" then
		for _, url in ipairs(urls) do
			sound.stop(url)
		end
		runtime.playing[id] = 0
		return
	end

	sound.stop(urls)
	runtime.playing[id] = 0
end


return M
