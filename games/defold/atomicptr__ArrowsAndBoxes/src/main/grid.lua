---@generic T
---@class GridItem
---@field data T|nil
---@field x    integer
---@field y    integer

---@generic T
---@class Grid
---@field data   GridItem<T>[]
---@field width  integer
---@field height integer
local M = {}
M.__index = M

---@param width  integer
---@param height integer
---@return Grid
function M.new(width, height)
    local data = {}

    for y = 1, height do
        for x = 1, width do
            table.insert(data, { x = x, y = y, data = nil })
        end
    end

    local instance = {
        data = data,
        width = width,
        height = height,
    }

    return setmetatable(instance, M)
end

---@param self Grid
---@param x integer
---@param y integer
---@return integer
function M:index(x, y)
    assert(x >= 1 and y >= 1 and x <= self.width and y <= self.height, "x/y is out of bounds")
    return (y - 1) * self.width + x
end

---@generic T
---@param self Grid<T>
---@param x    integer
---@param y    integer
---@return T|nil
function M:get(x, y)
    local item = self.data[self:index(x, y)]
    return item.data
end

---@generic T
---@param self  Grid<T>
---@param x     integer
---@param y     integer
---@param value T|nil
function M:set(x, y, value)
    local target_index = self:index(x, y)
    self.data[target_index].data = value
end

---@generic T
---@param self Grid<T>
---@param x    integer
---@param y    integer
---@return boolean
function M:has(x, y)
    return self:get(x, y) ~= nil
end

---@generic T
---@param self   Grid<T>
---@param from_x integer
---@param from_y integer
---@param to_x   integer
---@param to_y   integer
function M:move(from_x, from_y, to_x, to_y)
    assert(self:has(from_x, from_y), "from position has to contain something")
    assert(not self:has(to_x, to_y), "to position has to be empty")

    local from_index = self:index(from_x, from_y)
    local to_index = self:index(to_x, to_y)

    local from_data = self.data[from_index].data
    self.data[from_index].data = nil
    self.data[to_index].data = from_data
end

---@generic T
---@param self     Grid<T>
---@param callback fun(item: T, x: integer, y: integer)
function M:for_each(callback)
    for _, item in ipairs(self.data) do
        if item.data ~= nil then
            callback(item.data, item.x, item.y)
        end
    end
end

---@generic T
---@param self Grid<T>
---@param x    integer
---@param y    integer
---@return { item: T, x: integer, y: integer }[]
function M:adjacent(x, y)
    local adjacent_items = {}

    for i = math.max(x - 1, 1), math.min(x + 1, self.width) do
        for j = math.max(y - 1, 1), math.min(y + 1, self.height) do
            if not (i == x and j == y) and (x == i or y == j) then
                local item = self:get(i, j)

                if item ~= nil then
                    table.insert(adjacent_items, {
                        item = item,
                        x = i,
                        y = j,
                    })
                end
            end
        end
    end

    return adjacent_items
end

---@generic T
---@param self     Grid<T>
---@param callback fun(item: T, x: integer, y: integer): boolean
---@return T|nil
---@return integer|nil
---@return integer|nil
function M:find(callback)
    for _, item in ipairs(self.data) do
        if item.data ~= nil and callback(item.data, item.x, item.y) then
            return item.data, item.x, item.y
        end
    end

    return nil
end

return M
