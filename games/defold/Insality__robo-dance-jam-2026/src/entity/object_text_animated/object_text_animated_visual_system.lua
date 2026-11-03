local decore = require("decore.decore")

local music_command = require("system.music.music_command")

---@class entity
---@field object_text_animated_visual component.object_text_animated_visual|nil

---@class entity.object_text_animated_visual: entity
---@field object_text_animated_visual component.object_text_animated_visual
---@field game_object component.game_object
---@field druid_widget component.druid_widget

---@class component.object_text_animated_visual
---@field text string
---@field color string|nil
---@field _current_text string|nil
decore.register_component("object_text_animated_visual", {
	text = "",
	_current_text = nil,
})

---@class system.object_text_animated_visual: system
---@field entities entity.object_text_animated_visual[]
local M = {}


---@return system.object_text_animated_visual
function M.create()
	return decore.system(M, "object_text_animated_visual", { "object_text_animated_visual", "game_object", "druid_widget" })
end


function M:onAddToWorld()
	music_command.on_beat:subscribe(self.on_music_beat, self)
end


function M:onAdd(entity)
	local widget = entity.druid_widget.widget --[[@as widget.object_text_animated_widget]]
	widget:set_position(go.get_world_position(entity.game_object.root))
	self:update_text(entity, widget)
end


---@param entity entity.object_text_animated_visual
---@param widget widget.object_text_animated_widget
function M:update_text(entity, widget)
	local visual = entity.object_text_animated_visual
	if visual.text == visual._current_text then
		return
	end

	widget:set_text(visual.text)
	widget:set_color(visual.color)
	visual._current_text = visual.text
end


function M:on_music_beat(bar_beat_counter)
	for i = 1, #self.entities do
		local entity = self.entities[i]
		local widget = entity.druid_widget.widget --[[@as widget.object_text_animated_widget]]
		widget:on_music_beat(bar_beat_counter)
	end
end

return M
