Food = Rectangle:extend()

function Food:new()
    local empty_locations = {}
    for i = 1,NUM_X_TILES do
        for j = 1,NUM_Y_TILES do
            if grid[i][j] == 0 then
                table.insert(empty_locations, {i,j})
            end
        end
    end
    local indx = love.math.random(1, #empty_locations)
    local i = empty_locations[indx][1]
    local j = empty_locations[indx][2]
    Food.super.new(self, empty_locations[indx][1], empty_locations[indx][2])
    grid[i][j] = 1
end

function Food:draw()
    love.graphics.setColor(1, 0, 0)
    Food.super.draw(self)
end