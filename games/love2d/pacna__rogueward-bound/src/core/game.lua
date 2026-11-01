-- core
local roguecore = require("core.rogue")
local layoutcore = require('core.layout')

-- factories
local rendererfactory = require('factories.renderer')
local handlerfactory = require('factories.messagebus.handler')
local publisher = require('factories.messagebus.publisher')

local game = {}

function game.init()
    layoutcore.load()
    roguecore.loadWorld()
end

function game.update(dt)
    handlerfactory.run()
    roguecore.currentPlayer:update(dt)
end

function game.draw()
    rendererfactory.renders()
end

function game.move(key)
    publisher.send(publisher.Types.KEYBOARD, { keycode = key })
end

return game
