local Player = {}

function Player:new(configs)
    self.__index = self
    local frames = {}
    local spriteSize = 32;

    for y = 0, configs.idleSheet:getHeight() - spriteSize, spriteSize do
        for x = 0, configs.idleSheet:getWidth() - spriteSize, spriteSize do
            table.insert(frames, love.graphics.newQuad(x, y, spriteSize, spriteSize, configs.idleSheet:getDimensions()))
        end
    end

    return setmetatable({
        xPos = configs.xPos,
        yPos = configs.yPos,
        health = configs.health,
        xp = configs.xp,
        atk = configs.atk,
        imgSrc = configs.imgSrc,
        idleSheet = configs.idleSheet,
        frames = frames,
        currentTime = 0,
        duration = 1
    }, self)
end

function Player:debugPrint()
    print("x: " .. self.xPos, "y: " .. self.yPos, "health: " .. self.health, "XP: " .. self.xp, "ATK: " .. self.atk)
end

function Player:update(dt)
    self.currentTime = self.currentTime + dt
    if self.currentTime >= self.duration then
        self.currentTime = self.currentTime - self.duration
    end
end

function Player:setPos(pos)
    self.xPos = pos.x
    self.yPos = pos.y
end

function Player:addHealth(health)
    self.health = self.health + health
end

function Player:subtractHealth(health)
    self.health = self.health - health
end

function Player:addXP(xp)
    self.xp = self.xp + xp
end

function Player:addAtkPower(atk)
    self.atk = self.atk + atk
end

return Player
