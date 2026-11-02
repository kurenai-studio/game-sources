-- Simon the game

debug=true

-- Setup
function love.load()
    paused = false

    -- dimensions to draw squares
    x1, x2 = 200, 400
    y1, y2 = 150, 350
    w, h = 160, 160

    -- tables to hold squares
    red, green, blue, yellow = {}, {}, {}, {}

    -- sounds for each square
    red.sound = love.audio.newSource('sounds/red.wav', 'static')
    green.sound = love.audio.newSource('sounds/green.wav', 'static')
    blue.sound = love.audio.newSource('sounds/blue.wav', 'static')
    yellow.sound = love.audio.newSource('sounds/yellow.wav', 'static')

    -- instructions
    intro = 'Simon will play a random sequence and then ask you to repeat it.' ..
    ' As the game progresses, the sequence will get more difficult. Good Luck!'
    love.window.showMessageBox('Welcome to Simon', intro)

    -- our player
    player = {score = 0}
end

-- Update
function love.update(dt)
    if not paused then
        -- Exit game using 'esc'
        if love.keyboard.isDown('escape') then
            love.event.push('quit')
        end

         -- restart game using 'q'
        if love.keyboard.isDown('q') then
            resetGame()
        end
    end
end

-- Render
function love.draw()
    if paused then
        love.graphics.setColor(255, 255, 255)
        love.graphics.print("GAME PAUSED.", 10, 200)
    end

    red.color = love.graphics.setColor(204, 0, 0)
    red.shape = love.graphics.rectangle("fill", x1, y1, w, h)

    green.color = love.graphics.setColor(0, 204, 0)
    green.shape = love.graphics.rectangle("fill", x2, y1, w, h)

    blue.color = love.graphics.setColor(0, 0, 204)
    blue.shape = love.graphics.rectangle("fill", x1, y2, w, h)

    yellow.color = love.graphics.setColor(204, 204, 0)
    yellow.shape = love.graphics.rectangle("fill", x2, y2, w, h)

    -- what to do when r, g, b and y keys are pressed
    if love.keyboard.isDown('r') then
        red.sound:play()
        red.color = love.graphics.setColor(255, 0, 0)
        red.shape = love.graphics.rectangle("fill", x1, y1, w, h)
    elseif love.keyboard.isDown('g') then
        green.sound:play()
        green.color = love.graphics.setColor(0, 255, 0)
        green.shape = love.graphics.rectangle("fill", x2, y1, w, h)
    elseif love.keyboard.isDown('b') then
        blue.sound:play()
        blue.color = love.graphics.setColor(0, 0, 255)
        blue.shape = love.graphics.rectangle("fill", x1, y2, w, h)
    elseif love.keyboard.isDown('y') then
        yellow.sound:play()
        yellow.color = love.graphics.setColor(255, 255, 0)
        yellow.shape = love.graphics.rectangle("fill", x2, y2, w, h)
    end
end

function love.keyPressed(key)
    if key == "space" then
        paused = not paused
    end
end

function randomSequence(max)
    sequence = {}
    for i=1,max do
        table.insert(sequence, love.math.random(i))
    end
    return sequence
end

function playSequence()
    randomSequence(4)
    -- set each number to corresponding square
    -- change background and play sound for each square
    for key, value in ipairs(sequence)
        do
            if value == 1 then
                red.color = love.graphics.setColor(250, 100, 100)
                red.sound:play()
            elseif value == 2 then
                green.color = love.graphics.setColor(100, 250, 100)
                green.sound:play()
            elseif value == 3 then
                blue.color = love.graphics.setColor(100, 100, 250)
                blue.sound:play()
            elseif value == 4 then
                yellow.color = love.graphics.setColor(250, 250, 0)
                yellow.sound:play()
            end
    end
end

function checkSequence()
    playerSequence = {}
    -- after sequence plays, put keys pressed into playerSequence
      -- pressing [enter] terminates the sequence
    -- compare playerSequence and randomSequence
    -- if match for input and position return true
      -- else return false
end

function updateScore()
    if checkSequence then
        player.score = player.score + 1
        love.graphics.print("Score: " .. player.score, 400, 200)
    end
end

function gameOver()
    love.graphics.print("GAME OVER! Your score was: " .. player.score, 400, 200)
end

function resetGame()
    love.graphics.print('Resetting game..please wait', 400, 300)
    love.load()
end

function pauseGame()
end

function startGame()
    repeat
        randomSequence()
        playSequence()
        checkSequence()
        updateScore()
    until checkSequence == false
        gameOver()
end
