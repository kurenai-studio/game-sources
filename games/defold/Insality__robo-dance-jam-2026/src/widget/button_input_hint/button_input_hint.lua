local helper = require("druid.helper")
local events = require("event.events")

---@class widget.button_input_hint: druid.widget
local M = {}

local IS_SUPPORTED = not (helper.is_mobile() or helper.is_web_mobile())

function M:init()
	self.root = self:get_node("root")

	self:set_enabled(true)
	self:set_appear(false, true)

	events.subscribe("show_input_hint", self.on_show_input_hint, self)
end


function M:on_remove()
	events.unsubscribe("show_input_hint", self.on_show_input_hint, self)
end


function M:set_enabled(enabled)
	gui.set_enabled(self.root, enabled)
end


function M:set_appear(appear, is_instant)
	if is_instant then
		gui.set_alpha(self.root, appear and 1 or 0)
		return
	end

	gui.animate(self.root, "color.w", appear and 1 or 0, gui.EASING_OUTSINE, 0.6)
end


function M:on_show_input_hint(appear)
	if not IS_SUPPORTED then
		return
	end

	self:set_appear(appear)
end


return M
