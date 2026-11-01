local State = {}

function State:load(arg)
end

function State:update(dt)
end 

function State:draw()
end

function State:new (arg)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o:load(arg)
    return o
end

return State