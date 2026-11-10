function love.load()
    SCREEN_WIDTH = love.graphics.getWidth()
    SCREEN_HEIGHT = love.graphics.getHeight()
    love.window.setTitle("\"Breakout\"")
    reset_game()
end

function love.update(dt)
    if not game_ended and not game_paused then
        if #blocks == 0 then
            game_ended = true
        end
        -- Player movement
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            player.x = player.x + player.speed
        elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            player.x = player.x - player.speed
        end

        -- Player out of bounds "barriers"
        if player.x < 0 then
            player.x = 0
        elseif player.x > SCREEN_WIDTH-player.width then
            player.x = SCREEN_WIDTH-player.width
        end

        -- Ball movement
        ball:angle_to_speed()
        ball.x = ball.x + ball.speed_x
        ball.y = ball.y + ball.speed_y
        
        -- Wall collision
        if ball.x <= 0 or ball.x >= SCREEN_WIDTH-ball.width then
            ball.angle = ball.angle * -1
            ball.angle = ball.angle + 180
        end
        if ball.y <= 0 then
            ball.angle = ball.angle * -1
        end
        if ball.y + ball.height > SCREEN_HEIGHT then
            if player.lives <= 0 then
                game_ended = true
            else
                player.lives = player.lives - 1
                new_life()
            end
        end

        -- Turn angle to a value between 0 and 360
        ball.angle = math.abs(ball.angle%360)
        -- Player collision with ball
        if is_colliding(player, ball) then
            if ball.angle <= 360 and ball.angle >= 270 then
                if ball.x < player.x + player.width/2 then
                    ball.angle = ball.angle * -1
                    ball.angle = ball.angle + 180
                else
                    ball.angle = ball.angle * -1
                end
            elseif ball.angle < 270 and ball.angle >= 180 then
                if ball.x < player.x + player.width/2 then
                    ball.angle = ball.angle * -1
                else
                    ball.angle = ball.angle * -1
                    ball.angle = ball.angle + 180
                end
            end
        end
        
        -- Ball collision with blocks
        for i, block in pairs(blocks) do
            if is_colliding(block, ball) then
                if ball.x > block.x then
                    ball.angle = ball.angle * -1
                else
                    ball.angle = ball.angle * -1
                    ball.angle = ball.angle + 180
                end
                table.remove(blocks, i)
            end
        end
    end
end

function love.draw()
    -- Blocks drawing
    love.graphics.setColor(1, 0, 0)
    for i, block in pairs(blocks) do
        love.graphics.rectangle("fill", block.x, block.y, block.width, block.height)
    end
    
    -- Player and ball drawing
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", ball.x+ball.radius, ball.y+ball.radius, ball.radius)
    
    love.graphics.setColor(0, 0, 1)
    love.graphics.printf("Lives: " .. player.lives, SCREEN_WIDTH/4, 30, SCREEN_WIDTH/2, "center")

    -- "Menus"
    if game_paused then
        love.graphics.printf("PAUSED", SCREEN_WIDTH/4, SCREEN_HEIGHT/2 + 50, SCREEN_WIDTH/2, "center")
    end
    if game_ended then
        love.graphics.printf("GG", SCREEN_WIDTH/4, SCREEN_HEIGHT/2, SCREEN_WIDTH/2, "center")
    end
    love.graphics.setColor(1, 1, 1)
    if debug_menu then
        love.graphics.print("Player: X: " .. player.x .. "; Lives: " .. player.lives, 0, 0)
        love.graphics.print("Ball: X: " .. math.floor(ball.x) .. "; Y: " .. math.floor(ball.y) .. "; Angle: " .. ball.angle, 0, 30)
    end
end

function love.keypressed(key)
    if key == "p" then
        game_paused = not game_paused
    end
    if key == "k" then
        debug_menu = not debug_menu
    end
    if key == "r" then
        reset_game()
    end
end

-- Returns true if obj1 is colliding with obj2
function is_colliding(obj1, obj2)
    return obj1.x+obj1.width > obj2.x and obj1.y+obj1.height > obj2.y and obj2.x+obj2.width > obj1.x and obj2.y+obj2.height > obj1.y
end

-- Unused: Returns the collision point of two objects, if they are colliding
function get_collision_point(obj1, obj2)
    if not is_colliding(obj1, obj2) then
        return nil
    else

    end
end

-- Returns true if the point (x, y) is colliding with obj
function colliding_with_point(obj, x, y)
    return (obj.x+obj.width > x and obj.x < x) and (obj.y+obj.height > y and obj.y < y)
end

-- Resets(or sets for the first time) the game's status
function reset_game()
    game_paused = false
    game_ended = false
    debug_menu = false
    ball = {
        x = 0,
        y = 350,
        angle = -20,
        speed = 10,
        speed_x = 10,
        speed_y = 6,
        radius = 15,
        width = 30,
        height = 30,
        angle_to_speed = function (self)
            self.speed_x = math.cos(math.rad(self.angle))*self.speed
            self.speed_y = -math.sin(math.rad(self.angle))*self.speed
        end,
    }
    player = {
        x = SCREEN_WIDTH/2-75,
        y = 500,
        speed = 15,
        width = 150,
        height = 15,
        lives = 3,
    }
    local BLOCKS_SIZE = {w = 11, h = 8}
    blocks = {}
    for i=1, BLOCKS_SIZE.h do
        for j=1, BLOCKS_SIZE.w do
            blocks[#blocks+1] = {
                x = j*66-20,
                y = 30+i*23,
                width = 60,
                height = 20,
            }
        end
    end
end

-- Resets the ball
function new_life()
    ball = {
        x = 0,
        y = 350,
        angle = -20,
        speed = 10,
        speed_x = 10,
        speed_y = 6,
        radius = 15,
        width = 30,
        height = 30,
        angle_to_speed = function (self)
            self.speed_x = math.cos(math.rad(self.angle))*self.speed
            self.speed_y = -math.sin(math.rad(self.angle))*self.speed
        end,
    }
end