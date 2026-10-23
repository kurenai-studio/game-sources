local saver = require("saver.saver")
local decore = require("decore.decore")
local command_sound = require("system.sound.sound_command")

local IS_DEBUG = sys.get_engine_info().is_debug

---@class system.sound.state
---@field sound_volume number
---@field music_volume number

---@class system.sound: system
---@field entities entity[]
---@field state system.sound.state
---@field runtime table
---@field current_music string|nil
local M = {}


---@return system.sound
function M.create_system()
	local self = decore.system(M, "sound")

	self.state = {
		sound_volume = IS_DEBUG and 1 or 1,
		music_volume = IS_DEBUG and 1 or 1,
	}

	self.runtime = {
		props = { gain = 1, speed = 1 },
		last_gains = {},
		times = {},
		fades = {},
	}

	return self
end


---@param sound_id string
---@return string
local function get_sound_url(sound_id)
	return "game:/sound#" .. sound_id
end


---@param self system.sound
---@param sound_id string
---@param gain number
local function set_gain(self, sound_id, gain)
	sound.set_gain(get_sound_url(sound_id), gain)
	self.runtime.last_gains[sound_id] = gain
end


function M:onAddToWorld()
	---@class saver.game_state
	---@field sound system.sound.state
	saver.bind_save_state("sound", self.state)

	self.world.sound = command_sound.create(self)

	self:set_music_gain(self.state.music_volume)
	self:set_sound_gain(self.state.sound_volume)
end


function M:update(dt)
	local fades = self.runtime.fades
	for index, fade in ipairs(fades) do
		fade.gain = fade.gain + fade.step
		set_gain(self, fade.sound_id, fade.gain)

		if fade.gain >= fade.to then
			table.remove(fades, index)
		end
	end
end


---Play the sound in the game
---@param sound_id string
---@param gain number|nil
---@param speed number|nil
function M:play(sound_id, gain, speed)
	gain = gain or self.runtime.last_gains[sound_id] or 1
	speed = speed or 1

	if self.state.sound_volume == 0 then
		return
	end

	local sound_times = self.runtime.times
	local threshold = 0.05

	if sound_times[sound_id] and (socket.gettime() - sound_times[sound_id]) < threshold then
		return
	end

	self.runtime.props.gain = gain
	self.runtime.props.speed = speed
	sound.play(get_sound_url(sound_id), self.runtime.props)

	sound_times[sound_id] = socket.gettime()
end


---Play the random sound from sound names array
---@param sound_ids string[]
---@param gain number|nil
function M:play_random(sound_ids, gain)
	local sound_id = sound_ids[math.random(1, #sound_ids)]
	self:play_random_speed(sound_id, gain)
end


---Play the random sound from sound names array with random speed
---@param sound_id string
---@param gain number|nil
---@param speed_delta number|nil
function M:play_random_speed(sound_id, gain, speed_delta)
	gain = gain or 1
	speed_delta = speed_delta or 0.2

	local speed = 1 + (math.random() - 0.5) * speed_delta
	self:play(sound_id, gain, speed)
end


---Stop sound playing
---@param sound_id string
function M:stop(sound_id)
	sound.stop(get_sound_url(sound_id))
end


---Start playing music_game
---@param music_url string
---@param gain number|nil
---@param on_end_play_callback function|nil
function M:play_music(music_url, gain, on_end_play_callback)
	local prev_music = self.current_music

	local is_stop_music = false

	if is_stop_music then
		self:stop_music()
		if prev_music then
			gain = gain or self.runtime.last_gains[prev_music]
		end
	end

	gain = gain or 1
	--gain = gain * self.state.music_volume

	self.current_music = music_url
	set_gain(self, self.current_music, gain)
	sound.play(get_sound_url(self.current_music), { gain = gain }, on_end_play_callback)
end


---Stop playing music
function M:stop_music()
	if self.current_music then
		sound.stop(get_sound_url(self.current_music))
		self.current_music = nil
	end
end


---Fade sound from one gain to another
---@param sound_id string
---@param to number
---@param time number
function M:fade(sound_id, to, time)
	local from = self.runtime.last_gains[sound_id] or 1
	set_gain(self, sound_id, from)

	local gain = from
	local delta = math.abs(to - from)
	local step = delta * (1/60) / time

	table.insert(self.runtime.fades, {
		sound_id = sound_id,
		gain = gain,
		step = step,
		to = to,
	})
end


---Slowly fade music to another one or empty
---@param to number
---@param time number|nil
---@param callback function|nil
function M:fade_music(to, time, callback)
	if self.current_music then
		time = time or 1
		self:fade(self.current_music, to, time)
		if callback then
			timer.delay(time, false, callback)
		end
	else
		if callback then
			callback()
		end
	end
end


---Stop all sounds in the game
function M:stop_all()
	self:stop_music()
end


---Set music gain
---@param value number
function M:set_music_gain(value)
	self.state.music_volume = value
	sound.set_group_gain("music", value)
end


---Set sound gain
---@param value number
function M:set_sound_gain(value)
	self.state.sound_volume = value
	sound.set_group_gain("sound", value)
end


--- The same as sound.set_gain, but linear scale for gain
---@param url url
---@param linear_value number
function M:set_gain(url, linear_value)
	-- Value is a number from 0 to 1
	-- but for gain for sounds, we need to use other to make volume linear
	local gain = linear_value ^ 2
	sound.set_gain(url, gain)
end


---Get music gain
---@return number
function M:get_music_gain()
	return self.state.music_volume
end


---Get sound gain
---@return number
function M:get_sound_gain()
	return self.state.sound_volume
end


---Check music gain
---@return boolean
function M:is_music_enabled()
	return self:get_music_gain() > 0
end


---Check sound gain
---@return boolean
function M:is_sound_enabled()
	return self:get_sound_gain() > 0
end


return M

