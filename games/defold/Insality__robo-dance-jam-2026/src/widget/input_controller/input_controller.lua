local event = require("event.event")

---@class widget.input_controller: druid.widget
local M = {}

local INPUTS = {
	[hash("key_space")] = "action",
	[hash("key_enter")] = "action",
	[hash("key_x")] = "action",
	[hash("gamepad_rpad_down")] = "action",

	[hash("key_left")] = "left",
	[hash("key_a")] = "left",
	[hash("gamepad_lpad_left")] = "left",
	[hash("gamepad_lstick_left")] = "left",

	[hash("key_right")] = "right",
	[hash("key_d")] = "right",
	[hash("gamepad_lpad_right")] = "right",
	[hash("gamepad_lstick_right")] = "right",

	[hash("key_up")] = "up",
	[hash("key_w")] = "up",
	[hash("gamepad_lpad_up")] = "up",
	[hash("gamepad_lstick_up")] = "up",

	[hash("key_down")] = "down",
	[hash("key_s")] = "down",
	[hash("gamepad_lpad_down")] = "down",
	[hash("gamepad_lstick_down")] = "down",

	[hash("key_backspace")] = "back",
	[hash("key_back")] = "back",
	[hash("key_z")] = "back",
	[hash("gamepad_rpad_right")] = "back",

	[hash("key_tab")] = "menu",
	[hash("key_esc")] = "menu",
	[hash("gamepad_start")] = "menu",
}

function M:init()
	self.enabled = true

	self.on_direction = event.create()
	self.on_action = event.create()
	self.on_back = event.create()
	self.on_menu = event.create()

	self.events = {
		["action"] = self.on_action,
		["back"] = self.on_back,
		["menu"] = self.on_menu,
	}

	self.direction_events = {
		["left"] = self.on_direction,
		["right"] = self.on_direction,
		["up"] = self.on_direction,
		["down"] = self.on_direction,
	}
end


---@param action_id hash
---@param action action
function M:on_input(action_id, action)
	if not self.enabled then
		return false
	end

	local event_id = INPUTS[action_id]
	local is_pressed = action.pressed or action.repeated
	local is_value_ok = true
	if action.value then
		is_value_ok = action.value > 0.8
	end
	if not event_id or not is_pressed or not is_value_ok then
		return false
	end

	-- Special direction handling
	local direction_event = self.direction_events[event_id]
	if direction_event then
		self:trigger_direction(event_id)
		return true
	end

	self.events[event_id]:trigger()

	return true
end


---@param enabled boolean
---@return widget.input_controller
function M:set_enabled(enabled)
	self.enabled = enabled

	return self
end


function M:trigger_direction(side)
	local direction_event = self.direction_events[side]
	if not direction_event then
		return
	end

	local direction_x = 0
	local direction_y = 0

	if side == "left" then
		direction_x = -1
	elseif side == "right" then
		direction_x = 1
	elseif side == "up" then
		direction_y = 1
	elseif side == "down" then
		direction_y = -1
	end

	direction_event:trigger(direction_x, direction_y, side)
end


return M
