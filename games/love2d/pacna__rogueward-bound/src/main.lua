-- core
local gamecore = require("core.game")

function love.load()
    gamecore.init()
end

function love.update(dt)
    gamecore.update(dt)
end

function love.keypressed(key)
    gamecore.move(key)
end

function love.draw()
    gamecore.draw()
end
