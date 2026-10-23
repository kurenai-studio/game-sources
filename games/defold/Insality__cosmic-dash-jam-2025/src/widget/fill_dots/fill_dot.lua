local color = require("druid.color")
local promise = require("event.promise")
local panthera = require("panthera.panthera")

local animation = require("widget.fill_dots.fill_dot_panthera")

---@class widget.fill_dot: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.dot = self:get_node("dot")
	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	--panthera.set_time(self.animation, "locked", panthera.get_duration(self.animation, "locked"))

	self._level_state = nil
end


---@param color_id color
function M:set_color(color_id)
	color.set_color(self.dot, color_id)
end


---Set level state for the dot
---@param level_state string "completed", "current", or "locked"
---@param is_instant boolean?
function M:set_level_state(level_state, is_instant)
	if self._level_state == level_state then
		return promise.resolved()
	end

	self._level_state = level_state

	if is_instant then
		panthera.set_time(self.animation, level_state, panthera.get_duration(self.animation, level_state))
	else
		panthera.play(self.animation, level_state, panthera.OPTIONS_SKIP_INIT)
	end
end


return M
