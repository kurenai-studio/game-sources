local square = {}
square.x = 1
square.y = 4
square.w = 50
square.h = 50

local r = {}
r.w = 30
r.h = 30

local g = {}
g.w = 30
g.h = 30

local b = {}
b.w = 30
b.h = 30

local before = 'b'

local objrand = function ()
    r.x = math.random(800 - r.w)
    r.y = math.random(600 - r.h)


    g.x = math.random(800 - g.w)
    g.y = math.random(600 - g.h)


    b.x = math.random(800 - b.w)
    b.y = math.random(600 - b.h)
end

local point = 0

local collision = require('collision')

function love.load()
    love.mouse.setVisible(false)

    math.randomseed(os.time())
    objrand()

    end

function love.update(dt)
    if collision.aabb(square, r) and before == 'b' then
	point = point + 1
	before = "r"
	objrand()
    end
    if collision.aabb(square, g) and before == "r" then
        point = point + 1
        before = "g"
        objrand()
    end
    if collision.aabb(square, b) and before == "g" then
        point = point + 1
        before = "b"
        objrand()
        end
end
function love.draw()
    square.x, square.y = love.mouse.getPosition()
    love.graphics.setColor(255,255,255)
    love.graphics.print('Points: '..tostring(point))
    love.graphics.rectangle("fill", square.x, square.y, square.w, square.h)
    love.graphics.setColor(255,0,0)
    love.graphics.rectangle("fill", r.x, r.y, r.w, r.h)
    love.graphics.setColor(0,255,0)
    love.graphics.rectangle("fill", g.x, g.y, g.w, g.h)
    love.graphics.setColor(0,0,255)
    love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
end
