local M = {}


---@param transform system.transform
function M.register(transform)
	M.transform = transform
end


---@param entity entity
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M.set_position(entity, x, y, z)
	assert(entity.transform, "Entity does not have a transform component.")
	---@cast entity entity.transform
	M.transform:set_position(entity, x, y, z)
end


---@param entity entity
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M.add_position(entity, x, y, z)
	local t = entity.transform
	assert(t, "Entity does not have a transform component.")
	---@cast entity entity.transform

	x = x and t.position_x + x
	y = y and t.position_y + y
	z = z and t.position_z + z
	M.transform:set_position(entity, x, y, z)
end


---@param entity entity
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M.set_scale(entity, x, y, z)
	assert(entity.transform, "Entity does not have a transform component.")
	---@cast entity entity.transform
	M.transform:set_scale(entity, x, y, z)
end


---@param entity entity
---@param x number|nil
---@param y number|nil
---@param z number|nil
function M.set_size(entity, x, y, z)
	assert(entity.transform, "Entity does not have a transform component.")
	---@cast entity entity.transform
	M.transform:set_size(entity, x, y, z)
end


function M.set_rotation(entity, rotation)
	assert(entity.transform, "Entity does not have a transform component.")
	---@cast entity entity.transform
	M.transform:set_rotation(entity, rotation)
end


---@param entity entity
---@param animate_time number|nil
---@param easing integer|nil
---@param delay number|nil
---@param callback function|nil
function M.set_animate_time(entity, animate_time, easing, delay, callback)
	assert(entity.transform, "Entity does not have a transform component.")
	---@cast entity entity.transform
	M.transform:set_animate_time(entity, animate_time, easing, delay, callback)
end


---Return node borders relative to the current node parent
---@param entity entity
---@return number, number, number, number @left, top, right, bottom
function M.get_transform_borders(entity)
	local t = entity.transform --[[@as component.transform]]

	local left = t.position_x - t.size_x * 0.5
	local top = t.position_y + t.size_y * 0.5
	local right = t.position_x + t.size_x * 0.5
	local bottom = t.position_y - t.size_y * 0.5

	return left, top, right, bottom
end


---@param entity_from entity
---@param entity_to entity
---@return number angle Angle in degrees [0, 360]
function M.get_lookup_angle(entity_from, entity_to)
	local angle = math.atan2(entity_to.transform.position_y - entity_from.transform.position_y, entity_to.transform.position_x - entity_from.transform.position_x)
	angle = math.deg(angle)

	if angle < 0 then
		angle = angle + 360
	end

	return angle
end


---Check if two entities are overlapping
---@param entity1 entity
---@param entity2 entity
---@return boolean
function M.is_overlap(entity1, entity2)
	local left1, top1, right1, bottom1 = M.get_transform_borders(entity1)
	local left2, top2, right2, bottom2 = M.get_transform_borders(entity2)

	local is_overlap = left1 < right2 and right1 > left2 and top1 > bottom2 and bottom1 < top2
	return is_overlap
end


---@param entity entity
---@param x number
---@param y number
---@return boolean
function M.pick_entity(entity, x, y)
	local left, top, right, bottom = M.get_transform_borders(entity)
	return x > left and x < right and y > bottom and y < top
end


return M
