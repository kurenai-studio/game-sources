function love.load()
    screen_width = 500
    screen_height = 500

    love.window.setTitle("silly ping pong bing bong")
    love.window.setMode(screen_width, screen_height)
    love.window.setVSync(true)

    _G.gameStates = {
        isOver = false;
        score = 0;
    }

    _G.player = {
        x = 0;
        y = 0;
        xsize = 10;
        ysize = 50;
        speed = 500;
        move = function(speed, dt)
            player.y = player.y + speed * dt
        end;
    }

    _G.ball = {
        x = 240;
        y = 240;
        size = 10;
        xspeed = 300;
        yspeed = 0;
    }
end

function love.update(dt)
    if love.keyboard.isDown("r") and gameStates.isOver then
        
        love.load()

    elseif gameStates.isOver then return end

    
    -- // Player Logic

    if love.keyboard.isDown("e") and player.y < 450 then
        player.move(player.speed, dt)
    end
    if love.keyboard.isDown("q") and player.y > 0 then 
        player.move(-player.speed, dt)
    end


    -- // Ball Logic

    if (ball.x >= love.graphics.getWidth() - ball.size) then
        ball.xspeed = -ball.xspeed
        ball.yspeed = math.random(-300, 300)
    end
    if (ball.x <= 0) then
        print("Game Over!")
        gameStates.isOver = true
    end

    if (ball.y >= love.graphics.getHeight() - ball.size) then
        ball.yspeed = -ball.yspeed
    end
    if (ball.y <= 0) then
        ball.yspeed = math.abs(ball.yspeed)
    end

    if ((ball.y >= player.y and ball.y <= player.y + player.ysize) and ball.x <= player.x + player.xsize) then
        gameStates.score = gameStates.score + 1

        ball.xspeed = ball.xspeed - 30
        
        ball.x = player.x + player.xsize + 1

        ball.xspeed = math.abs(ball.xspeed)
        ball.yspeed = math.random(-300, 300)
    end

    ball.x = ball.x + ball.xspeed * dt
    ball.y = ball.y + ball.yspeed * dt

    print(ball.xspeed, ball.yspeed, gameStates.score)
end

function love.draw()
    love.graphics.setColor(255,0,255)

    if gameStates.isOver then
        love.graphics.print("Game Over!\nScore is " .. gameStates.score .. "\nPress R to Restart", 210, 240)
    end

    love.graphics.rectangle("fill", player.x, player.y, player.xsize, player.ysize)
    love.graphics.rectangle("fill", ball.x, ball.y, ball.size, ball.size)
end
