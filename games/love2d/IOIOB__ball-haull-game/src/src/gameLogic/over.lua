function overLoad(sc, difficulty)

    score = sc

    particles = {}

    loadScore()

    if score > highScores[difficulty] then
        for i = 0, 512 do
            table.insert(particles, Confetti(random(0, 128), random(-64, 0)))
        end
    end

    if score > highScores[difficulty] then
        highScores[difficulty] = score
    end

    highScore = highScores[difficulty]

    saveScore()

    quitTimer = 0
    quitTime = 0.5
end


function overUpdate(dt)
    if buttonDown(1) or buttonDown(2) or buttonDown(3) or buttonDown(4) then
        quitTimer = quitTimer + dt
        if quitTimer >= quitTime then
            newState(states.start)
        end
    else
        quitTimer = 0
    end

    for i, v in ipairs(particles) do
        v.vely = v.vely + dt
        v.y = v.y + v.vely * dt * 32
    end
end


function overDraw()
    palette(1)
    bigsprite(41, 32, 16, 4, 2)

    local length = FONT:getWidth("score: " .. score)

    palette(2)

    if score >= highScore then
        color(3)
    else
        color(4)
    end
    print("score: ", 64 - length/2, 54)
    print(score, 96 - length/2, 54)


    palette(1)

    --Display high score
    color(3)
    print("high score:", 36, 72)
    color(3)
    printf(highScore, 22, 82, 80, "center")

    color(4)
    print("hold to return: ", 2, 118)
    rect(76, 119, 48, 8)
    color(3)
    rectFill(77, 120, 45 * quitTimer / quitTime, 5)

    for i, v in ipairs(particles) do
        palette(v.palette)
        pixel(v.x, v.y)
    end
end


function Confetti(x, y)
    local confetti = {}
    confetti.x = x
    confetti.y = y
    confetti.vely = random(-32, 0) / 16
    confetti.velx = 0
    confetti.palette = random(2, 4)
    return confetti
end
