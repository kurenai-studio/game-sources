local Game = require("src.core.game")

local game

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.mouse.setVisible(true)
    love.math.setRandomSeed(os.time())

    game = Game.new()
    game:load()
end

function love.update(dt)
    if game then
        game:update(dt)
    end
end

function love.draw()
    if game then
        game:draw()
    end
end

function love.resize(width, height)
    if game then
        game:resize(width, height)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if game then
        game:keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if game then
        game:keyreleased(key, scancode)
    end
end

function love.textinput(text)
    if game then
        game:textinput(text)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if game then
        game:mousepressed(x, y, button, istouch, presses)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if game then
        game:touchpressed(id, x, y, dx, dy, pressure)
    end
end
