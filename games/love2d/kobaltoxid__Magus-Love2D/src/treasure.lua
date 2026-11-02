local treasure = {
    name = 'treasure',
    sprite = '',
    x = 0,
    y = 0,
    key = true,
    final = false
}

-- Initialize health potion object.
function treasure:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function treasure:setPos(xPos, yPos)
    self.x, self.y = xPos, yPos
end

function treasure:setSprite(quad)
    self.sprite = quad
end

function treasure:take()
    self.key = false
end

return treasure
