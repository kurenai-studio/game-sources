local decore = require("decore.decore")

local camera_command = require("system.camera.camera_command")
local camera_area_command = require("system.camera_area.camera_area_command")

---@class entity
---@field camera_area component.camera_area|nil

---@class entity.camera_area: entity
---@field camera_area component.camera_area
---@field transform component.transform

---Add this component to an entity to make the camera focus on its transform area (position + size).
---@class component.camera_area
---@field start_in_stack boolean|nil
decore.register_component("camera_area", {
	start_in_stack = false,
})

---@class system.camera_area: system
---@field entities entity.camera_area[]
---@field focus_entity entity|nil
---@field focus_stack entity[]
local M = {}


---@return system.camera_area
function M.create()
	local system = decore.system(M, "camera_area")
	system.filter = decore.ecs.requireAll("camera_area", "transform")
	system.focus_entity = nil
	system.focus_stack = {}
	camera_area_command.register(system)

	return system
end


function M:onAdd(entity)
	if entity.camera_area.start_in_stack then
		local is_instant = #self.focus_stack == 0
		self:_push_focus(entity, is_instant)
	end
end


---@param entity entity
---@param is_instant boolean?
function M:_push_focus(entity, is_instant)
	local stack = self.focus_stack
	local existing_index = nil

	for index = 1, #stack do
		if stack[index] == entity then
			existing_index = index
			break
		end
	end

	if existing_index and existing_index == #stack and self.focus_entity == entity then
		return
	end

	if existing_index then
		table.remove(stack, existing_index)
	end

	stack[#stack + 1] = entity
	self.focus_entity = entity

	camera_command.focus_entity(entity, is_instant and 0 or 0.3)
end


---@param entity entity
function M:_remove_from_stack(entity)
	local stack = self.focus_stack
	for index = #stack, 1, -1 do
		if stack[index] == entity then
			table.remove(stack, index)
			break
		end
	end
end


function M:_restore_top_or_follow()
	local stack = self.focus_stack
	local entity = stack[#stack]

	if entity then
		self.focus_entity = entity
		camera_command.focus_entity(entity)
	end
end


---@param entity entity
function M:_unfocus_entity(entity)
	if self.focus_entity == entity then
		self:_remove_from_stack(entity)
		self:_restore_top_or_follow()
	else
		self:_remove_from_stack(entity)
	end
end


---@param entity entity.camera_area
function M:onRemove(entity)
	if self.focus_entity == entity then
		self:_remove_from_stack(entity)
		self:_restore_top_or_follow()
	else
		self:_remove_from_stack(entity)
	end
end


return M
