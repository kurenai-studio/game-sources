local single_star = require("widget.star_counter.single_star")

---@class widget.star_counter: druid.widget
local M = {}


function M:init()
	self.stars = {
		self.druid:new_widget(single_star, "single_star_1"),
		self.druid:new_widget(single_star, "single_star_2"),
		self.druid:new_widget(single_star, "single_star_3"),
	}
end


---@param amount number
function M:set_stars(amount)
	for index = 1, #self.stars do
		self.stars[index]:set_collected(index <= amount, true)
	end
end


---@param color color
function M:set_color(color)
	for index = 1, #self.stars do
		self.stars[index]:set_color(color)
	end
end


return M
