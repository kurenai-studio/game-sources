local M = {}

function M.round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end


---@param x number
---@param y number
---@return number, number
function M.get_ij(x, y, tile_size)
	local i = M.round((x + tile_size / 2) / tile_size) + 1
	local j = M.round((y + tile_size / 2) / tile_size) + 1

	return i, j
end


---@param i number
---@param j number
---@return number, number
function M.get_xy(i, j, tile_size)
	local x = (i - 1) * tile_size - (tile_size)
	local y = (j - 1) * tile_size - (tile_size)

	return x, y
end


---Get list of {i, j} occupied by the entity, based on its transform (position and size)
---@param transform component.transform
function M.get_occupied_ij(transform, tile_size)
	local result = {}
	local x, y = transform.position_x, transform.position_y
	local size_x, size_y = transform.size_x, transform.size_y
	local half_tile_size = tile_size / 2
	local min_i, min_j = M.get_ij(x - size_x / 2 + half_tile_size, y - size_y / 2 + half_tile_size, tile_size)
	local max_i, max_j = M.get_ij(x + size_x / 2 - half_tile_size, y + size_y / 2 - half_tile_size, tile_size)

	for i = min_i, max_i do
		for j = min_j, max_j do
			table.insert(result, { i = i, j = j })
		end
	end

	return result
end


---@param t table
---@param v any
---@return boolean
function M.remove_value(t, v)
	for index = 1, #t do
		if t[index] == v then
			table.remove(t, index)
			return true
		end
	end

	return false
end


---@param field system.field.entity_grid
---@param id string|number
---@return entity|nil
function M.get_entity_by_id(field, id)
	for entity, ij in pairs(field.entities) do
		if entity.id == id then
			return entity
		end
	end

	return nil
end


return M
