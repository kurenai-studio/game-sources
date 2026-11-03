local panthera = require("panthera.panthera")
local animation = require("widget.side_selector.side_selector_panthera")
local side_selector_sector = require("widget.side_selector.side_selector_sector")

---@class widget.side_selector: druid.widget
local M = {}

local HALF_SECTOR_ANGLE = 90

local SIDE_ANGLE = {
	right = 0,
	up = 90,
	left = 180,
	down = -90,
}


local function get_angle_delta(angle_a, angle_b)
	local delta = (angle_a - angle_b + 180) % 360 - 180
	return math.abs(delta)
end


local function get_side_progress(angle, side)
	local delta = get_angle_delta(angle, SIDE_ANGLE[side])
	return vmath.clamp(1 - delta / HALF_SECTOR_ANGLE, 0, 1)
end


function M:init()
	self.root = self:get_node("root")
	self.sectors = {
		self.druid:new_widget(side_selector_sector, "sector_up"),
		self.druid:new_widget(side_selector_sector, "sector_left"),
		self.druid:new_widget(side_selector_sector, "sector_down"),
		self.druid:new_widget(side_selector_sector, "sector_right"),
	}
	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
end



---@param color_id string|vector4
---@param color_back_id string|vector4
function M:set_color(color_id, color_back_id)
	for _, sector in ipairs(self.sectors) do
		sector:set_color(color_id, color_back_id)
	end
end


---@param top_layer boolean
function M:set_top_layer(top_layer)
	for _, sector in ipairs(self.sectors) do
		sector:set_top_layer(top_layer)
	end
end


function M:reset_angle()
	for _, sector in ipairs(self.sectors) do
		sector:reset_progress()
	end
end


---@param angle number
function M:set_angle(angle)
	local progress_right = get_side_progress(angle, "right")
	local progress_up = get_side_progress(angle, "up")
	local progress_left = get_side_progress(angle, "left")
	local progress_down = get_side_progress(angle, "down")

	self.sectors[1]:set_selected_progress(progress_up)
	self.sectors[2]:set_selected_progress(progress_left)
	self.sectors[3]:set_selected_progress(progress_down)
	self.sectors[4]:set_selected_progress(progress_right)

	self.current_side = "up"
	local max_progress = progress_up
	if progress_left > max_progress then
		self.current_side = "left"
		max_progress = progress_left
	end
	if progress_down > max_progress then
		self.current_side = "down"
		max_progress = progress_down
	end
	if progress_right > max_progress then
		self.current_side = "right"
	end

	return self.current_side
end


---@return "up" | "down" | "left" | "right"
function M:get_current_side()
	return self.current_side
end


---@param enabled boolean
---@param callback fun()?
function M:set_enabled(enabled, callback)
	if enabled then
		gui.set_enabled(self.root, true)
		self:reset_angle()
		self:set_top_layer(true)
		if callback then
			callback()
		end
		panthera.play(self.animation, "appear")
	else
		panthera.play(self.animation, "disappear", {
			callback = function()
				self:set_top_layer(false)
				gui.set_enabled(self.root, false)
				if callback then
					callback()
				end
			end,
		})
	end
end


return M
