local Turtle = require("turtle")

local my_turtle = Turtle()

function circle()
    my_turtle:pensize(30)
    my_turtle:up()
    my_turtle:right(90):forward(275):left(90)
    -- draw line only AFTER this
    my_turtle:down()
    local nodes = 360
    local angle = 360 / nodes
    -- triangle:color({1,0,0})
    -- turtle.lua supports chain methods as you can see below
    -- triangle:forward(60):left(120):forward(60):left(120):forward(60):right(50):forward(20)
    for i = 1, nodes do
        my_turtle:color(math.random(), math.random(), math.random())
        my_turtle:forward(4):left(angle)
    end
end

function filled_circle()
    local nodes = 360
    local angle = 360 / nodes
    for i = 1, nodes do
        my_turtle:color(math.random(), math.random(), math.random())
        my_turtle:up()
        my_turtle:forward(60)
        my_turtle:down():forward(30)
        my_turtle:up():backward(90)
        my_turtle:down()
        my_turtle:left(angle)
    end
end

function square_snail(l0)
    -- pensize - 1 = what used
    local l = l0
    -- for i=1, l0/10 do
    while l > 0 do
        my_turtle:forward(l)
        my_turtle:right(90)
        l = l - 10
        my_turtle:color(math.random(), math.random(), math.random())
    end
end

function rectangular_snail(l0)
    -- pensize - 1 = what used
    local l = 300
    local w = 200

    -- for i=1, l0/10 do
    while l > 0 and w > 0 do
        my_turtle:forward(l)
        my_turtle:right(90)
        my_turtle:color(math.random(), math.random(), math.random())
        my_turtle:forward(w)
        my_turtle:right(90)
        l = l - 10
        w = w - 10
        my_turtle:color(math.random(), math.random(), math.random())
    end
end

function circle_snail(l0)
    local nodes = 360
    local angle = 360 / nodes
    local l = 1
    -- for i=1, l0/10 do

    --square:up()
    --square:right(90):forward(275):left(90)
    -- draw line only AFTER this
    --square:down()

    while l < 10 do
        my_turtle:forward(l)
        my_turtle:left(angle)
        l = l + 0.001
        my_turtle:color(math.random(), math.random(), math.random())
    end
end

-- Only called once, at the beginning.
function love.load()
    -- success = love.window.setFullscreen(true, "desktop")

    love.graphics.setBackgroundColor(1, 1, 1)
    my_turtle:speed(30)

    -- circle_snail(300)
end

-- called many times.
function love.draw()
    my_turtle:draw()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "s" then
        my_turtle = Turtle()
        square_snail(300)
        love.graphics.setBackgroundColor (1, 0, 0)
    elseif key == "r" then
        my_turtle = Turtle()
        rectangular_snail(10)
        love.graphics.setBackgroundColor (0, 1, 0)
    elseif key == "escape" then
        love.event.quit()
    end
end
