local event = require("event.event")

---@class widget.settings_slider: druid.widget
local M = {}


function M:init()
	self.on_value_changed = event.create()

	self.slider = self.druid:new_slider("pin", vmath.vector3(200, 0, 0), self.on_slider)
	self.slider:set_input_node("slider_back")

	self.progress = self.druid:new_progress("slider_fill", "x")

	self.layout = self.druid:new_layout("group_info", "horizontal")
		:add("text")
		:add("icon")
end


function M:on_slider(value)
	self.progress:set_to(value)
	self.on_value_changed(value)

	gui.set_alpha(self:get_node("icon"), value == 0 and 0.3 or 0.8)
end


function M:set_value(value)
	self.progress:set_to(value)
	self.on_value_changed(value)
	gui.set_alpha(self:get_node("icon"), value == 0 and 0.3 or 0.8)
end


function M:on_language_change()
	self.layout:set_dirty()
end


return M
