local color = require("druid.color")
local button_input_hint = require("widget.button_input_hint.button_input_hint")

---@class widget.icon_turn_action: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.icon = self:get_node("icon")
	self.outline = self:get_node("outline")
	self.panel = self:get_node("panel")
	self.back = self:get_node("back")

	self.button_input_hint = self.druid:new_widget(button_input_hint, "button_input_hint")
end


---@param color_id string|vector4
function M:set_color(color_id)
	color.set_color(self.back, color_id)
	color.set_color(self:get_node("shadow"), color_id)
end


---@param icon string
function M:set_icon(icon)
	gui.play_flipbook(self.icon, icon)
end


---@param top_layer boolean
function M:set_top_layer(top_layer)
	local layer = top_layer and hash("gui_top") or hash("gui")
	gui.set_layer(self.back, layer)
	gui.set_layer(self.panel, layer)
	gui.set_layer(self.outline, layer)
	gui.set_layer(self.icon, layer)
end


return M
