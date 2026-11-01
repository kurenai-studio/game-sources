-- entities
local Message = require('entities.message')

-- self
local messagebus = require('factories.messagebus.bus')

local publisher = {}

--[[const]]
publisher.Types = {
    KEYBOARD = "keyboard",
    POSITION = "position",
    LOG = "log",
    ITEM = "item",
    BRAWL = "brawl",
    DONE = "done"
}

function publisher.send(key, value)
    local msg = Message:new(key, value)
    messagebus.add(msg)
end

function publisher.off()
    messagebus.stop()
end

return publisher
