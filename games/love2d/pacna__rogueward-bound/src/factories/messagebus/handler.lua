-- handlers
local positionhandler = require('handlers.position')
local keyboardhandler = require('handlers.keyboard')
local loghandler = require('handlers.log')
local itemhandler = require('handlers.item')
local brawlhandler = require('handlers.brawl')
local donehandler = require('handlers.done')

-- self
local messagebus = require('factories.messagebus.bus')

local handler = {}

local handlers = {
    [donehandler.Key] = donehandler.handleMessage,
    [keyboardhandler.Key] = keyboardhandler.handleMessage,
    [positionhandler.Key] = positionhandler.handleMessage,
    [loghandler.Key] = loghandler.handleMessage,
    [itemhandler.Key] = itemhandler.handleMessage,
    [brawlhandler.Key] = brawlhandler.handleMessage
}

function handler.run()

    if messagebus.isOff() then
        messagebus.remove()
    end

    if messagebus.isEmpty() then
        return
    end

    for _, handleMessage in pairs(handlers) do
        handleMessage(messagebus.peek())
    end

    messagebus.remove()

end

return handler
