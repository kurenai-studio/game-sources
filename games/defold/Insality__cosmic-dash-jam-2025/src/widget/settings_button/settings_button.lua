local event = require("event.event")

---@class widget.settings_button: druid.widget
local M = {}


function M:init()
	self.on_click = event.create()

	self.layout = self.druid:new_layout("button", "horizontal")
		:add("text")
		:add("icon")

	self.button = self.druid:new_button("button", self.on_click)
end


function M:on_language_change()
	self.layout:set_dirty()
end


return M
