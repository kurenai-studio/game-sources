-- main.lua
-- Space Shooter RPG Game using shapes in LÖVE2D

-- Game states
local gameState = "start" -- start, play, gameover, levelup
local player = nil
local enemies = {}
local bullets = {}
local stars = {}
local powerups = {}

-- Player stats (RPG elements)
local playerStats = {
    level = 1,
    exp = 0,
    expToLevel = 100,
    health = 100,
    maxHealth = 100,
    damage = 10,
    fireRate = 0.3,
    speed = 200,
    shield = 0
}

-- Colors
local COLORS = {
    background = {0.05, 0.05, 0.1, 1},
    player = {0, 0.8, 0.9, 1},
    enemy = {0.9, 0.2, 0.3, 1},
    bullet = {1, 0.9, 0.2, 1},
    text = {1, 1, 1, 1},
    health = {0.2, 0.8, 0.2, 1},
    exp = {0.6, 0.2, 0.9, 1},
    shield = {0.3, 0.4, 0.9, 0.6}
}

-- Enemy types with different behaviors and stats
local ENEMY_TYPES = {
    {
        name = "Scout",
        health = 20,
        damage = 5,
        speed = 100,
        expValue = 10,
        color = {0.9, 0.2, 0.3, 1},
        size = 15,
        shootRate = 1.5
    },
    {
        name = "Destroyer",
        health = 40,
        damage = 10,
        speed = 70,
        expValue = 25,
        color = {0.8, 0.1, 0.3, 1},
        size = 25,
        shootRate = 2
    },
    {
        name = "Battleship",
        health = 100,
        damage = 20,
        speed = 50,
        expValue = 50,
        color = {0.7, 0.1, 0.2, 1},
        size = 35,
        shootRate = 3
    }
}

-- Powerup types
local POWERUP_TYPES = {
    {
        name = "Health",
        effect = function() player.health = math.min(player.health + 20, playerStats.maxHealth) end,
        color = {0.2, 0.8, 0.2, 1},
        duration = 0
    },
    {
        name = "Shield",
        effect = function() playerStats.shield = playerStats.shield + 30 end,
        color = {0.3, 0.4, 0.9, 1},
        duration = 0
    },
    {
        name = "FireRate",
        effect = function() playerStats.fireRate = playerStats.fireRate * 0.7 end,
        color = {0.9, 0.6, 0.1, 1},
        duration = 5
    }
}

-- Timers
local shootTimer = 0
local enemySpawnTimer = 0
local powerupSpawnTimer = 0
local enemyShootTimers = {}

-- Load game resources and initialize
function love.load()
    -- Set random seed based on time
    math.randomseed(os.time())
    
    -- Set window properties
    love.window.setTitle("Space Shooter RPG")
    love.window.setMode(800, 600, {vsync = true})
    
    -- Initialize player
    resetPlayer()
    
    -- Create background stars
    createStars(100)
end

-- Reset player to initial state
function resetPlayer()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    player = {
        x = windowWidth / 2,
        y = windowHeight - 50,
        width = 20,
        height = 30,
        health = playerStats.maxHealth,
        color = COLORS.player,
        invulnerable = false,
        invulnerableTimer = 0
    }
end

-- Create background stars
function createStars(count)
    local windowWidth, windowHeight = love.graphics.getDimensions()
    for i = 1, count do
        table.insert(stars, {
            x = math.random(windowWidth),
            y = math.random(windowHeight),
            size = math.random(1, 3),
            speed = math.random(10, 50),
            brightness = math.random(50, 100) / 100
        })
    end
end

-- Update game state
function love.update(dt)
    if gameState == "start" then
        updateStart(dt)
    elseif gameState == "play" then
        updatePlay(dt)
    elseif gameState == "gameover" then
        updateGameOver(dt)
    elseif gameState == "levelup" then
        -- Do nothing, wait for input
    end
end

-- Update start screen
function updateStart(dt)
    updateStars(dt)
    
    -- Pressing space starts the game
    if love.keyboard.isDown("space") then
        gameState = "play"
    end
end

-- Update game over screen
function updateGameOver(dt)
    updateStars(dt)
    
    -- Pressing space restarts the game
    if love.keyboard.isDown("space") then
        resetGame()
        gameState = "play"
    end
end

-- Update gameplay
function updatePlay(dt)
    -- Update player
    updatePlayer(dt)
    
    -- Update bullets
    updateBullets(dt)
    
    -- Update enemies
    updateEnemies(dt)
    
    -- Update powerups
    updatePowerups(dt)
    
    -- Update stars
    updateStars(dt)
    
    -- Spawn enemies
    enemySpawnTimer = enemySpawnTimer + dt
    if enemySpawnTimer >= 1.5 then
        spawnEnemy()
        enemySpawnTimer = 0
    end
    
    -- Spawn powerups occasionally
    powerupSpawnTimer = powerupSpawnTimer + dt
    if powerupSpawnTimer >= 15 then
        if math.random() < 0.6 then
            spawnPowerup()
        end
        powerupSpawnTimer = 0
    end
    
    -- Check for level up
    if playerStats.exp >= playerStats.expToLevel then
        gameState = "levelup"
    end
end

-- Update player movement and shooting
function updatePlayer(dt)
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Movement
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        player.x = player.x - playerStats.speed * dt
    end
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        player.x = player.x + playerStats.speed * dt
    end
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        player.y = player.y - playerStats.speed * dt
    end
    if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        player.y = player.y + playerStats.speed * dt
    end
    
    -- Constrain player to screen bounds
    player.x = math.max(player.width / 2, math.min(player.x, windowWidth - player.width / 2))
    player.y = math.max(player.height / 2, math.min(player.y, windowHeight - player.height / 2))
    
    -- Shooting mechanics
    shootTimer = shootTimer + dt
    if love.keyboard.isDown("space") and shootTimer >= playerStats.fireRate then
        fireBullet()
        shootTimer = 0
    end
    
    -- Update invulnerability timer
    if player.invulnerable then
        player.invulnerableTimer = player.invulnerableTimer - dt
        if player.invulnerableTimer <= 0 then
            player.invulnerable = false
        end
    end
end

-- Fire a bullet from the player
function fireBullet()
    table.insert(bullets, {
        x = player.x,
        y = player.y - player.height / 2,
        width = 5,
        height = 10,
        speed = 400,
        damage = playerStats.damage,
        color = COLORS.bullet,
        fromPlayer = true
    })
end

-- Update all bullets
function updateBullets(dt)
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        
        -- Move bullet
        if bullet.fromPlayer then
            bullet.y = bullet.y - bullet.speed * dt
        else
            bullet.y = bullet.y + bullet.speed * dt
        end
        
        -- Remove bullets that go off screen
        if bullet.y < -bullet.height or bullet.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end
    
    -- Check collisions with player
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if not bullet.fromPlayer and checkCollision(bullet, player) and not player.invulnerable then
            player.health = player.health - bullet.damage
            if playerStats.shield > 0 then
                playerStats.shield = math.max(0, playerStats.shield - bullet.damage)
            end
            table.remove(bullets, i)
            
            -- Check player death
            if player.health <= 0 then
                gameState = "gameover"
            else
                -- Make player invulnerable for a short time
                player.invulnerable = true
                player.invulnerableTimer = 1
            end
        end
    end
    
    -- Check collisions with enemies
    for i = #bullets, 1, -1 do
        if i > #bullets then break end -- Safety check if bullet was removed
        
        local bullet = bullets[i]
        if bullet.fromPlayer then
            for j = #enemies, 1, -1 do
                local enemy = enemies[j]
                
                if checkCollision(bullet, enemy) then
                    enemy.health = enemy.health - bullet.damage
                    table.remove(bullets, i)
                    
                    if enemy.health <= 0 then
                        -- Grant experience
                        playerStats.exp = playerStats.exp + enemy.expValue
                        
                        -- Random chance to drop powerup
                        if math.random() < 0.1 then
                            spawnPowerup(enemy.x, enemy.y)
                        end
                        
                        table.remove(enemies, j)
                        table.remove(enemyShootTimers, j)
                    end
                    
                    break -- Break out of enemy loop since bullet is removed
                end
            end
        end
    end
end

-- Update all enemies
function updateEnemies(dt)
    for i, enemy in ipairs(enemies) do
        -- Move enemy
        enemy.y = enemy.y + enemy.speed * dt
        
        -- Simple AI: move toward player
        if enemy.y > enemy.size * 2 then
            if enemy.x < player.x then
                enemy.x = enemy.x + enemy.speed * 0.2 * dt
            elseif enemy.x > player.x then
                enemy.x = enemy.x - enemy.speed * 0.2 * dt
            end
        end
        
        -- Check if enemy is off screen
        if enemy.y > love.graphics.getHeight() + enemy.size then
            table.remove(enemies, i)
            table.remove(enemyShootTimers, i)
        end
        
        -- Enemy shooting
        enemyShootTimers[i] = enemyShootTimers[i] + dt
        if enemyShootTimers[i] >= enemy.shootRate then
            -- Fire enemy bullet
            table.insert(bullets, {
                x = enemy.x,
                y = enemy.y + enemy.size,
                width = 4,
                height = 8,
                speed = 200,
                damage = enemy.damage,
                color = enemy.color,
                fromPlayer = false
            })
            enemyShootTimers[i] = 0
        end
        
        -- Check collision with player
        if checkCollision(enemy, player) and not player.invulnerable then
            player.health = player.health - enemy.damage
            if playerStats.shield > 0 then
                playerStats.shield = math.max(0, playerStats.shield - enemy.damage)
            end
            
            -- Check player death
            if player.health <= 0 then
                gameState = "gameover"
            else
                -- Make player invulnerable for a short time
                player.invulnerable = true
                player.invulnerableTimer = 1
            end
        end
    end
end

-- Update all powerups
function updatePowerups(dt)
    for i = #powerups, 1, -1 do
        local powerup = powerups[i]
        
        -- Move powerup down
        powerup.y = powerup.y + 50 * dt
        
        -- Remove powerups that go off screen
        if powerup.y > love.graphics.getHeight() + powerup.size then
            table.remove(powerups, i)
            goto continue
        end
        
        -- Check collision with player
        if checkCollision(powerup, player) then
            -- Apply powerup effect
            powerup.type.effect()
            table.remove(powerups, i)
        end
        
        ::continue::
    end
end

-- Update background stars
function updateStars(dt)
    for i, star in ipairs(stars) do
        star.y = star.y + star.speed * dt
        
        -- Reset stars that go off screen
        if star.y > love.graphics.getHeight() then
            star.y = 0
            star.x = math.random(love.graphics.getWidth())
        end
    end
end

-- Spawn a new enemy
function spawnEnemy()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Choose enemy type based on player level
    local availableTypes = {}
    for i, type in ipairs(ENEMY_TYPES) do
        if i <= math.ceil(playerStats.level / 2) then
            table.insert(availableTypes, type)
        end
    end
    
    local enemyType = availableTypes[math.random(#availableTypes)]
    
    -- Create enemy
    local enemy = {
        x = math.random(enemyType.size, windowWidth - enemyType.size),
        y = -enemyType.size,
        size = enemyType.size,
        health = enemyType.health * (1 + (playerStats.level - 1) * 0.1),
        damage = enemyType.damage * (1 + (playerStats.level - 1) * 0.1),
        speed = enemyType.speed,
        expValue = enemyType.expValue,
        color = enemyType.color,
        shootRate = enemyType.shootRate,
        type = enemyType.name
    }
    
    table.insert(enemies, enemy)
    table.insert(enemyShootTimers, 0)
end

-- Spawn a new powerup
function spawnPowerup(x, y)
    local windowWidth = love.graphics.getWidth()
    
    -- Default position if not provided
    x = x or math.random(20, windowWidth - 20)
    y = y or -20
    
    local powerupType = POWERUP_TYPES[math.random(#POWERUP_TYPES)]
    
    table.insert(powerups, {
        x = x,
        y = y,
        size = 15,
        type = powerupType,
        color = powerupType.color
    })
end

-- Reset game to initial state
function resetGame()
    -- Reset player stats
    playerStats = {
        level = 1,
        exp = 0,
        expToLevel = 100,
        health = 100,
        maxHealth = 100,
        damage = 10,
        fireRate = 0.3,
        speed = 200,
        shield = 0
    }
    
    -- Reset game elements
    resetPlayer()
    enemies = {}
    bullets = {}
    powerups = {}
    enemyShootTimers = {}
    
    -- Reset timers
    shootTimer = 0
    enemySpawnTimer = 0
    powerupSpawnTimer = 0
end

-- Check collision between two objects
function checkCollision(a, b)
    -- For player and bullets (rectangle)
    if a.width and b.width then
        return a.x < b.x + b.width and
               a.x + a.width > b.x and
               a.y < b.y + b.height and
               a.y + a.height > b.y
    -- For enemies and powerups (circle) with other objects
    elseif a.size and b.width then
        local circleDistX = math.abs(a.x - (b.x + b.width/2))
        local circleDistY = math.abs(a.y - (b.y + b.height/2))
        
        if circleDistX > (b.width/2 + a.size) then return false end
        if circleDistY > (b.height/2 + a.size) then return false end
        
        if circleDistX <= (b.width/2) then return true end
        if circleDistY <= (b.height/2) then return true end
        
        local cornerDistance = (circleDistX - b.width/2)^2 + (circleDistY - b.height/2)^2
        return cornerDistance <= (a.size^2)
    -- For rectangle (like player) with circle (like enemy)
    elseif a.width and b.size then
        return checkCollision(b, a)
    -- For circles with circles
    elseif a.size and b.size then
        local dx = a.x - b.x
        local dy = a.y - b.y
        local distance = math.sqrt(dx * dx + dy * dy)
        return distance < a.size + b.size
    end
    
    return false
end

-- Level up the player with stat increases
function levelUp(choice)
    playerStats.level = playerStats.level + 1
    playerStats.exp = playerStats.exp - playerStats.expToLevel
    playerStats.expToLevel = math.floor(playerStats.expToLevel * 1.2)
    
    -- Apply stat increase based on player's choice
    if choice == 1 then
        -- More health
        playerStats.maxHealth = playerStats.maxHealth + 20
        player.health = playerStats.maxHealth
    elseif choice == 2 then
        -- More damage
        playerStats.damage = playerStats.damage + 5
    elseif choice == 3 then
        -- Faster firing rate
        playerStats.fireRate = playerStats.fireRate * 0.9
    elseif choice == 4 then
        -- Faster movement
        playerStats.speed = playerStats.speed + 20
    end
    
    gameState = "play"
end

-- Draw game elements
function love.draw()
    if gameState == "start" then
        drawStart()
    elseif gameState == "play" then
        drawPlay()
    elseif gameState == "gameover" then
        drawGameOver()
    elseif gameState == "levelup" then
        drawLevelUp()
    end
end

-- Draw start screen
function drawStart()
    -- Draw background and stars
    love.graphics.setBackgroundColor(COLORS.background)
    drawStars()
    
    -- Draw title and instructions
    love.graphics.setColor(COLORS.text)
    love.graphics.printf("SPACE SHOOTER RPG", 0, 150, love.graphics.getWidth(), "center")
    love.graphics.printf("Use WASD or Arrow Keys to move", 0, 250, love.graphics.getWidth(), "center")
    love.graphics.printf("SPACE to shoot", 0, 280, love.graphics.getWidth(), "center")
    love.graphics.printf("Defeat enemies to gain experience and level up", 0, 310, love.graphics.getWidth(), "center")
    love.graphics.printf("Press SPACE to start", 0, 400, love.graphics.getWidth(), "center")
end

-- Draw gameplay elements
function drawPlay()
    -- Draw background and stars
    love.graphics.setBackgroundColor(COLORS.background)
    drawStars()
    
    -- Draw player
    if not player.invulnerable or (player.invulnerable and math.floor(love.timer.getTime() * 10) % 2 == 0) then
        love.graphics.setColor(player.color)
        love.graphics.polygon("fill", 
            player.x, player.y - player.height/2, 
            player.x - player.width/2, player.y + player.height/2, 
            player.x + player.width/2, player.y + player.height/2
        )
        
        -- Draw shield if active
        if playerStats.shield > 0 then
            love.graphics.setColor(COLORS.shield)
            love.graphics.circle("line", player.x, player.y, player.width * 0.8)
        end
    end
    
    -- Draw enemies
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(enemy.color)
        love.graphics.circle("fill", enemy.x, enemy.y, enemy.size)
        
        -- Draw enemy health bar
        local healthBarWidth = enemy.size * 2
        local healthPercent = enemy.health / (ENEMY_TYPES[1].health * (1 + (playerStats.level - 1) * 0.1))
        if enemy.type == "Destroyer" then
            healthPercent = enemy.health / (ENEMY_TYPES[2].health * (1 + (playerStats.level - 1) * 0.1))
        elseif enemy.type == "Battleship" then
            healthPercent = enemy.health / (ENEMY_TYPES[3].health * (1 + (playerStats.level - 1) * 0.1))
        end
        
        love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
        love.graphics.rectangle("fill", enemy.x - healthBarWidth/2, enemy.y - enemy.size - 8, healthBarWidth, 5)
        love.graphics.setColor(0.8, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", enemy.x - healthBarWidth/2, enemy.y - enemy.size - 8, healthBarWidth * healthPercent, 5)
    end
    
    -- Draw bullets
    for _, bullet in ipairs(bullets) do
        love.graphics.setColor(bullet.color)
        love.graphics.rectangle("fill", bullet.x - bullet.width/2, bullet.y - bullet.height/2, bullet.width, bullet.height)
    end
    
    -- Draw powerups
    for _, powerup in ipairs(powerups) do
        love.graphics.setColor(powerup.color)
        love.graphics.circle("fill", powerup.x, powerup.y, powerup.size)
    end
    
    -- Draw UI
    drawUI()
end

-- Draw game over screen
function drawGameOver()
    -- Draw background and stars
    love.graphics.setBackgroundColor(COLORS.background)
    drawStars()
    
    -- Draw game over text and stats
    love.graphics.setColor(COLORS.text)
    love.graphics.printf("GAME OVER", 0, 150, love.graphics.getWidth(), "center")
    love.graphics.printf("Level reached: " .. playerStats.level, 0, 220, love.graphics.getWidth(), "center")
    love.graphics.printf("Press SPACE to restart", 0, 350, love.graphics.getWidth(), "center")
end

-- Draw level up screen
function drawLevelUp()
    -- Draw background and stars
    love.graphics.setBackgroundColor(COLORS.background)
    drawStars()
    
    -- Draw level up text and options
    love.graphics.setColor(COLORS.text)
    love.graphics.printf("LEVEL UP!", 0, 100, love.graphics.getWidth(), "center")
    love.graphics.printf("Choose an upgrade:", 0, 150, love.graphics.getWidth(), "center")
    
    love.graphics.printf("1. Increase max health (+20)", 0, 220, love.graphics.getWidth(), "center")
    love.graphics.printf("2. Increase damage (+5)", 0, 250, love.graphics.getWidth(), "center")
    love.graphics.printf("3. Increase fire rate", 0, 280, love.graphics.getWidth(), "center")
    love.graphics.printf("4. Increase movement speed", 0, 310, love.graphics.getWidth(), "center")
    
    love.graphics.printf("Press 1-4 to select", 0, 380, love.graphics.getWidth(), "center")
end

-- Draw game UI
function drawUI()
    -- Draw health bar
    local barWidth = 200
    local barHeight = 20
    local healthPercent = player.health / playerStats.maxHealth
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.rectangle("fill", 20, 20, barWidth, barHeight)
    love.graphics.setColor(COLORS.health)
    love.graphics.rectangle("fill", 20, 20, barWidth * healthPercent, barHeight)
    love.graphics.setColor(COLORS.text)
    love.graphics.printf("HP: " .. math.floor(player.health) .. "/" .. playerStats.maxHealth, 20, 22, barWidth, "center")
    
    -- Draw shield bar if player has shield
    if playerStats.shield > 0 then
        love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
        love.graphics.rectangle("fill", 20, 45, barWidth, barHeight)
        love.graphics.setColor(COLORS.shield)
        love.graphics.rectangle("fill", 20, 45, barWidth * (playerStats.shield / 50), barHeight)
        love.graphics.setColor(COLORS.text)
        love.graphics.printf("Shield: " .. math.floor(playerStats.shield), 20, 47, barWidth, "center")
    end
    
    -- Draw experience bar
    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)
    love.graphics.rectangle("fill", 20, love.graphics.getHeight() - 40, barWidth, barHeight)
    love.graphics.setColor(COLORS.exp)
    love.graphics.rectangle("fill", 20, love.graphics.getHeight() - 40, barWidth * (playerStats.exp / playerStats.expToLevel), barHeight)
    love.graphics.setColor(COLORS.text)
    love.graphics.printf("EXP: " .. playerStats.exp .. "/" .. playerStats.expToLevel, 20, love.graphics.getHeight() - 38, barWidth, "center")
    
    -- Draw level indicator
    love.graphics.setColor(COLORS.text)
    love.graphics.print("Level: " .. playerStats.level, love.graphics.getWidth() - 100, 20)
    
    -- Draw stats
    love.graphics.print("DMG: " .. playerStats.damage, love.graphics.getWidth() - 100, 40)
    love.graphics.print("SPD: " .. playerStats.speed, love.graphics.getWidth() - 100, 60)
    love.graphics.print("FIRE: " .. string.format("%.2f", 1/playerStats.fireRate) .. "/s", love.graphics.getWidth() - 100, 80)
end

-- Draw background stars
function drawStars()
    for _, star in ipairs(stars) do
        love.graphics.setColor(star.brightness, star.brightness, star.brightness, 1)
        love.graphics.rectangle("fill", star.x, star.y, star.size, star.size)
    end
end

-- Handle key presses
function love.keypressed(key)
    if gameState == "levelup" then
        if key == "1" then
            levelUp(1)
        elseif key == "2" then
            levelUp(2)
        elseif key == "3" then
            levelUp(3)
        elseif key == "4" then
            levelUp(4)
        end
    end
    
    -- Quick restart with R
    if key == "r" and (gameState == "play" or gameState == "gameover") then
        resetGame()
        gameState = "play"
    end
    
    -- Quit with escape
    if key == "escape" then
        love.event.quit()
    end
end