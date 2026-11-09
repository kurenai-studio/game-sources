buildingProps = {
    width = 1400,
    alley = 100,
    roofmin = 800,
    roofmax = 1200
}

hero = {
    accelcoef = 4,
    topspd = 800,
    jump = 1800,
    canJump = true
}

cam = {
    accelcoef = 10,
    centerx = 200,
    centery = 360,
    x = 0,
    y = 0
}

cloudaltmin = 0
cloudaltmax = 300

cloudprob = 0.015
enemyprob = 0.01

clouds = {}
enemies = {}

fires = {}
firespd = 4

burn = 0
burncoef = 0.5

dousecharges = 3
douseantiburn = -1

health = 100

gameover = false

parallaxcoef = 0.10

usedouse = true

function love.load()
    rng = love.math.newRandomGenerator()
    
    love.physics.setMeter(32)
    world = love.physics.newWorld(0, 40*32, true)
    world:setCallbacks(beginContact, nil, nil, nil)
    
    buildings = { {}, {}, {}, {}}
    
    for i, bdg in ipairs(buildings) do
        bdg.body = love.physics.newBody(world, (i - 1)*(buildingProps.width + buildingProps.alley), rng:random(buildingProps.roofmin, buildingProps.roofmax), "static")
        bdg.shape = love.physics.newRectangleShape(buildingProps.width, 2000)
        bdg.fixture = love.physics.newFixture(bdg.body, bdg.shape)
        bdg.fixture:setFriction(0)
    end
    
    hero.body = love.physics.newBody(world, 0, buildings[1].body:getY() - 1080, "dynamic")
    hero.shape = love.physics.newRectangleShape(32, 64)
    hero.fixture = love.physics.newFixture(hero.body, hero.shape, 1)
    hero.body:setFixedRotation(true)
    hero.fixture:setFriction(0)
    hero.body:setLinearVelocity(hero.topspd, 0)

    love.graphics.setBackgroundColor(220, 220, 220)
    love.window.setMode(1280, 720)
    
    starttime = love.timer.getTime()
end

function beginContact(a, b, coll)
    if a == hero.fixture or b == hero.fixture then
        hero.canJump = true
    end
end

function love.update(dt)
    world:update(dt)
    
    if love.keyboard.isDown("space") and hero.canJump then
        hero.body:applyLinearImpulse(0, -hero.jump)
        hero.canJump = false
    end
    
    if love.keyboard.isDown("q") then
        if usedouse and dousecharges > 0 then
            dousecharges = dousecharges - 1
            burn = douseantiburn
        end
        usedouse = false
    else
        usedouse = true
    end
    
    if love.keyboard.isDown("lshift") then
        hero.jump = 900
        hero.topspd = 100
    else
        hero.jump = 1800
        hero.topspd = 800
    end
    
    for i, f in ipairs(fires) do
        if math.abs(f.x - hero.body:getX()) + math.abs(f.y - hero.body:getY()) < 200 then
            burn = burn + (burncoef * dt)
        end
        f.progress = f.progress + (firespd * dt)
    end
    
    health = health - (burn * dt)
    
    if health > 100 then
        health = 100
    end
    
    if (health < 0 or hero.body:getY() > 1000) and not gameover then
        gameover = true
        endtime = love.timer.getTime()
        totaltime = endtime - starttime
    end
    
    if gameover then
        health = 0
    end
        
    for i = #fires,1,-1 do
        if fires[i].progress > 1 then
            table.remove(fires, i)
        end
    end
    
    for i, e in ipairs(enemies) do
        e.x = e.x + e.xvel
        spawnfire(e.x, e.y, e.x + (40 *e.xvel), e.y + 100)
    end
    
    for i = #enemies,1,-1 do
        if enemies[i].x + 1000 < hero.body:getX() then
            table.remove(enemies, i)
        end
    end
    
    if buildings[1].body:getX() - hero.body:getX() < -1000 then
        local tmp = buildings[1]
        buildings[1] = buildings[2]
        buildings[2] = buildings[3]
        buildings[3] = buildings[4]
        buildings[4] = tmp
        
        tmp.body:setPosition(tmp.body:getX() + 3*(buildingProps.width + buildingProps.alley), rng:random(buildingProps.roofmin, buildingProps.roofmax))
    end
    
    local xvel, yvel = hero.body:getLinearVelocity()
    hero.body:applyForce(hero.accelcoef*(hero.topspd - xvel), 0)
    
    
    cam.x = cam.x - ((cam.x - hero.body:getX()) * cam.accelcoef * dt)
    cam.y = cam.y - ((cam.y - hero.body:getY()) * cam.accelcoef * dt)
    
    if rng:random() < cloudprob then
        clouds[#clouds + 1] = {
            x = (cam.x - cam.centerx) + 1380 / parallaxcoef,
            y = (cam.y - cam.centery) + rng:random(cloudaltmin, cloudaltmax) / parallaxcoef
        }
    end
    
    if rng:random() < enemyprob then
        spawnenemy((cam.x - cam.centerx) + 1380, (cam.y - cam.centery) - 100 + rng:random(100), rng:random(-6, -2))
    end
    
    if rng:random(80) < burn then
        local firex = hero.body:getX() + rng:random(-10, 10)
        local firey = hero.body:getY() + rng:random(-10, 10)
        spawnfire(firex, firey, firex, firey - 100)
    end
end

function drawfire(f)
    love.graphics.setColor(235, 60, 5, 255 * (2 - 2*f.progress))
    love.graphics.circle("fill", (f.x * (1 - f.progress)) + (f.xp * f.progress), (f.y * (1 - f.progress)) + (f.yp * f.progress), 5 + (40 * f.progress))
end

function spawnfire(x, y, xp, yp)
    local f = {}
    
    dx = rng:random(-5, 5)
    dy = rng:random(-5, 5)
    
    f.x = x + dx
    f.y = y + dy
    f.xp = xp + dx
    f.yp = yp + dy
    f.progress = 0
    
    fires[#fires + 1] = f
end

function spawnenemy(x, y, xvel)
    local e = {}
    
    e.x = x
    e.y = y
    e.xvel = xvel
    
    enemies[#enemies + 1] = e
end

function cloud(x, y)
    love.graphics.circle("fill", x, y, 200)
    love.graphics.circle("fill", x - 200, y + 80, 100)
    love.graphics.circle("fill", x + 200, y + 80, 100)
end

function ship(x, y)
    local fx, fy = x - 2000, y
    local tx, ty = x + 1000, y - 500
    local bx, by = x + 1000, y - 500
    love.graphics.polygon("fill", fx, fy, tx, ty, bx, by)
end

function love.draw()
    love.graphics.push()    
    love.graphics.scale(parallaxcoef)
    love.graphics.translate((-cam.x + cam.centerx), (-cam.y + cam.centery))
    
    love.graphics.setColor(255,255,255)
    for i, coord in ipairs(clouds) do
        cloud(coord.x, coord.y)
    end
    
    love.graphics.setColor(255, 0, 255)
    love.graphics.circle("fill", (cam.x - cam.centerx), (cam.y - cam.centery), 50)
    love.graphics.circle("fill", (cam.x - cam.centerx) + 1280 / parallaxcoef, (cam.y - cam.centery), 50)
    love.graphics.pop()
    
    love.graphics.push()
    love.graphics.scale(0.8)
    love.graphics.translate(-cam.x + cam.centerx, -cam.y + cam.centery)
    
    love.graphics.setColor(40, 40, 40)
    for i, bdg in ipairs(buildings) do
        love.graphics.polygon("fill", bdg.body:getWorldPoints(bdg.shape:getPoints()))
    end

    love.graphics.setColor(0, 95, 125)
    love.graphics.polygon("fill", hero.body:getWorldPoints(hero.shape:getPoints()))
    
    for i, f in ipairs(fires) do
        drawfire(f)
    end
    love.graphics.setColor(0, 255, 0)
    for i, e in ipairs(enemies) do
        ship(e.x, e.y)
    end
    
    love.graphics.pop()
    
    love.graphics.setColor(0, 190, 250)
    for i = 1, dousecharges do
        love.graphics.circle("fill", -10 + (50 * i), 40, 20, 256)
    end
    
    love.graphics.setColor(0, 152, 200)
    love.graphics.rectangle("fill", 200, 30, 4 * health, 20)
    love.graphics.rectangle("line", 200, 30, 400, 20)
    
    if gameover then
        love.graphics.setColor(0, 0, 0)
        love.graphics.print("Time: " .. totaltime ..  " seconds", 20, 200)
    end
end
