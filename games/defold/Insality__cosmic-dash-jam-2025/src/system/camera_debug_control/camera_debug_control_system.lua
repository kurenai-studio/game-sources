local decore = require("decore.decore")

---@class system.camera_debug_control: system
---@field is_ctrl boolean
local M = {}

local HASH_CMD = hash("key_lsuper")
local HASH_CTRL = hash("key_lctrl")


---@return system.camera_debug_control
function M.create_system()
	local self = decore.system(M, "camera_debug_control")
	self.is_ctrl = false
	self.is_hold = false

	return self
end


function M:postWrap()
	self.world.event_bus:process("input_event", self.process_input_event, self)
end


---@param input_event system.input.event
function M:process_input_event(input_event)
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


---@param entity entity.camera
---@param zoom_factor number
---@param action system.input.event
function M:zoom_at_position(entity, zoom_factor, action)
	-- Get mouse position in world space
	local mouse_world_x, mouse_world_y = self.world.camera:screen_to_world(action.x, action.y)

	-- Calculate vector from camera to mouse position
	local camera_to_mouse_x = mouse_world_x - entity.transform.position_x
	local camera_to_mouse_y = mouse_world_y - entity.transform.position_y

	-- Apply zoom
	local new_scale_x = entity.transform.scale_x * zoom_factor
	local new_scale_y = entity.transform.scale_y * zoom_factor
	self.world.transform:set_scale(entity, new_scale_x, new_scale_y)
	self.world.transform:set_animate_time(entity, 0.16, go.EASING_LINEAR)

	-- Calculate position adjustment
	local adjustment_factor = 1 - (1 / zoom_factor)
	local dx = camera_to_mouse_x * adjustment_factor * 0.9
	local dy = camera_to_mouse_y * adjustment_factor * 0.9

	-- Move camera to keep mouse point fixed
	self.world.transform:add_position(entity, -dx, -dy)
end


---@param action system.input.event
function M:process_drag_camera(action)
	local action_id = action.action_id
	if action_id == hash("touch") then
		if action.pressed then
			self.is_hold = true
			self.start_x = action.x
			self.start_y = action.y
		elseif action.released then
			self.is_hold = false
		end
	end

	if self.is_hold and action.dx then
		local entity = self.world.camera:get_current_camera()
		local zoom = entity.camera.zoom
		local koef = (1 / zoom) / 6 -- 6 is magic thing...
		self.world.transform:add_position(entity, -action.dx * koef, -action.dy * koef)
	end

	if self.is_ctrl then
		-- check wheel
		if action.action_id == hash("mouse_wheel_down") then
			local entity = self.world.camera:get_current_camera()
			self:zoom_at_position(entity, 1.1, action)
		end
		if action.action_id == hash("mouse_wheel_up") then
			local entity = self.world.camera:get_current_camera()
			self:zoom_at_position(entity, 0.9, action)
		end
	end
end


return M
