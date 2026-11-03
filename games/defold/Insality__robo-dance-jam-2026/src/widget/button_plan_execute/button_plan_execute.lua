local event = require("event.event")
local panthera = require("panthera.panthera")

local button_input_hint = require("widget.button_input_hint.button_input_hint")
local text_animated = require("widget.text_animated.text_animated")
local animation = require("widget.button_plan_execute.button_plan_execute_panthera")

---@class widget.button_plan_execute: druid.widget
local M = {}


function M:init()
	self.on_click = event.create()
	self.on_ready = event.create()

	self.animation = panthera.create_gui(animation, self:get_template(), self:get_nodes())
	self.fx_animation = panthera.clone_state(self.animation)

	self.root = self:get_node("root")
	self.text_animated = self.druid:new_widget(text_animated, "text_animated")
	self.button_input_hint = self.druid:new_widget(button_input_hint, "button_input_hint")
	self.button = self.druid:new_button("root", self._on_click)
	self._is_executing = false
	self._is_enabled = true
	self._can_unpause = false
	self._text_key = "ui_execute"
	self._is_ready_to_execute = false

	self.text_animated:set_text(self._text_key)

	self:set_enabled(true)
end


function M:_on_click()
	self.on_click:trigger()
end


function M:onRemove()
	panthera.stop(self.animation)
	panthera.stop(self.fx_animation)
end


---@param is_executing boolean
function M:set_executing(is_executing)
	self._is_executing = is_executing

	self:_refresh_text()
	self:_refresh_ready_state()

	if is_executing then
		panthera.play(self.animation, "start_executing")
	else
		panthera.play(self.animation, "completed")
	end
end


---@param progress number
function M:set_running_time_progress(progress)
	if self._is_executing and not panthera.is_playing(self.animation) then
		panthera.set_time(self.animation, "progress", progress)
	end
end


---@param is_enabled boolean
function M:set_enabled(is_enabled)
	self._is_enabled = is_enabled

	local is_alpha = not self._is_executing and not is_enabled
	gui.set_alpha(self.root, is_alpha and 0.5 or 1)
	self:_refresh_text()
	self:_refresh_ready_state()

	--self.button:set_input_enabled(is_enabled)
end


---@param can_unpause boolean
function M:set_can_unpause(can_unpause)
	self._can_unpause = can_unpause
	self:_refresh_text()
	self:_refresh_ready_state()
end


function M:_refresh_ready_state()
	local is_ready_to_execute = self._is_enabled and not self._is_executing and not self._can_unpause

	if self._is_ready_to_execute == is_ready_to_execute then
		return
	end

	self._is_ready_to_execute = is_ready_to_execute

	if is_ready_to_execute then
		self.on_ready:trigger()
		panthera.play(self.fx_animation, "ready", panthera.OPTIONS_SKIP_INIT_LOOP)
	else
		panthera.stop(self.fx_animation)
	end
end


function M:_refresh_text()
	local text_key = "ui_executing"

	if not self._is_executing then
		text_key = self._can_unpause and "ui_unpause" or "ui_execute"
	elseif self._is_enabled then
		text_key = "ui_pause"
	end

	if self._text_key == text_key then
		return
	end

	self._text_key = text_key
	self.text_animated:animate_text(text_key)

	gui.set_enabled(self:get_node("button_green_mask"), self._text_key ~= "ui_pause")
end


function M:on_language_change()
	local key = self._text_key
	self._text_key = nil
	self:_refresh_text()
end


return M
