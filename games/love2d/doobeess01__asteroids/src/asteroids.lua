require("move")


function new_asteroid()
    window_width,window_height,flags = love.window.getMode()
    local asteroid = {
        width=love.math.random(40,100),
        height=love.math.random(40,100),
        dx = love.math.random(-50,50),
        dy = love.math.random(40,150)
    }
	if math.random() > .95 then
		asteroid.width = 300
		asteroid.height = 300
    end

    asteroid.x = love.math.random(0,window_width-asteroid.width)

    if math.random() > .98 and time_elapsed > 10 then
        asteroid.width = 4
        asteroid.height = 1000
        asteroid.x = love.graphics.getWidth()/2-2
        asteroid.dx = 0
        asteroid.dy = 100
    end

    asteroid.y = -asteroid.height

    return asteroid
end
