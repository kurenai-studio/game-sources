local event = require("event.event")

---@class widget.button_plan_mode: druid.widget
local M = {}


function M:init()
	self.on_click = event.create()

	self._auto = false

	self.root = self:get_node("root")
	self.text_animated = self.druid:new_lang_text("text", "ui_plan_mode")
	self.button = self.druid:new_button("root", self._on_click)

	self:set_auto(self._auto)
end


function M:_on_click()
	self:set_auto(not self._auto)
	self.on_click:trigger()
end


function M:set_auto(auto)
	self._auto = auto
	if self._auto then
		gui.play_flipbook(self:get_node("button"), "button_action")
	else
		gui.play_flipbook(self:get_node("button"), "button_yellow")
	end
end


function M:get_auto()
	return self._auto
end


return M
