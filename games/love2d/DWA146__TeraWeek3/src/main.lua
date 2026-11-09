print("Hello, World!")

function love.load()

    state = "menu"
    mode = "pvp"
    menuChoice = 1
    botSpeed = 300

    love.window.setTitle("P-NG")
    W , H = 800, 600

    paddleW, paddleH, paddleSpeed = 15, 100, 400

    p1 = { x = 20, y = H/2 - paddleH/2, health = 100, armed = false, hits = 0}
    p2 = { x = W - 20 - paddleW, y = H/2 - paddleH/2, health = 100, armed = false, hits = 0 }


    hitsNeeded = 5
    superMult = 3
    maxSpeed=  1200
    trail = {}
    trailTimer = 0 
    maxHealth = 100
    dmg = 20
    gameOver = false
    winner = ""

    resetBall()
end

function resetBall()
    ball = {
        x = W/2,
        y = H/2,
        size = 12,
        super = false,
        dx = (love.math.random() <  0.5 and -1 or 1) * 300,
        dy = love.math.random(-150, 150)

    }

end

function love.keypressed(key)
    if state == "menu" then
        if key == "up" or key == "down" then
            menuChoice = (menuChoice == 1) and 2 or 1
        elseif key == "return" then
            mode = (menuChoice == 1) and "pvp" or "bot"
            state = "playing"
        end
        return
    end
    if key == "escape" then
        state = "menu"
        p1.health = maxHealth
        p2.health = maxHealth
        gameOver = false
        winner = ""
        resetBall()
        return
    end

    if key == "d" and p1.hits >= hitsNeeded then -- super shot | you gotta have 5+ bounces already to use then press d on ur keyboard
        p1.armed = true
    end

    if key == "left" and mode == "pvp" and p2.hits >= hitsNeeded then 
        p2.armed = true 
    end



    if key == "r" and gameOver then
        p1.hits, p2.hits = 0, 0
        p1.armed, p2.armed = false, false
        p1.health = maxHealth
        p2.health = maxHealth
        gameOver = false
        winner = ""
        resetBall()
    end
end

function love.update(dt)
    -- game overness
    if state == "menu" or gameOver then return end

    --player 1
    if love.keyboard.isDown("w") then
        p1.y = p1.y  - paddleSpeed * dt
    end

    if love.keyboard.isDown("s") then
        p1.y = p1.y + paddleSpeed * dt
    end

    -- player 2
    if mode == "pvp" then
        
        if love.keyboard.isDown("up") then
            p2.y = p2.y - paddleSpeed * dt
        end

        if love.keyboard.isDown("down") then
            p2.y = p2.y + paddleSpeed * dt
        end
    else
        -- bot
        local target = ball.y + ball.size/2 - paddleH/2
        if p2.hits >= hitsNeeded then
            p2.armed = true
        end

        if p2.y < target - 10 then
            p2.y = p2.y + botSpeed * dt
        elseif  p2.y > target + 10 then
            p2.y = p2.y - botSpeed * dt
        end
    end

    -- keeping the players on screen
    p1.y = math.max(0, math.min(H - paddleH, p1.y))
    p2.y = math.max(0, math.min(H - paddleH, p2.y))
   
    -- ball movements
    ball.x = ball.x + ball.dx * dt
    ball.y = ball.y + ball.dy * dt
    
    -- affter images trails
    trailTimer = trailTimer + dt
    if trailTimer > 0.02 then
        trailTimer = 0
        table.insert(trail, {x = ball.x, y = ball.y, life = 1})
    end

    for i = #trail, 1, -1 do 
        trail[i].life = trail[i].life - dt * 2
        if trail[i].life <= 0 then
            table.remove(trail, i)
    
        end
    end


    -- richocheting balls
    if ball.y < 0 then
        ball.y = 0
        ball.dy = -ball.dy
    end

    if ball.y + ball.size > H then
        ball.y = H - ball.size
        ball.dy = -ball.dy
    end
    -- player collisons
    if hits(p1) and ball.dx < 0 then
        bounce(p1)
    end
    
    if hits(p2) and ball.dx > 0 then
        bounce(p2)
    end

    -- health
    if ball.x < 0 then
        p1.health = p1.health - dmg
        resetBall()
    
    end

    if ball.x > W then
        p2.health = p2.health - dmg
        resetBall()

    end

    -- game overness checker
    if p1.health <= 0 then 
        gameOver = true
        winner = "player 2"
    elseif p2.health <= 0 then
        gameOver = true
        winner = "player 1"
    end

end

function hits(p)
    return ball.x < p.x + paddleW and ball.x + ball.size > p.x
    and ball.y < p.y + paddleH and ball.y + ball.size > p.y
end

function bounce(p)
    ball.dx = -ball.dx * 1.05
    local hitPos = (ball.y + ball.size/2) - (p.y + paddleH/2)
    ball.dy = hitPos * 5

    if p.armed then
        ball.dx = ball.dx * superMult
        ball.dy = ball.dy * superMult
        ball.super = true
        p.armed = false
        p.hits = 0
    else
        ball.super = false
        p.hits = math.min(hitsNeeded, p.hits + 1)
    end

    -- speed cap
    ball.dx = math.max(-maxSpeed, math.min(maxSpeed, ball.dx))
    ball.dy = math.max(-maxSpeed, math.min(maxSpeed, ball.dy))

end


local function barcolor(h)
    if h > 60 then
        return 0, 0.8, 0
    elseif h >  30 then
        return 0.9, 0.8, 0
    else
        return 0.9, 0.1, 0.1
    end

end

function love.draw()
    if state == "menu" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("P-NG", 0, 120, W, "center", 0, 1, 1)

        local options = {"vs player", "vs bot"}
        for i,text in ipairs(options) do
            if i == menuChoice then
                love.graphics.setColor(1, 0.8, 0)
                text = "> ".. text .. " <"
            else
                love.graphics.setColor(1, 1, 1)
            end
            love.graphics.printf(text, 0 ,250 + i * 50, W, "center")
        end
        
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("Up/Down to choose, Enter to start", 0, H - 60, W, "center")
        love.graphics.setColor(1, 1, 1)
        return
    end


    -- paddies
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", p1.x, p1.y, paddleW, paddleH)
    love.graphics.rectangle("fill", p2.x, p2.y, paddleW, paddleH)
    -- steel ballll ruuuuuuuuuuuuun 
    for _, t in ipairs(trail)do
        if ball.super then
            love.graphics.setColor(1, 0.4, 0.1, t.life * 0.7)
        else
            love.graphics.setColor(1, 1, 1, t.life * 0.3)
        end
        local s = ball.size * t.life
        local off = (ball.size - s) / 2
        love.graphics.rectangle("fill", t.x + off, t.y + off, s, s)
    end

    -- suuuupeerrrr ball
    if ball.super then
        love.graphics.setColor(0.5, 0.5, 1)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.rectangle("fill", ball.x, ball.y, ball.size, ball.size)

    -- hit counters
    for i = 1, hitsNeeded do
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 20 + (i-1) * 20, 52, 16, 8)
        love.graphics.rectangle("fill", W - 36 - (i-1) * 20, 52, 16, 8)
        love.graphics.setColor(0.2, 0.6, 1)
        if p1.hits >= i then
            love.graphics.rectangle("fill", 20 + (i-1) * 20, 52, 16, 8)
        end
        if p2.hits >= i then
            love.graphics.rectangle("fill", W - 36 - (i - 1) * 20, 52, 16, 8)
        end
    end

    -- superrr readdyy hint
    love.graphics.setColor(0.2,0.1,0.5)
    if p1.armed then
        love.graphics.rectangle("fill", p1.x - 2, p1.y - 2, paddleW + 4, paddleH + 4)
    end
    if p2.armed then
        love.graphics.rectangle("fill", p2.x - 2, p2.y - 2, paddleW + 4, paddleH + 4)
    end
    love.graphics.setColor(1, 1, 1)
    -- health barrr
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 20, 20, 300, 25)
    love.graphics.rectangle("fill", W - 320, 20, 300, 25)

    -- coloring health bit
    love.graphics.setColor(barcolor(p1.health))
    love.graphics.rectangle("fill", 20, 20, 300 * (p1.health/maxHealth), 25)
    local p2width = 300 * (p2.health/maxHealth)
    love.graphics.setColor(barcolor(p2.health))
    love.graphics.rectangle("fill", W - 20 - p2width, 20, p2width, 25)
    
    --game over screen
    if gameOver then
        love.graphics.setColor(0.9, 0.1, 0.1)
        love.graphics.printf(winner .. " wins!\nPress R to restart", 0, H/2 - 40,W, "center", 0 ,1 ,1 )
    end


end