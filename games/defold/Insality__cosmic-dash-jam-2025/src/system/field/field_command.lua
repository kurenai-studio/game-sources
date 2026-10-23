---@class world
---@field field system.field.command

---@class system.field.command
---@field field system.field
---@field world world
local M = {}

---@param field system.field
---@return system.field.command
function M.create(field)
	return setmetatable({ field = field, world = field.world }, { __index = M })
end


---@param entity entity
---@return number, number
function M:get_entity_ij(entity)
	return self.field.field:get_ij(entity.transform.position_x, entity.transform.position_y)
end


---@param i number
---@param j number
---@return number, number
function M:get_xy(i, j)
	return self.field.field:get_xy(i, j)
end


---@param x number
---@param y number
---@return number, number
function M:get_ij(x, y)
	return self.field.field:get_ij(x, y)
end


---@param entity entity
---@param direction string|table "up", "down", "left", "right", {i = number, j = number}
---@param max_length number|nil Default is 40
---@return entity.field|nil, number, number
function M:get_collide_entity_in_direction(entity, direction, max_length)
	local i, j = self:get_entity_ij(entity)

	local dir_x = direction and direction.i or 0
	local dir_y = direction and direction.j or 0

	if direction == "up" then
		dir_x, dir_y = 0, 1
	elseif direction == "down" then
		dir_x, dir_y = 0, -1
	elseif direction == "left" then
		dir_x, dir_y = -1, 0
	elseif direction == "right" then
		dir_x, dir_y = 1, 0
	end

	return self.field.field:get_in_direction(i, j, dir_x, dir_y, max_length)
end


---@param i number
---@param j number
---@return boolean
function M:is_floor_exists(i, j)
	return self.field.field:is_floor_exists(i, j)
end


return M
