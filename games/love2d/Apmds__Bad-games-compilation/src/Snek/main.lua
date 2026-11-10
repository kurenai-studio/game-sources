function love.load()
    love.window.setTitle("Snek")
    math.randomseed(os.time())
    set_start_conditions()
end

function love.update(dt)
    fps = 1/dt
    if not game_paused and not game_ended then
        -- Update timer
        timer = timer - dt
        -- Move snake when time is up
        if timer <= 0 then
            -- Move the snake's body
            for i=#snake, 1 , -1 do
                if i ~= 1 then
                    snake[i][1] = snake[i-1][1]
                    snake[i][2] = snake[i-1][2]
                end
            end
            -- Move the head according to the direction
            if direction == 1 then
                snake[1][2] = snake[1][2] - 1
            elseif direction == 2 then
                snake[1][2] = snake[1][2] + 1
            elseif direction == 3  then
                snake[1][1] = snake[1][1] - 1
            elseif direction == 4 then
                snake[1][1] = snake[1][1] + 1
            end

            -- Check if head is touching the body
            for i, piece in pairs(snake) do
                if i ~= 1 and piece[1] == snake[1][1] and piece[2] == snake[1][2] then
                    game_ended = true
                end
            end
            
            -- Check if head is past the world's boundaries
            if snake[1][1] < 0 or snake[1][1] > 39 or snake[1][2] < 0 or snake[1][2] > 29 then
                game_ended = true
            end

            -- Check if apple is eaten by head
            if snake[1][1] == apple[1] and snake[1][2] == apple[2] then
                snake[#snake+1] = {snake[#snake][1], snake[#snake][2]}
                respawn_apple()
                score = score + 1
            end
            timer = move_time
        end
    end
end

function love.draw()
    love.graphics.setColor(207/255, 37/255, 37/255)
    love.graphics.rectangle("fill", apple[1]*20, apple[2]*20, 20, 20)
    for i, piece in pairs(snake) do
        if i == 1 then
            love.graphics.setColor(1, 0, 0)
        elseif i%2 == 0 then
            love.graphics.setColor(20/255, 94/255, 5/255)
        else
            love.graphics.setColor(35/255, 168/255, 8/255)
        end
        love.graphics.rectangle("fill", piece[1]*20, piece[2]*20, 20, 20)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 400, 50)
    
    if game_ended then
        love.graphics.print("GG", 400, 400)
    end

    if game_paused then
        love.graphics.print("PAUSED", 400, 300)
    end

    if debug_mode then
        love.graphics.print("FPS: " .. fps, 0, 0)
        love.graphics.print("Head: X- " .. snake[1][1] .. "; Y- " .. snake[1][2], 0, 30)
    end
end

function love.keypressed(key)
    if not game_ended then
        if not game_paused then
            if (key == "w" or key == "up") and snake[1][2]-1 ~= snake[2][2] then
                direction = 1
            elseif (key == "s"  or key == "down") and snake[1][2]+1 ~= snake[2][2] then
                direction = 2
            elseif (key == "a" or key == "left") and snake[1][1]-1 ~= snake[2][1] then
                direction = 3
            elseif (key == "d" or key == "right") and snake[1][1]+1 ~= snake[2][1] then
                direction = 4
            end
        end
        if key == "p" then
            game_paused = not game_paused
        end
    end
    if key == "k" then
        debug_mode = not debug_mode
    end
    if key == "r" then
        set_start_conditions()
    end
end

-- Used to reset the game
function set_start_conditions()
    fps = 0
    game_paused = false
    game_ended = false
    snake = {}
    score = 0
    apple = {math.random(0, 39), math.random(0, 29)}
    move_time = 0.1
    timer = move_time
    direction = 4 -- 1 for up, 2 for down, 3 for left, 4 for right
    for i=1, 2 do
        snake[#snake+1] = {19, 14}
    end
end

-- Function to respawn_apple without it being inside the snake's body
function respawn_apple()
    for i, piece in pairs(snake) do
        apple = {math.random(0, 39), math.random(0, 29)}
        if apple[1] == piece[1] and apple[2] == piece[2] then
            respawn_apple()
        end
    end
end
