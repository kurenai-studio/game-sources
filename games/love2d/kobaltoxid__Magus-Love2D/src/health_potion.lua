health_potion = {
    name = 'health_potion',
    sprite = '',
    x = 0,
    y = 0,
    hp = 50,
    taken = false
}

-- Initialize health potion object.
function health_potion:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function health_potion:setPos(xPos, yPos)
    self.x, self.y = xPos, yPos
end

function health_potion:setSprite(quad)
    self.sprite = quad
end

function health_potion:take(po)
    self.taken = true
    po.health = po.health + self.hp
    return po.health
end

function health_potion:damage()
    self.hp = self.hp * -2
end

return health_potion
