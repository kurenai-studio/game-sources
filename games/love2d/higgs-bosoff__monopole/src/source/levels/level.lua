local Level = {}

Level.shipq = 1

function Level:new (arg)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return Level