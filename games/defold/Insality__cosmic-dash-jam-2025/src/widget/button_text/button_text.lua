---@class widget.button_text: druid.widget
local M = {}


function M:init(callback)
	self.root = self:get_node("root")
	self.button = self.druid:new_button("button", callback)
	self.text = self.druid:new_text("text")
end


return M
