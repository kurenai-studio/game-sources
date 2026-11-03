local event = require("event.event")
local audio = require("audio.audio")
local decore = require("decore.decore")

local music_command = require("system.music.music_command")

---@class entity
---@field music component.music|nil

---@class entity.music: entity
---@field music component.music

---@class component.music
decore.register_component("music", {})

---@class system.music: system
---@field on_beat event Each beat, which supposed to be start of turn step
local M = {}

local BPM = 100
M.BEAT_TIME = 0.6
M.TURN_TIME = M.BEAT_TIME * 4
local MUSIC_TIME = 0.6 * 4 * 8
local BEAT_OFFSET = 0

local MUSIC_START_DELAY = 0.1

---@return system.music
function M.create()
	local self = decore.system(M, "music", { "music" })
	self.on_beat = event.create()
	self._timer_id = nil
	self._timer_beat_id = nil
	self._timer_beat_offset_id = nil
	self._last_beat_time = 0

	music_command.register(self)
	return self
end


function M:onAddToWorld()
	-- Kind of prewarm?? looks weird but still it's better
	audio.set_gain("master", 0)
	audio.play("music_bass", 0)
	audio.play("music_idle", 0)
	audio.play("music_battle", 0)
	self.beat_counter = 0

	timer.delay(MUSIC_START_DELAY, false, function()
		audio.stop("music_bass")
		audio.stop("music_idle")
		audio.stop("music_battle")

		audio.set_gain("master", 1)
		audio.play("music_bass", 1)
		audio.play("music_idle", 0)
		audio.play("music_battle", 0)

		self._timer_id = timer.delay(MUSIC_TIME, true, function()
			audio.play("music_bass")
			audio.play("music_idle")
			audio.play("music_battle")
		end)

		self._timer_beat_id = timer.delay(M.BEAT_TIME, true, function()
			self.beat_counter = self.beat_counter + 1
			local bar_beat_counter = (self.beat_counter - 1) % 4 + 1
			self.on_beat:trigger(bar_beat_counter)
			self._last_beat_time = socket.gettime()
		end)
		timer.trigger(self._timer_beat_id)
	end)
end


function M:onRemoveFromWorld()
	if self._timer_id then
		timer.cancel(self._timer_id)
		self._timer_id = nil
	end
	if self._timer_beat_offset_id then
		timer.cancel(self._timer_beat_offset_id)
		self._timer_beat_offset_id = nil
	end
	if self._timer_beat_id then
		timer.cancel(self._timer_beat_id)
		self._timer_beat_id = nil
	end
end


---@return number
function M:get_time_to_next_beat()
	return M.BEAT_TIME - (socket.gettime() - self._last_beat_time)
end


-- Return the seconds the next main beat is in the future (the index beat is 1)
---@return number
function M:get_time_to_next_main_beat()
	local beats_to_next_main = 4 - (self.beat_counter % 4)
	return self:get_time_to_next_beat() + (beats_to_next_main - 1) * M.BEAT_TIME
end


return M
