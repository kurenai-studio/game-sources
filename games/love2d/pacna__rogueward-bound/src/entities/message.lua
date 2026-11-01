local Message = {}

function Message:new(key, value)
    self.__index = self
    return setmetatable({
        key = key,
        value = value
    }, self)
end

return Message
