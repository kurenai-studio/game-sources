Object = require "libs.classic"
bump = require "libs.bump"
world = bump.newWorld()
bodies = {}
food = {}
diff = 0
gamestate = "playing"
score = 0
function love.load()
    local Player = require "Player"
    local Food = require "Food"
    player = Player(320, 180)
    food = Food()
end

function Add()
    local Body = require "Body"
    table.insert(bodies, Body(diff))
    diff = diff + 1
end

function love.update()
    if gamestate == "playing" then
        player:update()
        food:update()
        for i, v in ipairs(bodies) do
            v:update()
        end
    end
end

function love.keypressed(key)
    if key == "r" then
        if gamestate == "gameover" then
            ResetGame()
        end
    end
end

function ResetGame()
    for i, v in ipairs(bodies) do
        if world:hasItem(v) then
            world:remove(v)
        end
    end
    bodies = {}
    DirectionList = {}
    diff = 0
    player:ResetGame()
    food:ResetGame()
    gamestate = "playing"
    score = 0
end

function love.draw()
    if gamestate == "playing" then
        food:draw()
        player:draw()
        for i, v in ipairs(bodies) do
            v:draw()
        end
        love.graphics.printf("Score: " .. score, 0, 0, love.graphics.getWidth(), "left")
    end
    if gamestate == "gameover" then
        love.graphics.printf("You lost!", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        love.graphics.printf('Press "R" to restart', 0, love.graphics.getHeight() / 2 + 40, love.graphics.getWidth(),
            "center")
        love.graphics.printf("Your Score was " .. score, 0, love.graphics.getHeight() / 2 + 20, love.graphics.getWidth(),
            "center")
    end
end
