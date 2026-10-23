---@class world
---@field sound system.sound.command

---@class system.sound.command
---@field sound system.sound
---@field world world
local M = {}


---@param sound_system system.sound
---@return system.sound.command
function M.create(sound_system)
	return setmetatable({ sound = sound_system, world = sound_system.world }, { __index = M })
end


---Play the sound in the game
---@param sound_id string
---@param gain number|nil
---@param speed number|nil
function M:play(sound_id, gain, speed)
	self.sound:play(sound_id, gain, speed)
end


---Play the random sound from sound names array
---@param sound_ids string[]
---@param gain number|nil
function M:play_random(sound_ids, gain)
	self.sound:play_random(sound_ids, gain)
end


---Play the random sound from sound names array with random speed
---@param sound_id string
---@param gain number|nil
---@param speed_delta number|nil
function M:play_random_speed(sound_id, gain, speed_delta)
	self.sound:play_random_speed(sound_id, gain, speed_delta)
end


---Stop sound playing
---@param sound_id string
function M:stop(sound_id)
	self.sound:stop(sound_id)
end


---Start playing music
---@param music_url string
---@param gain number|nil
---@param on_end_play_callback function|nil
function M:play_music(music_url, gain, on_end_play_callback)
	self.sound:play_music(music_url, gain, on_end_play_callback)
end


---Stop playing music
function M:stop_music()
	self.sound:stop_music()
end


---Fade sound from one gain to another
---@param sound_id string
---@param to number
---@param time number
function M:fade(sound_id, to, time)
	self.sound:fade(sound_id, to, time)
end


---Slowly fade music to another one or empty
---@param to number
---@param time number|nil
---@param callback function|nil
function M:fade_music(to, time, callback)
	self.sound:fade_music(to, time, callback)
end


---Stop all sounds in the game
function M:stop_all()
	self.sound:stop_all()
end


---Set music gain
---@param value number
function M:set_music_gain(value)
	self.sound:set_music_gain(value)
end


---Set sound gain
---@param value number
function M:set_sound_gain(value)
	self.sound:set_sound_gain(value)
end


--- The same as sound.set_gain, but linear scale for gain
---@param url url
---@param linear_value number
function M:set_gain(url, linear_value)
	self.sound:set_gain(url, linear_value)
end


---Get music gain
---@return number
function M:get_music_gain()
	return self.sound:get_music_gain()
end


---Get sound gain
---@return number
function M:get_sound_gain()
	return self.sound:get_sound_gain()
end


---Check music gain
---@return boolean
function M:is_music_enabled()
	return self.sound:is_music_enabled()
end


---Check sound gain
---@return boolean
function M:is_sound_enabled()
	return self.sound:is_sound_enabled()
end


return M

