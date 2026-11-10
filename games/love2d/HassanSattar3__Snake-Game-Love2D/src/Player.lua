local Player = Object:extend()
DirectionList = {}
function Player:new(x, y)
    self.x = 320
    self.y = 180
    self.width = 20
    self.height = 20
    self.distance = 20
    self.direction = "right"
    self.start = love.timer.getTime()
    world:add(self, self.x, self.y, self.width, self.height)
    self.isPlayer = true
end

local playerFilter = function(item, other)
    if other.isCoin then
        return "cross"
    end
    if other.isBody then
        return "slide"
    end
end

function Player:update()
    self:getInput()
    self:MoveUpdate()
    self:CheckBoundaries()
end

function Player:getInput()
    if love.keyboard.isDown("left", "a") then
        if self.direction ~= "right" then
            self.direction = "left"
        end
    end
    if love.keyboard.isDown("right", "d") then
        if self.direction ~= "left" then
            self.direction = "right"
        end
    end
    if love.keyboard.isDown("up", "w") then
        if self.direction ~= "down" then
            self.direction = "up"
        end
    end
    if love.keyboard.isDown("down", "s") then
        if self.direction ~= "up" then
            self.direction = "down"
        end
    end
end

function Player:MoveUpdate()
    if gamestate ~= "playing" then return end
    local GoalX = self.x
    local GoalY = self.y
    if love.timer.getTime() - self.start >= 0.1 then
        self:UpdatePrevPosition()
        if self.direction == "up" then
            GoalY = self.y - self.distance
        elseif self.direction == "down" then
            GoalY = self.y + self.distance
        elseif self.direction == "right" then
            GoalX = self.x + self.distance
        elseif self.direction == "left" then
            GoalX = self.x - self.distance
        end
        self.start = love.timer.getTime()
        local TrueX, TrueY, cols, len = world:move(self, GoalX, GoalY, playerFilter)
        self.x = TrueX
        self.y = TrueY
        for i, v in ipairs(cols) do
            if v.other.isBody then
                if gamestate == "playing" then
                    gamestate = "gameover"
                end
            end
        end
    end
end

function Player:CheckBoundaries()
    if self.x + self.width < 0 or self.x >= love.graphics.getWidth() or self.y + self.height < 0 or self.y >= love.graphics.getHeight() then
        if gamestate == "playing" then
            gamestate = "gameover"
        end
    end
end

function Player:UpdatePrevPosition()
    local PlayerPosition = {}
    PlayerPosition.x = self.x
    PlayerPosition.y = self.y
    table.insert(DirectionList, PlayerPosition)
end

function Player:ResetGame()
    player.x = 320
    player.y = 180
    world:update(player, player.x, player.y)
    player.direction = "right"
end

function Player:draw()
    love.graphics.setColor(31 / 255, 81 / 255, 255 / 255)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
end

return Player
