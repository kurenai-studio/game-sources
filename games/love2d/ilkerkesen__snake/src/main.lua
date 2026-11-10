function love.load()
    -- config
    TILE_SIZE = 12
    TILE_PAD = 1
    NUM_X_TILES = 48
    NUM_Y_TILES = 32
    TICK = 0.05
    TICK_MIN = 0.005
    TICK_ACC = 0.99
    DIRECTION_BUFFER_SIZE = 5
    SNAKE_INIT_SIZE = 4
    WINDOW_WIDTH = TILE_SIZE * NUM_X_TILES
    WINDOW_HEIGHT = TILE_SIZE * (1+NUM_Y_TILES)

    Object = require "lib/classic"
    require "src/utils"
    require "src/snake"
    require "src/food"
   
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    reset_game()
end

function love.update(dt)
    if game_state ~= "continue" then
        return nil
    end

    clock = clock + dt
    if clock > tick then
        if #direction_buffer ~= 0 then
            snake.direction = table.remove(direction_buffer, 1)
        end
        snake:move()
        clock = 0
    end
end

function love.keypressed(key)
    local direction
    local next_direction
    
    if key == "escape" then
        love.event.quit()
    elseif key == "r" then
        reset_game()
    elseif key == "space" and game_state == "continue" then
        game_state = "pause"
    elseif key == "space" and game_state == "pause" then
        game_state = "continue"
    end

    if #direction_buffer == DIRECTION_BUFFER_SIZE then
        return
    end

    if #direction_buffer == 0 then
        next_direction = snake.direction
    else
        next_direction = direction_buffer[#direction_buffer]
    end
    
    if key == "right" and next_direction ~= "left" then
        direction = "right"
    elseif key == "left" and next_direction ~= "right" then
        direction = "left"
    elseif key == "up" and next_direction ~= "down" then
        direction = "up"
    elseif key == "down" and next_direction ~= "up" then
        direction = "down"
    end
    
    table.insert(direction_buffer, direction)
end

function love.draw()
    snake:draw()
    food:draw()
    draw_status()
end

function reset_game()
    grid = init_grid()
    snake = Snake()
    food = Food()
    score = 0
    clock = 0
    direction_buffer = {}
    game_state = "continue"
    tick = TICK
end

function draw_status()
    love.graphics.setColor(1, 0, 1)
    love.graphics.rectangle("fill", 0, WINDOW_HEIGHT-TILE_SIZE, WINDOW_WIDTH, TILE_SIZE)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Score: " .. score, 0, WINDOW_HEIGHT-TILE_SIZE-1)
    if game_state == "pause" then
        love.graphics.print("PAUSED", (WINDOW_WIDTH / 2) - 5*TILE_SIZE, WINDOW_HEIGHT-TILE_SIZE-1)
    elseif game_state == "game_over" then
        love.graphics.print("GAME OVER!", (WINDOW_WIDTH / 2) - 5*TILE_SIZE, WINDOW_HEIGHT-TILE_SIZE-1)
    end
end