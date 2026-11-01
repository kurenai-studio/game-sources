PlayState = require('states.play')

game_global = {
    state=PlayState:new('arena_base')
}

function love.load(arg)
end

function love.update(dt)
    game_global.state:update(dt)
end

function love.draw()
    game_global.state:draw()
end