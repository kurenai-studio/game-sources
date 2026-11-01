

cursor = {}
-- where on the map the cursor starts
local START_X = 1
local START_Y = 1
local TILE_SIZE = 32

local MAP_MAX = 10
local MAP_MIN = 1

cursor.x = START_X
cursor.y = START_Y

function cursor.draw()
    love.graphics.setColor(0,20,40,50)
    love.graphics.rectangle("fill", cursor.x * TILE_SIZE, cursor.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
    love.graphics.setColor(255,255,255)
end

function cursor.move(dx, dy)
    if cursor.insideMap(dx, dy) then
        cursor.x = cursor.x + dx
        cursor.y = cursor.y + dy
    end
end

function cursor.insideMap(dx, dy)
    local xChange = cursor.x + dx
    local yChange = cursor.y + dy

    return (xChange >= MAP_MIN and xChange <= MAP_MAX) and (yChange >= MAP_MIN and yChange <= MAP_MAX)
end
