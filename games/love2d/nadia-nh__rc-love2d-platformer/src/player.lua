-- player.lua
-- Handles player state, movement, and drawing

local player = {}

local playerImg

function player.load(images)
    -- Load player sprite and get the image size
    playerImg = images.playerImg
    player.w = playerImg:getWidth()
    player.h = playerImg:getHeight()

    player.speed = 100

    -- Spawn/Respawn position
    player.spawnX = 100
    player.spawnY = 300

    player.respawn()
end

-- Reset player to the spawn position
function player.respawn()
    player.x = player.spawnX
    player.y = player.spawnY
    player.vx = 0
    player.vy = 0
    player.onGround = false
end

-- Apply gravity and update player position
function player.update(dt, gravity)
    -- Horizontal input
    if (love.keyboard.isDown("left") or love.keyboard.isDown("a")) then
        player.vx = -player.speed
    elseif (love.keyboard.isDown("right") or love.keyboard.isDown("d")) then
        player.vx = player.speed
    else
        player.vx = 0
    end

    -- Gravity and movement
    player.vy = player.vy + gravity * dt
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Reset onGround to false
    player.onGround = false
end

-- Jump only when standing on a platform
function player.jump(jumpStrength)
    if player.onGround then
        player.vy = -jumpStrength
        player.onGround = false
    end
end

function player.draw()
    love.graphics.draw(playerImg, player.x, player.y)
end

return player
