require("asteroids")
require("bonus_boxes")
require("move")
require("collision")

function love.conf(t)
    t.console = true
end


function love.load()
    love.window.setMode(300,600, {vsync=0})
    love.window.setFullscreen(true)

    font = love.graphics.newFont("font.ttf",8)
    font:setFilter("nearest", "nearest")

    love.graphics.setFont(font)

    player = {
        x=150,y=500,
        width=30,height=30,
        speed=200,
    }
    player.x = player.x - player.width/2

    dead = false

    asteroids = {
        spawn_timer = 0,
        spawn_time = .5,
        number_spawned = 0,
        speed_up = 15,
        inst = {}
    }

    bonus_boxes = {
        spawn_timer = 0,
        spawn_time = 4,
        inst = {}
    }

    score = 0
    time_elapsed = 0
end


function love.update(dt)
    time_elapsed = time_elapsed + dt

    if time_elapsed > 20 then
        asteroids.spawn_time = .3
    end

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end
    if love.keyboard.isDown("lshift") then
		player.speed = 400
    else
		player.speed = 200
    end
    if not dead then
        -- Player movement
        if love.keyboard.isDown("right") then
            move_direction(player, "right", dt)
        elseif love.keyboard.isDown("left") then
            move_direction(player, "left", dt)
        end
        if love.keyboard.isDown("up") then
            move_direction(player, "up", dt)
        elseif love.keyboard.isDown("down") then
            move_direction(player, "down", dt)
        end

        -- Make sure the player is in the screen
        if player.x < 0 then
            player.x = 0
        elseif player.x > love.graphics.getWidth()-player.width then
            player.x = love.graphics.getWidth()-player.width
        end

        if player.y < 0 then
            player.y = 0
        elseif player.y > love.graphics.getHeight()-player.height then
            player.y = love.graphics.getHeight()-player.height
        end

        -- Asteroids movement
        move_projectiles(asteroids.inst, dt)
        move_projectiles(bonus_boxes.inst, dt)


        -- Spawn new asteroids
        asteroids.spawn_timer = asteroids.spawn_timer + dt
        
        if asteroids.spawn_timer > asteroids.spawn_time then
            asteroids.spawn_timer = 0
            asteroids.inst[#asteroids.inst+1] = new_asteroid()
            asteroids.number_spawned = asteroids.number_spawned + 1
        end

        -- Spawn new bonus boxes
        bonus_boxes.spawn_timer = bonus_boxes.spawn_timer + dt
        
        if bonus_boxes.spawn_timer > asteroids.spawn_time then
            bonus_boxes.spawn_timer = 0
            bonus_boxes.inst[#bonus_boxes.inst+1] = new_bonus_box()
        end

        -- Is the player dead yet?
        for i,asteroid in pairs(asteroids.inst) do
            if colliding(asteroid.x,asteroid.y,asteroid.width,asteroid.height, player.x+5,player.y+5,player.width-5,player.height-5) then
                dead = true
            end
        end

        -- Did the player get a bonus box?
        local new_bonus_boxes = {}
        for i,bonus_box in pairs(bonus_boxes.inst) do
            if colliding(bonus_box.x,bonus_box.y,bonus_box.width,bonus_box.height, player.x+5,player.y+5,player.width-5,player.height-5) then
                score = score + 5
            else
                new_bonus_boxes[#new_bonus_boxes+1] = bonus_box
            end
        end
        bonus_boxes.inst = new_bonus_boxes
    end
end


function love.draw()
    if not dead then
        -- Draw player
        love.graphics.setColor(255,255,255)
    else
		love.graphics.setColor(255,0,0)
    end

	love.graphics.rectangle("fill",player.x,player.y,player.width,player.height)
	
    -- Draw asteroids
    love.graphics.setColor(255,0,0)

    for i,asteroid in pairs(asteroids.inst) do
        love.graphics.rectangle("fill",asteroid.x,asteroid.y,asteroid.width,asteroid.height)
    end

    -- Draw bonus boxes
    love.graphics.setColor(0,255,0)

    for i,bonus_box in pairs(bonus_boxes.inst) do
        love.graphics.rectangle("fill",bonus_box.x,bonus_box.y,bonus_box.width,bonus_box.height)
    end

    love.graphics.setColor(255,255,255)
    -- Draw score

	if not dead then
    	love.graphics.print(score,1,1,0,4,4)
	else
        love.graphics.setColor(0,0,0)
        love.graphics.rectangle("fill",0,love.graphics.getHeight()/2-74,love.graphics.getWidth(),64*2-4)
		love.graphics.setColor(255,255,255)
        love.graphics.printf("Score: "..score, 0,love.graphics.getHeight()/2-68,love.graphics.getWidth()/4,"center",0,4,4)
        love.graphics.printf("Better luck next time...", 0,love.graphics.getHeight()/2+4,love.graphics.getWidth()/4,"center",0,4,4)
	end    
end
