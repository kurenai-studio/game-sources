local Turtle = require("turtle")

local my_turtle = Turtle()

local is_at_start = true

local seconds_until_return_to_start = 0.0

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

function start_screen()
    love.graphics.setBackgroundColor(0, 0, 1)

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print("Hello", 100, 100)
end

-- Only called once, at the beginning.
function love.load()
    -- success = love.window.setFullscreen(true, "desktop")

    my_turtle:speed(30)
    --start_screen()

    -- circle_snail(300)
end

-- called many times.
function love.draw()
    -- love.graphics.setColor(0,0,0,1)
    -- love.graphics.print("Hello", 100, 100)
    if is_at_start then
        start_screen()
    else
        my_turtle:draw()
    end
end

function love.update(dt)
    seconds_until_return_to_start = seconds_until_return_to_start - dt
    if seconds_until_return_to_start <= 0 then
        is_at_start = true
    end
end

function love.keypressed(key, scancode, isrepeat)
    if key == "s" then
        is_at_start = false
        my_turtle = Turtle()
        square_snail(300)
        seconds_until_return_to_start = 7
        love.graphics.setBackgroundColor(1, 0, 0)
    elseif key == "r" then
        is_at_start = false
        my_turtle = Turtle()
        rectangular_snail(10)
        seconds_until_return_to_start = 7
        love.graphics.setBackgroundColor(0, 1, 0)
    elseif key == "escape" then
        love.event.quit()
    end
end
