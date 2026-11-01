function table.clone(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end
function circle_rect_collision(cx, cy, r, rx, ry, rw, rh)
    if (rx + rw >= cx - r) and (rx <= cx + r) and (ry + rh >= cy - r) and (ry <= cy + r) then
        return true
    else
        return false
    end
end

function love.load()
    player = {}
    player.h = 200
    player.w = 5
    player.x = 5
    player.y = love.graphics.getHeight() / 2 - player.h / 2
    player.speed = 2
    player.scoop = 0

    bot = table.clone(player)
    bot.x = love.graphics.getWidth() - bot.w - 5

    ball = {}
    ball.radius = 2.5
    ball.x = love.graphics.getWidth() / 2 - ball.radius + love.math.random(-500, 500)/10
    ball.y = love.graphics.getHeight() / 2 - ball.radius + love.math.random(-200, 200)
    ball.x_speed = love.math.random(-1, 0)
    if ball.x_speed == 0 then
        ball.x_speed = 1
    end
    ball.y_speed = love.math.random(-1, 0)
    if ball.y_speed == 0 then
        ball.y_speed = 1
    end
    ball.kf = 1.1
    ball.y_speed_constant = ball.y_speed
end

function love.update(dt)
    if love.keyboard.isDown("up") and player.y > 0 then
        player.y = player.y - player.speed
    end
    if love.keyboard.isDown("down") and player.y + player.h < love.graphics.getHeight() then
        player.y = player.y + player.speed
    end
    ball.x = ball.x + ball.x_speed * ball.kf
    ball.y = ball.y + ball.y_speed * ball.kf

    if ball.y - ball.radius < 0 or ball.y + ball.radius > love.graphics.getHeight() then
        ball.y_speed = -ball.y_speed
    end

    if ball.y - 20 * ball.kf > bot.y and bot.y + bot.h  < love.graphics.getHeight() then
        bot.y = bot.y + bot.speed
    end
    
    if ball.y + 20 * ball.kf < bot.y + bot.h and bot.y > 0 then
        bot.y = bot.y - bot.speed
    end

    if circle_rect_collision(ball.x, ball.y, ball.radius, player.x, player.y, player.w, player.h) then
        ball.x_speed = -ball.x_speed

        local center = player.y + player.h / 2
        local offset = (ball.y - center) / (player.h / 2)

        ball.y_speed = offset * ball.y_speed_constant
    end
    if circle_rect_collision(ball.x, ball.y, ball.radius, bot.x, bot.y, bot.w, bot.h) then
        ball.x_speed = -ball.x_speed

        local center = bot.y + bot.h / 2
        local offset = (ball.y - center) / (bot.h / 2)

        ball.y_speed = offset * ball.y_speed_constant
    end

    if ball.x - ball.radius <= 0 then
        bot.scoop = bot.scoop + 1
        ball.x = love.graphics.getWidth() / 2 - ball.radius + love.math.random(-500, 500)/10
        ball.y = love.graphics.getHeight() / 2 - ball.radius + love.math.random(-200, 200)
        ball.x_speed = love.math.random(-1, 0)
        if ball.x_speed == 0 then
            ball.x_speed = 1
        end
        ball.y_speed = love.math.random(-1, 0)
        if ball.y_speed == 0 then
            ball.y_speed = 1
        end
        ball.y_speed_constant = ball.y_speed
        ball.kf = 1.1
    end
    if ball.x + ball.radius >= love.graphics.getWidth() then
        player.scoop = player.scoop + 1
        ball.x = love.graphics.getWidth() / 2 - ball.radius + love.math.random(-500, 500)/10
        ball.y = love.graphics.getHeight() / 2 - ball.radius + love.math.random(-200, 200)
        ball.x_speed = love.math.random(-1, 0)
        if ball.x_speed == 0 then
            ball.x_speed = 1
        end
        ball.y_speed = love.math.random(-1, 0)
        if ball.y_speed == 0 then
            ball.y_speed = 1
        end
        ball.y_speed_constant = ball.y_speed
        ball.kf = 1.1
    end
end

function love.draw()
    love.graphics.print(tostring(player.scoop), love.graphics.getWidth()/3, 5)
    love.graphics.print(tostring(bot.scoop), love.graphics.getWidth()/3*2, 5)
    love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)
    love.graphics.rectangle("fill", bot.x, bot.y, bot.w, bot.h)
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)
    local x = love.graphics.getWidth() / 2
    for y=0, love.graphics.getHeight(), 50 do
        love.graphics.line(x, y, x, y+25)
    end
end