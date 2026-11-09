-- Player.lua
local bullet = require 'modules.bullet'

local Player = {
    size = 32,
    speed = 256,
    color = {1.0, 1.0, 1.0, 1.0},
    x = 0, y = 0,
    speedX = 0, speedY = 0,
    shootCooldown = 0, id = nil,
    type = "player"
}
Player.__index = Player

function Player.new(x, y, id, customColor)
    local self = {}
    setmetatable(self, Player)

    -- World position
    self.x = x
    self.y = y

    self.id = id

    -- Physics settings
    if IsServer then
        self.body = love.physics.newBody(World, self.x, self.y, "dynamic")
        self.shape = love.physics.newRectangleShape(self.size, self.size)
        self.fixture = love.physics.newFixture(self.body, self.shape, 1.0)
        self.fixture:setUserData(self)
    end

    -- Optional color override
    if customColor then self.color = customColor end

    return self
end

function Player:update(dt, inputs, eventListener)
    self.speedX = 0
    self.speedY = 0

    local alreadyProcessed = {}
    for _, input in ipairs(inputs) do
        if not alreadyProcessed[input] then
            alreadyProcessed[input] = true

            if input == 'd' then
                self.speedX = self.speedX + self.speed
            end

            if input == 'a' then
                self.speedX = self.speedX - self.speed
            end

            if input == 's' then
                self.speedY = self.speedY + self.speed
            end

            if input == 'w' then
                self.speedY = self.speedY - self.speed
            end

            -- Mouse input
            local aimX, aimY = input:match("^aim:(%-?%d+):(%-?%d+)$")
            if aimX and aimY then

                -- This check avoids duplicated bullets, otherwise client would recreate the bullet
                -- when server broadcasted the spawn_bullet message
                if IsServer and self.shootCooldown == 0 then
                    self.shootCooldown = 1/10
                    aimX = tonumber(aimX)
                    aimY = tonumber(aimY)
                    local angle = math.atan2(aimY, aimX)
                    bullet.new(self.x, self.y, angle, eventListener, self.id)
                end
            end

            table.insert(alreadyProcessed, input)
        end
    end

    -- Vector normalization to avoid diagonal faster than self.speed
    local length = math.sqrt(self.speedX ^ 2 + self.speedY ^ 2)
    if length > 0 then
        self.speedX = self.speedX / length * self.speed
        self.speedY = self.speedY / length * self.speed
    end

    -- Position updating
    if IsServer then
        self.body:setLinearVelocity(self.speedX, self.speedY)
        self.x, self.y = self.body:getPosition()
    else
        self.x = self.x + self.speedX * dt
        self.y = self.y + self.speedY * dt
    end

    self.shootCooldown = math.max(0, self.shootCooldown - dt)
end

function Player:draw(cameraX, cameraY)
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill',
        -- Centralize camera on player and draws every other player relative to it
        self.x - cameraX - self.size / 2,
        self.y - cameraY - self.size / 2,
    self.size, self.size)
end

return Player