local helper = require("system.field.field.field_helper")

---@class system.field.entity_grid
---@field tile_size number
---@field grid entity.field[][][] @field[i][j] = entities
---@field entities table<entity.field, table> @entities[entity] = { i, j }
local M = {}


---@return system.field.entity_grid
function M.create(tile_size)
	local self = setmetatable({}, { __index = M })
	self.tile_size = tile_size

	-- Auto allocate grid
	self.grid = setmetatable({}, {
		__index = function(t, i)
			t[i] = setmetatable({}, {
				__index = function(tt, j)
					-- Initialize with an empty array instead of empty table
					tt[j] = setmetatable({}, { __index = table })
					return tt[j]
				end,
			})
			return t[i]
		end,
	})
	self.entities = {}

	return self
end


---@param entity entity.field
function M:add_entity(entity)
	local occupied = helper.get_occupied_ij(entity.transform, self.tile_size)
	for _, ij in ipairs(occupied) do
		local i, j = ij.i, ij.j
		table.insert(self.grid[i][j], entity)
	end
	self.entities[entity] = occupied
end


---@param entity entity.field
function M:remove_entity(entity)
	local occupied = self.entities[entity]
	for _, ij in ipairs(occupied) do
		local i, j = ij.i, ij.j
		helper.remove_value(self.grid[i][j], entity)
	end
	self.entities[entity] = nil
end


---@param entity entity.field
function M:update_entity(entity)
	-- Remove entity from old positions
	local old_occupied = self.entities[entity]
	if old_occupied then
		for _, ij in ipairs(old_occupied) do
			local i, j = ij.i, ij.j
			helper.remove_value(self.grid[i][j], entity)
		end
	end

	-- Add entity to new positions
	local new_occupied = helper.get_occupied_ij(entity.transform, self.tile_size)
	for _, ij in ipairs(new_occupied) do
		local i, j = ij.i, ij.j
		table.insert(self.grid[i][j], entity)
	end
	self.entities[entity] = new_occupied
end


---@param x number
---@param y number
---@return number, number
function M:get_ij(x, y)
	return helper.get_ij(x, y, self.tile_size)
end


---@param i number
---@param j number
---@return number, number
function M:get_xy(i, j)
	return helper.get_xy(i, j, self.tile_size)
end


-- Get next entity in direction from i, j
---@param i number
---@param j number
---@param dir_x number -1, 0, 1
---@param dir_y number -1, 0, 1
---@param max_depth number|nil Default is 40
---@return entity.field|nil, number, number
function M:get_in_direction(i, j, dir_x, dir_y, max_depth)
	max_depth = max_depth or 40
	if max_depth <= 0 then
		return nil, i, j
	end

	local current_entity = self.grid[i][j][1]
	local next_i = i + dir_x
	local next_j = j + dir_y

	local entities = self.grid[next_i][next_j]

	local next_entity = nil
	for _, entity in ipairs(entities) do
		if not entity.field.floor then
			next_entity = entity
			break
		end
	end

	-- If the same entity, continue to the next cell
	if next_entity == current_entity then
		return self:get_in_direction(next_i, next_j, dir_x, dir_y, max_depth - 1)
	end

	-- If next entity is nil, continue to the next cell
	if not next_entity then
		return self:get_in_direction(next_i, next_j, dir_x, dir_y, max_depth - 1)
	end

	return next_entity, next_i, next_j
end


---@param i number
---@param j number
---@return boolean
function M:is_floor_exists(i, j)
	return self.grid[i][j][1] ~= nil
end


return M
