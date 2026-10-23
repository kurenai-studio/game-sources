---Widget to display level status as fill dots
local fill_dot = require("widget.fill_dots.fill_dot")

---@class widget.fill_dots: druid.widget
---@field dots widget.fill_dot[]
local M = {}


function M:init()
	self.root = self:get_node("root")
	self.layout = self.druid:new_layout(self.root, "horizontal")
	self.dots = {}
	self._level_count = 0
	self._current_level = 0
	self._main_color = nil

	gui.set_enabled(self:get_node("fill_dot/root"), false)
end


function M:set_dots(dots_count)
	for index = 1, #self.dots do
		gui.delete_node(self.dots[index].root)
		self.druid:remove(self.dots[index])
	end
	self.layout:clear_layout()
	self.dots = {}

	for index = 1, dots_count do
		local dot = self.druid:new_widget(fill_dot, "fill_dot", "root")
		gui.set_enabled(dot.root, true)

		table.insert(self.dots, dot)
		self.layout:add(dot.root)
	end
end


---Set level status with total level count and current level
---@param current_level number Current level (1-based)
---@param level_count number Total number of levels
function M:set_level_status(current_level, level_count)
	self._level_count = level_count
	self._current_level = current_level
	self:_refresh_levels()
end


---Update current level
---@param current_level number Current level (1-based)
function M:set_current_level(current_level)
	self._current_level = current_level
	self:_refresh_levels()
end


function M:_refresh_levels()
	for index = 1, #self.dots do
		local dot = self.dots[index]

		-- Set color for all dots
		if self._main_color then
			dot:set_color(self._main_color)
		end

		-- Set level state
		local level_state
		if index < self._current_level then
			level_state = "completed"
		elseif index == self._current_level then
			level_state = "current"
		else
			level_state = "locked"
		end

		dot:set_level_state(level_state)
	end
end


---Set color for all dots
---@param color color
function M:set_color(color)
	self._main_color = color
	self:_refresh_levels()
end


return M
