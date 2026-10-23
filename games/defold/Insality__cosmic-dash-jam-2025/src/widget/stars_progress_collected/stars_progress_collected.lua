local levels = require("game.levels")

---@class widget.stars_progress_collected: druid.widget
local M = {}


function M:init()
	self.mask = self:get_node("mask")
	self.text_counter = self.druid:new_text("text_counter")

	local collected_stars, total_stars = levels.get_total_stars_count()
	self:set_stars_collected(collected_stars, total_stars)
end


function M:set_stars_collected(amount, from)
	local progress = amount / from
	progress = math.min(math.max(progress, 0), 1)

	self._progress = progress

	local text_progress = string.format("%s / %s", amount, from)
	self.text_counter:set_text(text_progress)

	gui.set_fill_angle(self.mask, -360 * progress)

	gui.set_enabled(self.text_counter.node, self._progress < 1)
end


function M:is_completed()
	return self._progress == 1
end


return M
