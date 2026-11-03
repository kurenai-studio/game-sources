local decore = require("decore.decore")

local camera_command = require("system.camera.camera_command")
local transform_command = require("system.transform.transform_command")

---@class system.camera_debug_control: system
---@field is_ctrl boolean
local M = {}

local HASH_CMD = hash("key_lsuper")
local HASH_CTRL = hash("key_lctrl")
local WHEEL_STEP = 0.08
local WHEEL_TIME = 0.15

---@return system.camera_debug_control
function M.create()
	local system = decore.system(M, "camera_debug_control")
	system.is_ctrl = false
	system.is_hold = false

	return system
end


function M:postWrap()
	self.world.event_bus:process_all("input_event", self.process_input_event, self)
end


---@param input_events system.input.event[]
function M:process_input_event(input_events)
	for i = 1, #input_events do
		local input_event = input_events[i]
		-- Process mod key
		local action_id = input_event.action_id
		local is_ctrl = (action_id == HASH_CTRL or action_id == HASH_CMD)
		if is_ctrl and input_event.pressed then
			self.is_ctrl = true
		elseif is_ctrl and input_event.released then
			self.is_ctrl = false
		end

		-- process drag camera
		if self.is_ctrl then
			self:process_drag_camera(input_event)
		end
	end
end


---@param input_event system.input.event
function M:process_drag_camera(input_event)
	local action_id = input_event.action_id
	if action_id == hash("touch") then
		if input_event.pressed then
			self.is_hold = true
		elseif input_event.released then
			self.is_hold = false
		end
	end

	if self.is_hold and not action_id then
		local entity = camera_command.get_current_camera()
		local zoom = entity.camera.zoom
		local scale_x = zoom--entity.transform.scale_x
		local scale_y = zoom--entity.transform.scale_y
		transform_command.add_position(entity, -input_event.dx / scale_x, -input_event.dy / scale_y)
	end

	if self.is_ctrl then
		if input_event.action_id == hash("mouse_wheel_down") then
			local entity = camera_command.get_current_camera()
			local new_scale_x = entity.transform.scale_x * (1 + WHEEL_STEP)
			local new_scale_y = entity.transform.scale_y * (1 + WHEEL_STEP)
			transform_command.set_scale(entity, new_scale_x, new_scale_y)
			transform_command.set_animate_time(entity, WHEEL_TIME, go.EASING_OUTSINE)
		end
		if input_event.action_id == hash("mouse_wheel_up") then
			local entity = camera_command.get_current_camera()
			local new_scale_x = entity.transform.scale_x * (1 - WHEEL_STEP)
			local new_scale_y = entity.transform.scale_y * (1 - WHEEL_STEP)
			transform_command.set_scale(entity, new_scale_x, new_scale_y)
			transform_command.set_animate_time(entity, WHEEL_TIME, go.EASING_OUTSINE)
		end
	end
end


return M
