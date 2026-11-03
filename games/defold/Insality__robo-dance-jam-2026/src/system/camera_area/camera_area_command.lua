local M = {}


---@param camera_area system.camera_area
function M.register(camera_area)
	M.camera_area = camera_area
end


---@param entity entity
---@param is_instant boolean?
function M.focus_entity(entity, is_instant)
	M.camera_area:_push_focus(entity, is_instant)
end


---@param entity entity
function M.unfocus_entity(entity)
	M.camera_area:_unfocus_entity(entity)
end


return M
