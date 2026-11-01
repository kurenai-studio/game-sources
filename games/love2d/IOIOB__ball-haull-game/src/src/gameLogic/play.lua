
function playLoad(diff, diffNum)
    lives = 3
    time = 0
    score = 0

    ballTimer = 0
    ballSpawnTick = 0.3
    ballSpawnRate = 2 --More is less balls

    difficulty = diff or 1 --More is harder
    dn = diffNum

    activeEater = 2
    anim = 0

    balls = {}
    particles = {}

    camShake = 0
end


function playUpdate(dt)

    if abs(camShake) < dt then
        camShake = 0
    else
        camShake = camShake - dt
    end

    if ballTimer > ballSpawnTick then
        ballTimer = ballTimer - ballSpawnTick
        if random(ballSpawnRate) == 1 then
            Ball(random(3))
        end
    else
        ballTimer = ballTimer + dt * difficulty
    end

    updateBalls(dt)
    updateParticles(dt)


    if buttonPressed(2) then
        activeEater = 1
        sound(4)
    elseif buttonPressed(3) then
        activeEater = 2
        sound(4)
    elseif buttonPressed(4) then
        activeEater = 3
        sound(4)
    end

    if lives <= 0 then
        newState(states.over, score + (lives * 10), dn)
    end
end


function playDraw()

    camera(random(-camShake, camShake), random(-camShake, camShake))

    drawBackground()

    drawEatersBottom()

    drawBalls()

    drawEatersTop()

    drawParticles()

    --Draw pipes
    for i = 0, 2 do
        palette(2 + i)
        sprite(3, 24 + i * 32, 0)
    end
end



function Ball(x)
    ball = {}
    ball.x = x
    ball.y = -16
    ball.vely = 0
    ball.active = true
    table.insert(balls, ball)
end

function Particle(x, y, pal, vely)
    local particle = {}
    particle.x = x
    particle.y = y
    particle.vely = random(128)/128 * (vely or 1)
    particle.velx = (random(1, 2) * 2 - 3) / 8
    particle.palette = pal
    particle.color = random(0, 1)
    table.insert(particles, particle)
end

function exParticle(x, y, pal)
    local particle = {}
    particle.x = x
    particle.y = y
    particle.vely = random(-8, 64)/64
    particle.velx = random(-64, 64)/64
    particle.palette = pal
    particle.color = 0
    table.insert(particles, particle)
end


function updateParticles(dt)
    for i, p in ipairs(particles) do
        p.vely = max(p.vely - dt, 0)
        p.x = p.x + p.velx
        p.y = p.y - p.vely
    end
    for i = #particles, 1, -1 do
        if particles[i].vely == 0 then
            table.remove(particles, i)
        end
    end
end

function drawParticles()
    for i, p in ipairs(particles) do
        palette(p.palette)
        color(2 + p.color)
        pixel(p.x, p.y)
    end
end



function drawEatersTop()
    for i = 0, 2 do
        local active = 0
        if i + 1 == activeEater then
            active = 2
        end

        palette(2 + i)
        bigsprite(9 + active, 16 + i * 32, 96, 2, 2)
        color(1)
        local letters = {"a", "s", "d"}
        print(letters[i + 1], 30 + i * 32, 117)
    end
end

function drawEatersBottom()
    for i = 0, 2 do
        local active = 0
        if i + 1 == activeEater then
            active = 2
        end
        palette(2 + i)
        bigsprite(13 + active, 16 + i * 32, 96, 2, 1)
    end
end


function drawBalls()
    for i, ball in ipairs(balls) do
        palette(ball.x + 1)
        sprite(1, ball.x * 32 - 8, ball.y)
    end
end

function updateBalls(dt)
    for i, ball in ipairs(balls) do
        ball.vely = ball.vely + dt
        ball.y = ball.y + ball.vely * difficulty
        if ball.y >= 108 and ball.active then
            if ball.x == activeEater then
                score = score + 1
                ball.active = false
                for i = 0, 64 do
                     Particle((ball.x * 32) + random(-8, 8), 108, ball.x + 1)
                end
                sound(1)
            else
                lives = lives - 1
                ball.active = false
                for i = 0, 32 do
                     exParticle((ball.x * 32) + random(-8, 8), 108, ball.x + 1, 1.5)
                end
                camShake = 1
                sound(2)
            end
        end
    end
    for i = #balls, 1, -1 do
        if balls[i].active == false then
            table.remove(balls, i)
        end
    end
end



function drawBackground()
    --Draw lines
    for x = 0, 3 do
        for y = 0, 7 do
            sprite(2, x * 32 + 15, y * 16)
        end
    end

    --Heart background
    sprite(4, 2, 2)
    sprite(4, 2, 34, 0, 1, -1)
    --Hearts
    palette(2)
    for i = 0, lives - 1 do
        sprite(5, 4, 4 + i * 10)
    end

    palette(4)
    color(4)
    print(floor(score), 124, 3, 90)
end
