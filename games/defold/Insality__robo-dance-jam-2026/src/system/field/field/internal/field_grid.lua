local helper = require("system.field.field.internal.field_helper")

---@class field.grid
---@field grid field.entity[][][] field[i][j] = entities
---@field entities table<field.entity, table> entities[entity] = { i, j }
---@field entities_by_id table<string, field.entity> entities_by_id[entity_id] = entity
local M = {}


---@return field.grid
function M.create()
	local self = setmetatable({}, { __index = M })

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
	self.entities_by_id = {}

	return self
end


---@param entity field.entity
---@return field.entity
function M:add_entity(entity)
	if self.entities[entity] then
		return entity
	end

	local i = entity.i
	local j = entity.j

	table.insert(self.grid[i][j], entity)
	self.entities[entity] = { i, j }
	self.entities_by_id[entity.entity_id] = entity

	return entity
end


---@param entity field.entity
---@return field.entity
function M:remove_entity(entity)
	local i = entity.i
	local j = entity.j

	helper.remove_value(self.grid[i][j], entity)
	self.entities[entity] = nil
	self.entities_by_id[entity.entity_id] = nil

	return entity
end


---@param entity field.entity
---@param target_i integer
---@param target_j integer
---@return field.entity
function M:move_entity(entity, target_i, target_j)
	self:remove_entity(entity)
	entity.i = target_i
	entity.j = target_j
	return self:add_entity(entity)
end


---@param x number
---@param y number
---@return number, number @i, j
function M.get_ij(x, y)
	return helper.get_ij(x, y)
end


---@param i number
---@param j number
---@return number, number @x, y
function M.get_xy(i, j)
	return helper.get_xy(i, j)
end


---@param i number
---@param j number
---@return number
function M:ij_to_key(i, j)
	return i * 1000 + j
end


---@param id string|number
---@return field.entity|nil
function M:get_entity(id)
	return self.entities_by_id[id] or self.entities_by_id[tostring(id)]
end


---@param i number
---@param j number
---@return field.entity[]
function M:get_entities_at(i, j)
	return self.grid[i][j]
end


-- Get next entity in direction from i, j
---@param i number
---@param j number
---@param dir_x number -1, 0, 1
---@param dir_y number -1, 0, 1
---@param max_distance number? nil for infinite
---@return field.entity|nil
function M:get_in_direction(i, j, dir_x, dir_y, max_distance)
	dir_x = dir_x or 0
	dir_y = dir_y or 0

	if max_distance ~= nil and max_distance <= 0 then
		return nil
	end

	local next_i = i + dir_x
	local next_j = j + dir_y

	local current_entity = self.grid[i][j][1]
	if not current_entity then
		return nil
	end
	if not self.grid[next_i] then
		return nil
	end

	local next_entity = self.grid[next_i][next_j][1]

	-- If the same entity, continue to the next cell
	if next_entity == current_entity then
		return self:get_in_direction(next_i, next_j, dir_x, dir_y, max_distance and (max_distance - 1) or nil)
	end

	return next_entity
end


function M:print_debug_grid()
	local min_i = math.huge
	local max_i = -math.huge
	local min_j = math.huge
	local max_j = -math.huge

	for entity in pairs(self.entities) do
		if entity.i < min_i then
			min_i = entity.i
		end
		if entity.i > max_i then
			max_i = entity.i
		end
		if entity.j < min_j then
			min_j = entity.j
		end
		if entity.j > max_j then
			max_j = entity.j
		end
	end

	if min_i == math.huge then
		print("[field_grid] <empty>")
		return
	end

	for j = min_j, max_j do
		local row = {}
		for i = min_i, max_i do
			local entities = self.grid[i][j]
			local is_walkable = false
			local has_movable = false
			local has_non_movable = false

			for index = 1, #entities do
				local entity = entities[index]
				if entity.solid and (entity.z + entity.height) == 1 then
					is_walkable = true
				end
				if entity.z == 1 and entity.solid then
					if entity.movable then
						has_movable = true
					else
						has_non_movable = true
					end
				end
			end

			local symbol = " "
			if is_walkable then
				symbol = "X"
			end
			if has_non_movable then
				symbol = "W"
			end
			if has_movable then
				symbol = "M"
			end

			table.insert(row, symbol)
		end
		print(table.concat(row, " "))
	end
end


return M
