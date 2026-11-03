local const = require("system.field.field.const")

local M = {}
M.TILE_SIZE = 192

function M.round(num, numDecimalPlaces)
	local mult = 10 ^ (numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end


---@param x number
---@param y number
---@return number, number
function M.get_ij(x, y)
	local i = M.round((x + M.TILE_SIZE / 2) / M.TILE_SIZE) + 1
	local j = M.round((y + M.TILE_SIZE / 2) / M.TILE_SIZE) + 1

	return i, j
end


---@param i number
---@param j number
---@return number, number
function M.get_xy(i, j)
	local x = (i - 1) * M.TILE_SIZE
	local y = (j - 1) * M.TILE_SIZE

	return x, y
end


--- delta_i = lateral (positive = "right" relative to facing), delta_j = forward steps along `side`.
---@param i integer
---@param j integer
---@param side string
---@param delta_i integer
---@param delta_j integer
---@return integer, integer
function M.cell_from_facing_delta(i, j, side, delta_i, delta_j)
	local sd = const.TURN_SIDE_DATA[side]
	if not sd or side == const.TURN_SIDE.NONE then
		return i + delta_i, j + delta_j
	end

	local fi, fj = sd.i, sd.j
	local ri, rj = fj, -fi

	return i + delta_i * ri + delta_j * fi, j + delta_i * rj + delta_j * fj
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


---@param field field.grid
---@param id string|number
---@return field.entity|nil
function M.get_entity_by_id(field, id)
	return field:get_entity(id)
end


return M
