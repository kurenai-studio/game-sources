potion_swiftness = {
    name = 'potion_of_swiftness',
    sprite = '',
    x = 0,
    y = 0,
    speed = 70,
    taken = false
}

-- Initialize health potion object.
function potion_swiftness:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function potion_swiftness:setPos(xPos, yPos)
    self.x, self.y = xPos, yPos
end

function potion_swiftness:setSprite(quad)
    self.sprite = quad
end

function potion_swiftness:take()
    self.taken = true
    return self.speed
end

return potion_swiftness
