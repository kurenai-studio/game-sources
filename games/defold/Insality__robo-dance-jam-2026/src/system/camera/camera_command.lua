---@class system.camera.command
---@field camera system.camera
local M = {}

local TEMP_VECTOR3 = vmath.vector3(0)

---@param camera_system system.camera
function M.register(camera_system)
	M.camera = camera_system
end


---@param entity entity
---@param time number?
function M.focus_entity(entity, time)
	time = time or 0.3
	M.camera:focus_entity(entity, time)
end


function M.get_zoom()
	return M.camera:get_zoom()
end


---@param position_x number
---@param position_y number
---@param time number
---@param easing number|nil
function M.set_offset_position(position_x, position_y, time, easing)
	easing = easing or go.EASING_OUTSINE
	M.camera:set_offset_position(M.camera.camera, position_x, position_y, time, easing)
end


---@param zoom number
---@param time number
---@param easing number|nil
function M.set_offset_zoom(zoom, time, easing)
	easing = easing or go.EASING_OUTSINE
	M.camera:set_offset_zoom(M.camera.camera, zoom, time, easing)
end


---@param pivot_x number 0=left, 0.5=center, 1=right
---@param pivot_y number 0=bottom, 0.5=center, 1=top
---@param time number|nil
---@param easing number|nil
function M.set_pivot(pivot_x, pivot_y, time, easing)
	easing = easing or go.EASING_OUTSINE
	M.camera:set_pivot(M.camera.camera, pivot_x, pivot_y, time, easing)
end


---@param power number
---@param time number
function M.shake(power, time)
	M.camera.shake_power = power or 8
	M.camera.shake_time = time or 0.4
end


---@param x number
---@param y number
---@return number, number
function M.world_to_screen(x, y)
	TEMP_VECTOR3.x = x
	TEMP_VECTOR3.y = y
	TEMP_VECTOR3.z = 0
	local pos = camera.world_to_screen(TEMP_VECTOR3)
	return pos.x, pos.y
end


---@param x number
---@param y number
---@return number, number
function M.screen_to_world(x, y)
	local pos = camera.screen_xy_to_world(x, y)
	return pos.x, pos.y
end


---@return number, number, number, number
function M.get_visible_borders()
	return M.camera.visible_left, M.camera.visible_right, M.camera.visible_top, M.camera.visible_bottom
end


---@return entity.camera
function M.get_current_camera()
	return M.camera.camera
end


---@private
---@param entity entity
function M.get_camera_scale_to_fit_entity(entity)
	local camera = M.get_current_camera()
	local area_w = entity.transform.size_x * entity.transform.scale_x
	local area_h = entity.transform.size_y * entity.transform.scale_y
	local scale_x = area_w / camera.transform.size_x
	local scale_y = area_h / camera.transform.size_y

	return scale_x, scale_y
end


return M
