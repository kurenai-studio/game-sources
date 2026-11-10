local Body = Object:extend()

function Body:new(diff)
    self.diff = diff
    self.x = DirectionList[#DirectionList - self.diff].x
    self.y = DirectionList[#DirectionList - self.diff].y
    self.width = 20
    self.height = 20
    self.start = love.timer.getTime()
    world:add(self, self.x, self.y, self.width, self.height)
    self.isBody = true
end

local BodyFiliter = function(item,other)
    if other.isFood then
        return "cross"
    end
end

function Body:update()
    if #DirectionList - self.diff > 0 then
        self.x = DirectionList[#DirectionList - self.diff].x
        self.y = DirectionList[#DirectionList - self.diff].y
    end
    local TrueX, TrueY = world:move(self, self.x, self.y,BodyFiliter)
    self.x = TrueX
    self.y = TrueY
end

function Body:draw()
    love.graphics.setColor(31 / 255, 50 / 255, 255 / 255)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
end

return Body
