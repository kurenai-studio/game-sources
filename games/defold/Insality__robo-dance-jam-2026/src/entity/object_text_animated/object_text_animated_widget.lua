local text_animated = require("widget.text_animated.text_animated")

---@class widget.object_text_animated_widget: druid.widget
local M = {}


function M:init()
	gui.set_render_order(11)
	self.root = self:get_node("root")
	self.text_animated = self.druid:new_widget(text_animated, "text_animated")
	self._text_id = nil
end


---@param world_position vector3
function M:set_position(world_position)
	gui.set_position(self.root, world_position)
end


---@param color_id string
function M:set_color(color_id)
	self.text_animated:set_color(color_id)
end


---@param text string
function M:set_text(text)
	self._text_id = text
end


function M:on_music_beat(bar_beat_counter)
	if not self._text_id then
		return
	end

	if bar_beat_counter == 1 then
		self.text_animated:animate_text(self._text_id)
	end
end


return M
