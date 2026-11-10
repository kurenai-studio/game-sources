function love.load()
    math.randomseed(os.time())
    score_font = love.graphics.newFont(50)
    menu_font = love.graphics.newFont(20)
    love.window.setTitle("\"Pong\"")
    set_initial_conditions()
end

function love.update(dt)
    --game_paused = not game_paused -- "Slow-mo"
    if not game_ended and not game_paused then
        -- Players' movement
        if love.keyboard.isDown("w") then
            player1.y = player1.y - PLAYER_SPEED
        elseif love.keyboard.isDown("s") then
            player1.y = player1.y + PLAYER_SPEED
        end
        if love.keyboard.isDown("up") then
            player2.y = player2.y - PLAYER_SPEED
        elseif love.keyboard.isDown("down") then
            player2.y = player2.y + PLAYER_SPEED
        end
        -- Stop players from going out of bounds
        if player1.y < 0 then
            player1.y = 0
        elseif player1.y > 600 - 100 then
            player1.y = 600 - 100
        end
        if player2.y < 0 then
            player2.y = 0
        elseif player2.y > 600 - 100 then
            player2.y = 600 - 100
        end

        -- Update ball
        ball.x = ball.x + ball.speed_x
        ball.y = ball.y + ball.speed_y
        -- Ball hits the border(player doesn't hit the ball)
        if ball.x < 0 then
            reset_ball()
            player2.score = player2.score + 1
        elseif ball.x > love.graphics.getWidth()-ball.width then
            reset_ball()
            player1.score = player1.score + 1
        end
        -- Ball hits floor or ceiling
        if ball.y < 0 or ball.y > love.graphics.getHeight()-ball.height then
            ball.speed_y = ball.speed_y * -1
        end
        -- Ball hits player1 or player2
        if is_colliding(player1, ball) or is_colliding(player2, ball) then
            ball.speed_x = ball.speed_x * -1
            if ball.speed_x > 0 then
                ball.speed_x = ball.speed_x + 1
            else
                ball.speed_x = ball.speed_x - 1
            end
        end
    end
end

function love.draw()
    -- Draw the ball and players
    love.graphics.rectangle("fill", player1.x, player1.y, player1.width, player1.height)
    love.graphics.rectangle("fill", player2.x, player2.y, player2.width, player2.height)
    love.graphics.circle("fill", ball.x+ball.radius, ball.y+ball.radius, ball.radius)
    -- Draw the players' scores
    love.graphics.setFont(score_font)
    love.graphics.print(player1.score, 120, 70)
    love.graphics.print(player2.score, love.graphics.getWidth()-120, 70)

    love.graphics.setFont(menu_font)
    if game_ended then
        love.graphics.printf("GG", love.graphics.getWidth()/4, love.graphics.getHeight()/2, love.graphics.getWidth()/2, "center")
    end
    if game_paused then
        love.graphics.printf("PAUSED", love.graphics.getWidth()/4, love.graphics.getHeight()/2-100,love.graphics.getWidth()/2 , "center")
    end
end

function love.keypressed(key)
    if key == "p" then
        game_paused = not game_paused
    end
    if key == "r" then
        set_initial_conditions()
    end
    if key == "escape" then
        love.event.quit()
    end
end

-- Returns true if obj1 is colliding with obj2
function is_colliding(obj1, obj2)
    return obj1.x+obj1.width > obj2.x and obj1.y+obj1.height > obj2.y and obj2.x+obj2.width > obj1.x and obj2.y+obj2.height > obj1.y
end

-- Function used to reset the game
function set_initial_conditions()
    game_paused = false
    game_ended = false
    PLAYER_SPEED = 10
    player1 = {
        x = 50,
        y = love.graphics.getHeight()/2-50,
        width = 20,
        height = 100,
        score = 0,
    }
    player2 = {
        x = love.graphics.getWidth() - 20 - 50,
        y = love.graphics.getHeight()/2-50,
        width = 20,
        height = 100,
        score = 0,
    }
    local direction_table = {-1, 1}
    local starting_direction = direction_table[math.random(1, 2)]
    ball = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2,
        speed_x = math.random(2, 5) * starting_direction,
        speed_y = math.random( -10, 10),
        width = 30,
        height = 30,
        radius = 15,
    }
end

-- Function used to reset the ball without reseting the player's scores
function reset_ball()
    local direction_table = {-1, 1}
    local starting_direction = direction_table[math.random(1, 2)]
    ball = {
        x = love.graphics.getWidth()/2,
        y = love.graphics.getHeight()/2,
        speed_x = math.random(2, 5) * starting_direction,
        speed_y = math.random( -10, 10),
        width = 30,
        height = 30,
        radius = 15,
    }
    player1.y = love.graphics.getHeight()/2-50
    player2.y = love.graphics.getHeight()/2-50
end
