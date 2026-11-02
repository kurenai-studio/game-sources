-- Default enemy object.
local Enemy = {
    name = 'enemy',
    sprite = '',
    xPos = 0,
    yPos = 0,
    originX = 0,
    originY = 0,
    width = 16,
    height = 16,
    damage = 1,
    health = 100,
    dir = 1,
    flip = 1,
    alive = true
}

-- Initialize enemy object.
function Enemy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Self explanatory.
function Enemy:attack(p)
    local result = p.health - self.damage
    return result
end

-- Prerequisites for movement.
-- local direction = -1
local initialtime = love.timer.getTime()
local axisY = false
local direction = 0

-- Default enemy movement.
function Enemy:walk(goalX, goalY, dt)
    local stoptimer = 5 -- 5 seconds
    local speed = 50

    local timer = love.timer.getTime() - initialtime
    if timer > stoptimer then
        direction = math.random(1, 1000323)
        initialtime = love.timer.getTime()
        if direction % 3 == 0 then
            self.dir = self.dir * -1
        else
            self.dir = self.dir * 1
        end
        -- dir = smartTimes % 3 == 0 and dir * -1 or dir * 1
        axisY = axisY == false and true or false
    end

    if axisY == true then
        goalY = goalY + speed * dt * self.dir
    else
        goalX = goalX + speed * dt * self.dir
    end

    return goalX, goalY, self.dir

end

-- Set enemy position.
function Enemy:setPos(xPos, yPos)
    self.xPos = xPos
    self.yPos = yPos
    self.originX = xPos
    self.originY = yPos
end

-- Flip sprite.
function Enemy:flipEnemy(flip)
    self.flip = flip
end

-- Set enemy sprite.
function Enemy:setSprite(quad)
    self.sprite = quad
end

-- Calculate distance between two points.
function dist(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- Function to return what coordinates to chase.
function Enemy:chase(playerX, playerY, dt)
    local speed = 80
    local actualX, actualY = self.xPos, self.yPos
    local goalX = playerX - actualX
    local goalY = playerY - actualY
    local distance = math.sqrt(goalX * goalX + goalY * goalY)
    if dist(actualX, actualY, playerX, playerY) ~= 0 then -- avoid division by zero
        actualX = actualX + goalX / distance * speed * dt
        actualY = actualY + goalY / distance * speed * dt
    end
    return actualX, actualY
end

-- Change enemy object damage.
function Enemy:changeDamage(damage)
    self.damage = damage
end

-- Change enemy object direction.
function Enemy:changeDir(dir)
    self.dir = dir
end

-- Change enemy type.
function Enemy:changeType(type)
    self.name = type
end

return Enemy
