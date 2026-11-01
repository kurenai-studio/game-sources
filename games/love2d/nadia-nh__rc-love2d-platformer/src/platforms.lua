-- platforms.lua
-- Manages platform placement, collisions, and drawing

local platforms = {}

local platformImg
local platformWidth
local platformHeight

function platforms.load(images)
    -- Load platform sprite and get the image size
    platformImg = images.platformImg
    platformWidth = platformImg:getWidth()
    platformHeight = platformImg:getHeight()
end

-- Add a platform at a given world position
function platforms.addPlatform(x, y)
    table.insert(platforms, {
        x = x,
        y = y,
        w = platformWidth,
        h = platformHeight
    })
end

-- Placeholder in case we add movement or effects later
function platforms.update(dt)
end

-- Resolve player/platform collisions (landing on top of platforms)
function platforms.resolveCollisions(player, previousY)
    for _, p in ipairs(platforms) do
        if isColliding(player, p) then
            local previousBottom = previousY + player.h
            local platformTop = p.y

            -- If the player was above the platform last frame,
            -- snap them to the top and stop downward movement
            if previousBottom <= platformTop then
                player.y = platformTop - player.h
                player.vy = 0
                player.onGround = true
            end
        end
    end
end

function platforms.draw()
    for _, p in ipairs(platforms) do
        love.graphics.draw(platformImg, p.x, p.y)
    end
end

-- Axis-Aligned Bounding Box (AABB) collision check
function isColliding(obj1, obj2)
    local x1 = obj1.x
    local y1 = obj1.y
    local w1 = obj1.w
    local h1 = obj1.h
    local x2 = obj2.x
    local y2 = obj2.y
    local w2 = obj2.w
    local h2 = obj2.h
    
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

return platforms
