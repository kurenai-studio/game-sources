---@class widget.button_icon: druid.widget
local M = {}

function M:init(callback)
	self.root = self:get_node("root")
	self.button = self.druid:new_button("button")
	self.icon = self:get_node("icon")
end


function M:set_icon(image_id)
	gui.play_flipbook(self.icon, image_id)
end


return M
