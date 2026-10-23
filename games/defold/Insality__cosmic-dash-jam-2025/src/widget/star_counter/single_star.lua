local color = require("druid.color")
local panthera = require("panthera.panthera")
local animation = require("widget.star_counter.single_star_panthera")

---@class widget.single_star: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.icon = self:get_node("icon")
	self:set_collected(false)

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
end


function M:set_collected(is_collected, is_animate)
	if self._is_collected == is_collected then
		return
	end

	self._is_collected = is_collected

	if is_animate then
		local animation_id = is_collected and "collected" or "empty"
		panthera.play(self.animation, animation_id, panthera.OPTIONS_SKIP_INIT)
	else
		gui.set_alpha(self.icon, is_collected and 1 or 0.3)
	end
end


---@param color_id color
function M:set_color(color_id)
	color.set_color(self:get_node("icon"), color_id)
end


return M
