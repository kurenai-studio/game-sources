local Food = Object:extend()

function Food:new()
    self.x = love.math.random(0, 31) * 20
    self.y = love.math.random(0, 17) * 20
    self.width = 20
    self.height = 20
    world:add(self, self.x, self.y, self.width, self.height)
    self.isFood = true
end

function Food:spawn()
    local isSafe = false
    local NewX, NewY
    while not isSafe do
        isSafe = true
        NewX = love.math.random(0, 31) * 20
        NewY = love.math.random(0, 17) * 20
        local items, len = world:queryRect(NewX, NewY, self.width, self.height)
        for i, v in ipairs(items) do
            if v ~= self then
                isSafe = false
                break
            end
        end
    end

    self.x = NewX
    self.y = NewY
    world:update(self, self.x, self.y)
end

local function filter(item, other)
    if other.isPlayer then
        return "cross"
    end
    return "cross"
end

function Food:update()
    TrueX, TrueY, cols, len = world:move(self, self.x, self.y, filter)

    for i, v in ipairs(cols) do
        if v.other.isPlayer then
            self:spawn()
            Add()
            score = score + 1
        end
    end
end

function Food:ResetGame()
    food.x = love.math.random(0, 31) * 20
    food.y = love.math.random(0, 17) * 20
    world:update(food, food.x, food.y)
end

function Food:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
end

return Food
