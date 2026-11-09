--
-- Created by IntelliJ IDEA.
-- User: lucas
-- Date: 6/15/15
-- Time: 12:11 AM
-- To change this template use File | Settings | File Templates.
--

snake = {}
food = {}

SQUARE_SIZE = 15

function love.load()
    love.window.setMode(800, 600, {vsync=true})
    love.window.setTitle("Snake")

    snake.size = 1;
    snake[1] = {}
    snake[1].x = 1
    snake[1].y = 2
    snake[1].dir_x = 1
    snake[1].dir_y = 0

    food.x = love.math.random((love.window.getWidth() / SQUARE_SIZE) - 2) + 1
    food.y = love.math.random((love.window.getHeight() / SQUARE_SIZE) - 2) + 1
end

last_move_timer = 0;
game_over = false;
show_fps = false;

function love.update()
    local delta = love.timer.getDelta()

    last_move_timer = last_move_timer + delta
    if (last_move_timer > 0.1) then
        last_move_timer = 0

        --update snake position
        for i=1,snake.size do
            snake[i].x = snake[i].x + snake[i].dir_x
            snake[i].y = snake[i].y + snake[i].dir_y
        end

        --out of border test
        if (snake[1].x < 1 or
                snake[1].x > ((love.window.getWidth() / SQUARE_SIZE) -1) or
                snake[1].y < 1 or
                snake[1].y > ((love.window.getHeight() / SQUARE_SIZE) - 1)) then
            game_over = true
        end

        --update direction of child snake parts
        if (snake.size >= 2) then
            local i = snake.size
            while (i > 1) do
                snake[i].dir_x = snake[i-1].dir_x
                snake[i].dir_y = snake[i-1].dir_y

                i = i - 1;
            end
        end

        --colision test
        for i=1,snake.size do
            for j=1,snake.size do
                if (snake[i].x == snake[j].x and snake[i].y == snake[j].y and i ~= j) then
                    game_over = true;
                end
            end
        end
    end

    if (snake[1].x == food.x and snake[1].y == food.y) then
        food.x = love.math.random((love.window.getWidth() / SQUARE_SIZE) - 2) + 1
        food.y = love.math.random((love.window.getHeight() / SQUARE_SIZE) - 2) + 1

        snake.size = snake.size + 1;
        snake[snake.size] = {}
        snake[snake.size].x = snake[snake.size - 1].x
        snake[snake.size].y = snake[snake.size - 1].y
        snake[snake.size].dir_x = 0
        snake[snake.size].dir_y = 0
    end

    if (love.keyboard.isDown('d') and snake[1].dir_x ~= -1) then
        snake[1].dir_y = 0
        snake[1].dir_x = 1
    end

    if (love.keyboard.isDown('a') and snake[1].dir_x ~= 1) then
        snake[1].dir_y = 0
        snake[1].dir_x = -1
    end

    if (love.keyboard.isDown('w') and snake[1].dir_y ~= 1) then
        snake[1].dir_y = -1
        snake[1].dir_x = 0
    end

    if (love.keyboard.isDown('s') and snake[1].dir_y ~= -1) then
        snake[1].dir_y = 1
        snake[1].dir_x = 0
    end

    if (love.keyboard.isDown('f') and show_fps == false) then
        show_fps = true
    end

    if (love.keyboard.isDown('r') and game_over == true) then
        love.load()
        game_over = false
    end
end

function love.draw()
    if (game_over == true) then
        local game_over_msg = "GAME OVER!"
        love.graphics.print(game_over_msg, (love.window.getWidth() - string.len(game_over_msg))/2, love.window.getHeight()/2 - 20)

        local game_score_msg = "Score: " .. tostring(snake.size - 1)
        love.graphics.print(game_score_msg, (love.window.getWidth() - string.len(game_score_msg))/2, love.window.getHeight()/2 + 20)

        return
    end

    if (show_fps == true) then
        local fps = love.timer.getFPS()
        love.graphics.setColor(255, 255, 255)
        love.graphics.print(fps, love.window.getWidth() - 30, 0)
    end

    love.graphics.setColor(0, 255, 0)
    love.graphics.circle("fill", food.x * SQUARE_SIZE, food.y * SQUARE_SIZE, 5, 20)

    love.graphics.setColor(255, 0, 0)
    for i=1,snake.size do
        love.graphics.circle("fill", snake[i].x * SQUARE_SIZE, snake[i].y * SQUARE_SIZE, 5, 20)
    end

    -- draw limits
    love.graphics.setColor(255, 255, 255)
    love.graphics.line(0,
        SQUARE_SIZE/2,
        love.window.getWidth(),
        SQUARE_SIZE/2)
    love.graphics.line(0,
        SQUARE_SIZE * (love.window.getHeight()/SQUARE_SIZE - 1) + SQUARE_SIZE/2,
        love.window.getWidth(),
        SQUARE_SIZE * (love.window.getHeight()/SQUARE_SIZE - 1) + SQUARE_SIZE/2)
    love.graphics.line(SQUARE_SIZE/2,
        0,
        SQUARE_SIZE/2,
        love.window.getHeight())
    love.graphics.line(SQUARE_SIZE * (love.window.getWidth()/SQUARE_SIZE - 1) + SQUARE_SIZE/2,
        0,
        SQUARE_SIZE * (love.window.getWidth()/SQUARE_SIZE - 1) + SQUARE_SIZE/2,
        love.window.getHeight())
end