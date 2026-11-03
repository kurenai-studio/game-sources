local decore = require("decore.decore")

local camera_command = require("system.camera.camera_command")
local transform_command = require("system.transform.transform_command")

local TEMP_VECTOR = vmath.vector3()

---@class entity
---@field camera component.camera|nil

---@class entity.camera: entity
---@field camera component.camera
---@field transform component.transform

---Add this component to camera entity, it will manage the camera visible size and position
---@class component.camera
---@field camera_url url
---@field follow_entity entity|nil
---@field position_x number|nil
---@field position_y number|nil
---@field size_x number|nil
---@field size_y number|nil
---@field offset_position_x number|nil
---@field offset_position_y number|nil
---@field offset_zoom number|nil
---@field zoom number|nil
---@field pivot_x number|nil @ 0=left, 0.5=center (default), 1=right. Where the camera attaches relative to window.
---@field pivot_y number|nil @ 0=bottom, 0.5=center (default), 1=top. Where the camera attaches relative to window.
decore.register_component("camera", {
	camera_url = "",
	offset_position_x = 0,
	offset_position_y = 0,
	offset_zoom = 0,
	pivot_x = 0.5,
	pivot_y = 0.5,
})

---@class system.camera.event
---@field entity entity.camera

---@class system.camera: system
---@field entities (entity.camera)[]
---@field camera entity.camera|nil @Current camera entity
---@field camera_borders vector4|nil @Borders of camera visible area vmath.vector4(left, right, top, bottom). Camera will not move outside of these borders
---@field visible_left number
---@field visible_right number
---@field visible_top number
---@field visible_bottom number
---@field shake_power number|nil
---@field shake_time number|nil
---@field shake_max_time number|nil
local M = {}

M.DEFAULT_SIZE = math.min(sys.get_config_int("display.width"), sys.get_config_int("display.height"))

---@return system.camera
function M.create()
	local self = decore.system(M, "camera", "camera")

	self.interval = 0.03
	self.camera = nil
	self.camera_borders = nil
	self.visible_left = 0
	self.visible_right = 0
	self.visible_top = 0
	self.visible_bottom = 0
	self.shake_power = 0
	self.shake_time = 0
	self.shake_max_time = 0
	camera_command.register(self)

	return self
end


function M:onAddToWorld()
	msg.post("@render:", "use_camera_projection")
end


function M:postWrap()
	self.world.event_bus:process("window_event", self.process_window_event, self)
	self.world.event_bus:process("transform_event", self.process_transform_event, self)
end


---@param window_event constant
function M:process_window_event(window_event)
	if not self.camera then
		return
	end

	if window_event == window.WINDOW_EVENT_RESIZED then
		self:update_camera_zoom(self.camera)
		self:update_camera_position(self.camera)
	end
end


---@param event system.transform.event
function M:process_transform_event(event)
	if not self.camera then
		return
	end

	local entity = event.entity
	if entity == self.camera then
		local animate_time = event.animate_time
		local easing = event.easing
		if event.is_size_changed or event.is_scale_changed then
			self:update_camera_zoom(self.camera, animate_time, easing)
		end
		if event.is_position_changed or event.is_size_changed or event.is_scale_changed then
			self:update_camera_position(self.camera, animate_time, easing)
			self:refresh_visible_borders()
		end
	end

	if self._focus_entity == entity then
		self:_apply_focus_entity_transform(entity)
	end
end


---@param entity entity.camera
function M:onAdd(entity)
	self.camera = entity
	self.is_camera_changed = true

	local camera_url = msg.url(entity.game_object.root)
	camera_url.fragment = hash("camera")
	entity.camera.camera_url = camera_url
	entity.camera.zoom = go.get(camera_url, "orthographic_zoom") --[[@as number]]
	self:refresh_visible_borders()
end


---@param entity entity.camera
function M:onRemove(entity)
	if self.camera == entity then
		self.camera = nil
		self.visible_left = 0
		self.visible_right = 0
		self.visible_top = 0
		self.visible_bottom = 0
	end
end


function M:update(dt)
	if self.is_camera_changed then
		self.world.event_bus:trigger("camera_event", self.camera)
		self.is_camera_changed = false
	end

	if self.shake_time > 0 then
		self.shake_max_time = math.max(self.shake_max_time, self.shake_time)

		self.shake_time = self.shake_time - dt
		if self.shake_time <= 0 then
			self.shake_max_time = 0
			self.shake_power = 0
			self:shake(0)
		else
			local power = self.shake_power * (self.shake_time / self.shake_max_time)
			self:shake(power)
		end
	end
end


---@param entity entity
---@param time number
function M:focus_entity(entity, time)
	self._focus_entity = entity

	if self._focus_entity then
		self:_apply_focus_entity_transform(entity, time)
	end
end


---Move camera to the entity position
---@param entity entity.camera
---@param animate_time number|nil
---@param easing integer|nil
function M:update_camera_position(entity, animate_time, easing)
	if self._focus_entity then
		TEMP_VECTOR.x = entity.transform.position_x
		TEMP_VECTOR.y = entity.transform.position_y
	else
		TEMP_VECTOR.x = entity.transform.position_x + entity.camera.offset_position_x
		TEMP_VECTOR.y = entity.transform.position_y + entity.camera.offset_position_y
	end
	TEMP_VECTOR.z = entity.transform.position_z

	-- Apply borders
	local borders = self.camera_borders
	if borders then
		local size_x = entity.transform.size_x / 2
		local size_y = entity.transform.size_y / 2
		if TEMP_VECTOR.x - size_x < borders.x then
			TEMP_VECTOR.x = borders.x + size_x
		end
		if TEMP_VECTOR.x + size_x > borders.y then
			TEMP_VECTOR.x = borders.y - size_x
		end
		if TEMP_VECTOR.y + size_y > borders.z then
			TEMP_VECTOR.y = borders.z - size_y
		end
		if TEMP_VECTOR.y - size_y < borders.w then
			TEMP_VECTOR.y = borders.w + size_y
		end
	end

	do -- Calculate camera offset
		local w, h = window.get_size()
		local pivot_x = entity.camera.pivot_x or 0.5
		local pivot_y = entity.camera.pivot_y or 0.5
		local zoom = entity.camera.zoom
		local camera_size_x = entity.transform.size_x * entity.transform.scale_x
		local camera_size_y = entity.transform.size_y * entity.transform.scale_y
		local view_w = camera_size_x * zoom
		local view_h = camera_size_y * zoom
		local offset_px = (0.5 - pivot_x) * (w - view_w)
		local offset_py = (0.5 - pivot_y) * (h - view_h)
		TEMP_VECTOR.x = TEMP_VECTOR.x + offset_px / zoom
		TEMP_VECTOR.y = TEMP_VECTOR.y + offset_py / zoom
	end

	if animate_time then
		local easing_value = easing or go.EASING_OUTSINE
		go.animate(entity.game_object.root, "position", go.PLAYBACK_ONCE_FORWARD, TEMP_VECTOR, easing_value, animate_time)
	else
		go.set_position(TEMP_VECTOR, entity.game_object.root)
	end
end


---Update camera zoom, so that camera fits the entity size
---@param entity entity.camera
---@param animate_time number|nil
---@param easing integer|nil
function M:update_camera_zoom(entity, animate_time, easing)
	local _, _, width, height = defos.get_view_size()
	local camera_size_x = entity.transform.size_x * entity.transform.scale_x
	local camera_size_y = entity.transform.size_y * entity.transform.scale_y
	local scale_x = width / camera_size_x
	local scale_y = height / camera_size_y
	local zoom = math.min(scale_x, scale_y)

	local device_pixel_ratio = self:get_device_pixel_ratio()
	entity.camera.zoom = (zoom + entity.camera.offset_zoom) / device_pixel_ratio

	if animate_time then
		local easing_value = easing or go.EASING_OUTSINE
		go.animate(entity.camera.camera_url, "orthographic_zoom", go.PLAYBACK_ONCE_FORWARD, entity.camera.zoom, easing_value, animate_time)
	else
		go.set(entity.camera.camera_url, "orthographic_zoom", entity.camera.zoom)
	end
end


function M:get_zoom()
	return self.camera.camera.zoom
end


function M:refresh_visible_borders()
	if not self.camera then
		return
	end

	local camera_root = self.camera.game_object.root
	assert(camera_root, "Camera root not found")

	local _, _, view_width, view_height = defos.get_view_size()
	local device_pixel_ratio = self:get_device_pixel_ratio()
	view_width = view_width / device_pixel_ratio
	view_height = view_height / device_pixel_ratio
	local zoom = go.get(self.camera.camera.camera_url, "orthographic_zoom")
	if zoom == 0 then
		return
	end

	local half_width = view_width * 0.5 / zoom
	local half_height = view_height * 0.5 / zoom
	local camera_position = go.get_position(camera_root)
	self.visible_left = camera_position.x - half_width
	self.visible_right = camera_position.x + half_width
	self.visible_top = camera_position.y + half_height
	self.visible_bottom = camera_position.y - half_height
end


---@param entity entity.camera
---@param position_x number
---@param position_y number
---@param time number
---@param easing integer|nil
function M:set_offset_position(entity, position_x, position_y, time, easing)
	entity.camera.offset_position_x = position_x
	entity.camera.offset_position_y = position_y
	if self._focus_entity then
		self:_apply_focus_entity_transform(self._focus_entity, time)
	end
	self:update_camera_position(entity, time, easing)
end


---@param entity entity.camera
---@param zoom number
---@param time number
---@param easing integer|nil
function M:set_offset_zoom(entity, zoom, time, easing)
	entity.camera.offset_zoom = zoom
	self:update_camera_zoom(entity, time, easing)
	self:update_camera_position(entity, time, easing)
end


---@param entity entity.camera
---@param pivot_x number 0=left, 0.5=center, 1=right
---@param pivot_y number 0=bottom, 0.5=center, 1=top
---@param time number|nil
---@param easing integer|nil
function M:set_pivot(entity, pivot_x, pivot_y, time, easing)
	entity.camera.pivot_x = pivot_x
	entity.camera.pivot_y = pivot_y
	self:update_camera_position(entity, time, easing)
end


function M:shake(power)
	if not self.camera then
		return
	end

	local obj_url = self.camera.game_object.root

	local power_sqr = power * power
	local dx = math.random(-power_sqr, power_sqr)
	local dy = math.random(-power_sqr, power_sqr)
	local x = self.camera.transform.position_x + dx
	local y = self.camera.transform.position_y + dy
	TEMP_VECTOR.x = x
	TEMP_VECTOR.y = y
	TEMP_VECTOR.z = self.camera.transform.position_z

	go.animate(obj_url, "position", go.PLAYBACK_ONCE_FORWARD, TEMP_VECTOR, go.EASING_OUTSINE, 0.06)
end


---@param entity entity
---@param time number?
function M:_apply_focus_entity_transform(entity, time)
	local transform = entity.transform
	assert(transform, "Entity does not have a transform component.")

	local position_x = transform.position_x + self.camera.camera.offset_position_x
	local position_y = transform.position_y + self.camera.camera.offset_position_y
	transform_command.set_position(self.camera, position_x, position_y)
	transform_command.set_size(self.camera, transform.size_x, transform.size_y)
	transform_command.set_animate_time(self.camera, time or 0.3, go.EASING_OUTSINE)
end


function M:get_device_pixel_ratio()
	if html5 then
		local high_dpi_koef = sys.get_config_boolean("display.high_dpi") and 1 or 2
		local device_pixel_ratio = tonumber(html5.run("window.devicePixelRatio || 1")) or 1
		return device_pixel_ratio / high_dpi_koef
	end

	return 1
end


return M
