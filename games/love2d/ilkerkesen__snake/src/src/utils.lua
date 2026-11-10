Rectangle = Object.extend(Object)

function Rectangle:new(i, j)
    self.i = i
    self.j = j
    self.size = TILE_SIZE
    self.pad = TILE_PAD
end

function Rectangle:draw()
    local pos = tile_position_to_coordinates(self.i, self.j)
    love.graphics.rectangle("fill", pos.x, pos.y, self.size-self.pad, self.size-self.pad)
end

function init_grid()
    local grid = {}
    for i=1,NUM_X_TILES do
        local row = {}
        for j=1,NUM_Y_TILES do
            table.insert(row, 0)
        end
        table.insert(grid, row)
    end
    return grid
end

function tile_position_to_coordinates(i,j)
    return {
        x = (i-1) * TILE_SIZE,
        y = (j-1) * TILE_SIZE
    }
end