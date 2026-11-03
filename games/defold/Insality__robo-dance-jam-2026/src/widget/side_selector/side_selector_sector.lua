local color = require("druid.color")
local panthera = require("panthera.panthera")
local animation = require("widget.side_selector.side_selector_sector_panthera")

---@class widget.side_selector_sector: druid.widget
local M = {}


function M:init()
	self.root = self:get_node("root")

	self.inner = self:get_node("inner")
	self.outer = self:get_node("outer")
	self.icon_arrow = self:get_node("icon_arrow")

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self._tween_id = nil
	self._progress = 0
	self._target_progress = 0
	panthera.set_time(self.animation, "state", 0)
end


function M:set_selected_progress(progress)
	self._target_progress = vmath.clamp(progress, 0, 1)
	--panthera.set_time(self.animation, "state", progress)
end


function M:reset_progress()
	self._progress = 0
	self._target_progress = 0
	panthera.set_time(self.animation, "state", 0)
end

function M:update(dt)
	-- lerp to target progress, inline, not vmath
	local delta = self._target_progress - self._progress
	if math.abs(delta) < 0.001 then
		return
	end

	self._progress = self._progress + (self._target_progress - self._progress) * dt * 15
	panthera.set_time(self.animation, "state", self._progress)
end


---@param color_id string|vector4
---@param color_back_id string|vector4
function M:set_color(color_id, color_back_id)
	color.set_color(self:get_node("outer"), color_back_id)
	color.set_color(self:get_node("inner"), color_id)
end


---@param top_layer boolean
function M:set_top_layer(top_layer)
	local layer = top_layer and hash("gui_top") or hash("gui")
	gui.set_layer(self.inner, layer)
	gui.set_layer(self.outer, layer)
	gui.set_layer(self.icon_arrow, layer)
end


return M
