local audio = require("audio.audio")

---@class system.music.command
---@field music system.music
---@field on_beat event Each beat, which supposed to be start of turn step
local M = {}
M.BEAT_TIME = 0.6

local FADE_TIME = 1.2


---@param music system.music
function M.register(music)
	M.music = music
	M.on_beat = music.on_beat
end


function M.set_menu()
	audio.fade("music_bass", 1, FADE_TIME)
	audio.fade("music_idle", 0, FADE_TIME)
	audio.fade("music_battle", 0, FADE_TIME)
end


function M.set_game()
	audio.fade("music_bass", 0.6, FADE_TIME)
	audio.fade("music_idle", 1, FADE_TIME)
	audio.fade("music_battle", 0, FADE_TIME)
end


function M.set_battle()
	audio.fade("music_bass", 0, FADE_TIME)
	audio.fade("music_idle", 0, FADE_TIME)
	audio.fade("music_battle", 1, FADE_TIME)
end


---@return number
function M.get_turn_time()
	return M.music.BEAT_TIME * 4
end


function M.get_next_main_beat_time()
	return M.music:get_time_to_next_main_beat()
end


return M
