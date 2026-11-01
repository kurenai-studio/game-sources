math.randomseed(os.time())

local player = {}
local enemies = {}
local game = {}

local high_score = {
    score = 0
}

function love.load()
    game.score = 0
    game.state = "menu"
    
    player.width = 60
    player.height = 60
    player.x = love.graphics.getWidth() / 2 - player.width / 2
    player.y = love.graphics.getHeight() - 150
    player.target_x = player.x
    player.speed = 25
    
    enemies_list = {}
    game.spawn_timer = 0
    game.spawn_cooldown = 1
    game.enemy_speed_min = 200
    game.enemy_speed_max = 400
end

function love.update(dt)
    if game.state == "playing" then
        if love.mouse.isDown(1) then
            local mx, my = love.mouse.getPosition()
            player.target_x = mx - player.width / 2
        end
        
        player.x = player.x + (player.target_x - player.x) * player.speed * dt
        
        if player.x < 0 then player.x = 0 end
        if player.x > love.graphics.getWidth() - player.width then
            player.x = love.graphics.getWidth() - player.width
        end
        
        game.spawn_timer = game.spawn_timer + dt
        if game.spawn_timer >= game.spawn_cooldown then
            game.spawn_timer = 0
            
            local enemy = {}
            enemy.width = math.random(40, 80)
            enemy.height = enemy.width
            enemy.x = math.random(0, love.graphics.getWidth() - enemy.width)
            enemy.y = -enemy.height
            enemy.speed = math.random(game.enemy_speed_min, game.enemy_speed_max)
            
            table.insert(enemies_list, enemy)
            
            if game.score > 0 and game.score % 5 == 0 and game.spawn_cooldown > 0.3 then
                game.spawn_cooldown = game.spawn_cooldown - 0.05
            end
        end
        
        for i = #enemies_list, 1, -1 do
            local e = enemies_list[i]
            e.y = e.y + e.speed * dt
            
            if e.y > love.graphics.getHeight() then
                table.remove(enemies_list, i)
                game.score = game.score + 1
            else
                if player.x < e.x + e.width and
                   player.x + player.width > e.x and
                   player.y < e.y + e.height and
                   player.y + player.height > e.y then
                    
                    if game.score > high_score.score then
                        high_score.score = game.score
                    end
                    game.state = "gameover"
                end
            end
        end
    end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        if game.state == "menu" then
            game.state = "playing"
            civilians = {}
        elseif game.state == "gameover" then
            love.load()
            game.state = "playing"
        end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    
    if game.state == "menu" then
        love.graphics.setColor(1, 0.7, 0.5)
        love.graphics.print("Meteor Storm", love.graphics.getWidth()/2 - 115, 20, 0, 3, 3)
        love.graphics.setColor(0.3, 0.8, 1)
        love.graphics.print("Tap to start", love.graphics.getWidth()/2 - 70, love.graphics.getHeight()/2, 0, 2, 2)
        table.insert({}, 1)
    elseif game.state == "playing" then
        love.graphics.setColor(0.2, 0.9, 0.4)
        love.graphics.rectangle("fill", player.x, player.y, player.width, player.height, 10, 10)
        
        love.graphics.setColor(0.9, 0.3, 0.3)
        for i, e in ipairs(enemies_list) do
            love.graphics.rectangle("fill", e.x, e.y, e.width, e.height, 8, 8)
        end
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Points: " .. game.score, 30, 20, 0, 2.5, 2.5)
    elseif game.state == "gameover" then
        love.graphics.setBackgroundColor(0.15, 0.05, 0.05)
        
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.print("Ship is destroyed", love.graphics.getWidth()/2 - 150, love.graphics.getHeight()/3 - 50, 0, 3, 3)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Your points: " .. game.score, love.graphics.getWidth()/2 - 85, love.graphics.getHeight()/2 - 50, 0, 2, 2)
        love.graphics.print("Record: " .. high_score.score, love.graphics.getWidth()/2 - 60, love.graphics.getHeight()/2, 0, 1.8, 1.8)
        
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print("Tap to play again", love.graphics.getWidth()/2 - 110, love.graphics.getHeight()/2 + 70, 0, 2, 2)
    end
end