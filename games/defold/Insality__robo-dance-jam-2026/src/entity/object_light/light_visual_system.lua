local decore = require("decore.decore")

local panthera_command = require("system.panthera.panthera_command")
local music_command = require("system.music.music_command")

---@class entity
---@field light_visual boolean|nil

---@class entity.light_visual: entity
---@field light_visual boolean
---@field game_object component.game_object
---@field transform component.transform

---@class component.light_visual
decore.register_component("light_visual", false)

---@class system.light_visual: system
---@field entities entity.light_visual[]
local M = {}


---@return system.light_visual
function M.create()
	local self = decore.system(M, "light_visual", { "light_visual", "game_object", "transform", "panthera" })
	return self
end


function M:onAddToWorld()
	music_command.on_beat:subscribe(self.on_beat, self)
end


function M:onRemoveFromWorld()
	music_command.on_beat:unsubscribe(self.on_beat, self)
end


function M:on_beat(bar_beat_counter)
	for i = 1, #self.entities do
		panthera_command.play(self.entities[i], "on_beat")
	end
end


return M
