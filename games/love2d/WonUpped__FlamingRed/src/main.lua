function love.load()
    love.window.setTitle("FlamingRed")
    x = 500
    y = 600
end

function love.update(dt)
    if love.keyboard.isDown("right") then
        x = x + 200 * dt
    elseif love.keyboard.isDown("left") then
        x = x - 200 * dt
    elseif love.keyboard.isDown("up") then
        y = y - 200 * dt --subtract to go up for some reason
    elseif love.keyboard.isDown("down") then
        y = y + 200 * dt --hence, add to go down?

    end
end

function love.draw()
    love.graphics.circle("fill", x, y, 50)
end