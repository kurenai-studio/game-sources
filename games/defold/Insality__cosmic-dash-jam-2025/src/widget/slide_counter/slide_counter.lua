local panthera = require("panthera.panthera")
local animation = require("widget.slide_counter.slide_counter_panthera")


---@class widget.slide_counter: druid.widget
local M = {}


function M:init()
	self.text = self.druid:new_text("text")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
end


---@param amount number
function M:set(amount)
	self._amount = amount
	self.text:set_text(tostring(amount))
end


function M:add()
	self._amount = self._amount + 1
	self.text:set_text(tostring(self._amount))
	panthera.play(self.animation, "change", panthera.OPTIONS_SKIP_INIT)
end


return M
