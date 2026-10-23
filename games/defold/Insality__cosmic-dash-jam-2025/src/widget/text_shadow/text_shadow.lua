---@class widget.text_shadow: druid.widget
local M = {}


function M:init()
	self.text = self.druid:new_rich_text("text")
	self.text_reflection = self.druid:new_rich_text("text_reflection")
end


function M:set_text(text)
	self.text:set_text(text)
	self.text_reflection:set_text(text)
end


return M
