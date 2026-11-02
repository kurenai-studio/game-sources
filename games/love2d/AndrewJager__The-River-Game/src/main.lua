--Big Fish references added: 0

local world = {}
world.map = {}
world.keys = {}
world.level = "menu"
world.curLevel = "menu"
world.btnFont = love.graphics.newFont(32)
world.font = love.graphics.newFont(12)
world.titleFont = love.graphics.newFont(48)

loader = require "mapLoader"
local river = require "river"
local menu = require "menu"
local gameOver = require "gameOver"

function love.load()
    love.window.setTitle("The River")
    love.window.setMode(900, 650)
    menu.load(world)
end

function love.update(dt)
    world.keys = getInput()
    if world.level == "menu" then
        menu.update(dt)
    elseif world.level == "river" then
        river.update(world, dt)
    elseif world.level == "gameOver" then
        gameOver.update(dt)
    end

    if world.level ~= world.curLevel then
        if world.level == "menu" then
            menu.load(world)
        elseif world.level == "river" then
            river.load(world)
        elseif world.level == "gameOver" then
            gameOver.load(world)
        end
        world.curLevel = world.level
    end
end

function love.draw()
    if world.level == "menu" then
        menu.draw()
    elseif world.level == "river" then
        river.draw(world)
    elseif world.level == "gameOver" then
        gameOver.draw(world)
    end
end

function getInput()
    local keys = {}
    keys.right = love.keyboard.isDown("right")
	keys.left = love.keyboard.isDown("left")
	keys.up = love.keyboard.isDown("up")
    keys.down = love.keyboard.isDown("down")
    keys.a = love.keyboard.isDown("a")
    keys.d = love.keyboard.isDown("d")
    keys.z = love.keyboard.isDown("z")
    keys.x = love.keyboard.isDown("x")
    keys.c = love.keyboard.isDown("c")
    keys.h = love.keyboard.isDown("h")
    keys.one = love.keyboard.isDown("1")
    keys.two = love.keyboard.isDown("2")
    keys.space = love.keyboard.isDown("space")

    return keys
end