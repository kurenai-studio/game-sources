-- Bullet.lua
local Bullet = {
    size = 8,
    speed = 512,
    color = {1.0, 1.0, 0.0, 1.0},
    x = 0, y = 0,
    speedX = 0, speedY = 0,
    timer = 0, duration = 5,
    dead = false, shooterID = nil,
    type = "bullet", eventListener = nil,
    id = nil
}
Bullet.__index = Bullet

Bullet.bulletList = {}

local nextId = 1

function Bullet.new(x, y, direction, eventListener, shooterID, id, customColor)
    local self = {}
    setmetatable(self, Bullet)

    -- World position
    self.x = x
    self.y = y

    if id then
        self.id = id
    else
        self.id = nextId
        nextId = nextId + 1
    end
    self.shooterID = shooterID

    -- Physics settings
    if IsServer then
        self.body = love.physics.newBody(World, self.x, self.y, "dynamic")
        self.shape = love.physics.newRectangleShape(self.size, self.size)
        self.fixture = love.physics.newFixture(self.body, self.shape, 1.0)
        self.fixture:setUserData(self)
    end

    self.speedX = math.cos(direction) * self.speed
    self.speedY = math.sin(direction) * self.speed

    -- Optional color override
    if customColor then self.color = customColor end

    Bullet.bulletList[self.id] = self

    if IsServer then
        eventListener({
            type="spawn_bullet", data={
                x=x, y=y, direction=direction, id=self.id, shooterID=shooterID
        }})
        self.eventListener = eventListener
    end

    return self
end

function Bullet:update(dt)
    self.timer = self.timer + dt

    -- Position updating
    if IsServer then
        if not self.body then return end
        self.body:setLinearVelocity(self.speedX, self.speedY)
        self.x, self.y = self.body:getPosition()
    else
        self.x = self.x + self.speedX * dt
        self.y = self.y + self.speedY * dt
    end

    if self.timer >= self.duration then
        self.dead = true
    end

    if self.dead then self:destroy() end
end

function Bullet:destroy()
    Bullet.bulletList[self.id] = nil
    if IsServer then
        self.eventListener({type="destroy_bullet", data={id=self.id}})
        self.body:destroy()
        self.body = nil
        self.shape = nil
        self.fixture = nil
    end
end

function Bullet:draw(cameraX, cameraY)
    love.graphics.setColor(self.color)
    love.graphics.rectangle('fill',
        self.x - cameraX - self.size / 2,
        self.y - cameraY - self.size / 2,
    self.size, self.size)
end

return Bullet