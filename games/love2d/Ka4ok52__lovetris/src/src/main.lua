-- Lua 5.4.6
-- Tetris by Koti4
local love = require('love')
local shader = require('shader')
local drawText = require('drawText')
local drawGameContent = require('ui')

local GRID_WIDTH = 10
local GRID_HEIGHT = 20
local gameState = 'MENU'
local quitConfirmCounter = 0

local grid
local currentShapeId
local currentShape
local curX, curY

local pieceQueue = {}
local QUEUE_SIZE = 4
local holdShapeId = nil
local canHold = true

local dropTimer = 0
local dropSpeed = 0.4
local moveTimer = 0
local moveDelay = 0.2
local moveRate = 0.05
local score = 0
local lockTimer = 0
local lockResets = 0
local LOCK_DELAY = 0.5
local MAX_RESETS = 10

local t = 0
local pulseShader
local fonts

local TETRAMINO = {
    {{0,0,0,0},{1,1,1,1},{0,0,0,0},{0,0,0,0}}, -- I
    {{1,0,0},{1,1,1},{0,0,0}},                 -- J
    {{0,0,1},{1,1,1},{0,0,0}},                 -- L
    {{1,1},{1,1}},                             -- O
    {{0,1,1},{1,1,0},{0,0,0}},                 -- S
    {{0,1,0},{1,1,1},{0,0,0}},                 -- T
    {{1,1,0},{0,1,1},{0,0,0}}                  -- Z
}
local bag7 = {}

local function canMove(nextX, nextY, shape)
    for y = 1, #shape do
        for x = 1, #shape[y] do
            if shape[y][x] ~= 0 then
                local gx = nextX + x - 1
                local gy = nextY + y - 1
                if gx < 1 or gx > GRID_WIDTH or gy > GRID_HEIGHT then return false end
                if gy > 0 and grid[gy][gx] ~= 0 then return false end
            end
        end
    end
    return true
end

local function fillQueue()
    while #pieceQueue < QUEUE_SIZE do
        if #bag7 == 0 then
            for i = 1, #TETRAMINO do
                bag7[i] = i
            end
        end
        local randShape = love.math.random(1, #bag7)
        pieceQueue[#pieceQueue + 1] = bag7[randShape]
        bag7[randShape] = bag7[#bag7]
        bag7[#bag7] = nil
    end
end

local function spawnNewPiece()
    curX = 4
    curY = 0
    currentShapeId = table.remove(pieceQueue, 1)
    currentShape = TETRAMINO[currentShapeId]
    fillQueue()
    canHold = true

    if not canMove(curX, curY, currentShape) then
        gameState = 'GAMEOVER'
        quitConfirmCounter = 0
    end
end

local function swapHold()
    if not canHold then return end
    if holdShapeId == nil then
        holdShapeId = currentShapeId
        spawnNewPiece()
        canHold = false
    else
        local temp = currentShapeId
        currentShapeId = holdShapeId
        holdShapeId = temp
        currentShape = TETRAMINO[currentShapeId]
        curX = 4
        curY = 0
        canHold = false
    end
end

local function resetGame()
    grid = {}
    for y = 1, GRID_HEIGHT do
        grid[y] = {}
        for x = 1, GRID_WIDTH do grid[y][x] = 0 end
    end
    quitConfirmCounter = 0
    score = 0
    dropTimer = 0
    lockTimer = 0
    holdShapeId = nil
    canHold = true
    pieceQueue = {}
    fillQueue()
    spawnNewPiece()

    gameState = 'PLAYING' -- START
end

local function checkLines()
    local linesCleared = 0
    local y = GRID_HEIGHT
    while y >= 1 do
        local isFull = true
        for x = 1, GRID_WIDTH do
            if grid[y][x] == 0 then 
                isFull = false
                break
            end
        end
        if isFull then
            table.remove(grid, y)
            local newRow = {}
            for x=1,GRID_WIDTH do newRow[x]=0 end
            table.insert(grid, 1, newRow)
            linesCleared = linesCleared + 1
        else
            y = y - 1
        end
    end
    if linesCleared > 0 then score = score + (linesCleared * 100) end
end

local function rotate(shape)
    local newShape = {}
    local n = #shape
    for y = 1, n do
        newShape[y] = {}
        for x = 1, n do newShape[y][x] = shape[n - x + 1][y] end -- no table?(
    end
    return newShape
end

local function tryRotate()
    local rotated = rotate(currentShape)
    if canMove(curX, curY, rotated) then currentShape = rotated return end
    if canMove(curX - 1, curY, rotated) then curX = curX - 1; currentShape = rotated return end
    if canMove(curX + 1, curY, rotated) then curX = curX + 1; currentShape = rotated return end
    if #rotated == 4 then -- refine I wall kick
        if canMove(curX - 2, curY, rotated) then curX = curX - 2; currentShape = rotated return
        elseif canMove(curX + 2, curY, rotated) then curX = curX + 2; currentShape = rotated return end
    end
    if canMove(curX, curY - 1, rotated) then curY = curY - 1; currentShape = rotated return end
end

local function resetLockDelay()
    if not canMove(curX, curY + 1, currentShape) then
        if lockResets < MAX_RESETS then
            lockTimer = 0
            lockResets = lockResets + 1
        end
    end
end

function love.load()
    love.math.setRandomSeed(os.time())
    pulseShader = love.graphics.newShader(shader)

    fonts = {
        default    = love.graphics.newFont(14),
        ui         = love.graphics.newFont(24),
        title      = love.graphics.newFont(48)
    }

    gameState = 'MENU'
end

function love.keypressed(key)
    if gameState == 'MENU' then
        if key == 's' then
            resetGame()
        elseif key == 'q' then
            love.event.quit()
        end
        return
    end

    if gameState == 'GAMEOVER' then
        if key == 'q' then
            quitConfirmCounter = quitConfirmCounter + 1
            if quitConfirmCounter >= 2 then
                gameState = 'MENU'
            end
        elseif key == 'r' then
            resetGame()
        end
        return
    end

    if key == 'p' then
        if gameState == 'PLAYING' then
            gameState = 'PAUSED'
            quitConfirmCounter = 0
        elseif gameState == 'PAUSED' then
            gameState = 'PLAYING'
        end
    end

    if gameState == 'PAUSED' then
        if key == 'q' then
            quitConfirmCounter = quitConfirmCounter + 1
            if quitConfirmCounter >= 2 then
                gameState = 'MENU'
                quitConfirmCounter = 0
            end
        end
        return
    end

    if gameState == 'PLAYING' then
        if key == "up" then
            tryRotate()
            resetLockDelay()
        elseif key == "space" then
            while canMove(curX, curY + 1, currentShape) do curY = curY + 1 end
            dropTimer = dropSpeed
            lockTimer = LOCK_DELAY
        elseif key == "lshift" or key == "rshift" then swapHold()
        elseif key == "left" then
            if canMove(curX - 1, curY, currentShape) then
                curX = curX - 1
                moveTimer = -moveDelay
                resetLockDelay()
                end
        elseif key == "right" then
            if canMove(curX + 1, curY, currentShape) then
                curX = curX + 1
                moveTimer = -moveDelay
                resetLockDelay()
                end
        elseif key == "down" then
            if canMove(curX, curY + 1, currentShape) then
                curY = curY + 1
                moveTimer = -moveRate
                end
        end
    end
end

local function lockPiece()
    for y = 1, #currentShape do
        for x = 1, #currentShape[y] do
            if currentShape[y][x] ~= 0 then
                local gy = curY + y - 1
                local gx = curX + x - 1
                if gy >= 1 then grid[gy][gx] = currentShapeId end
            end
        end
    end
    score = score + 4
    checkLines()
    spawnNewPiece()
    dropTimer = 0
    lockTimer = 0
    lockResets = 0
end

function love.update(dt)
    t = t + dt
    if pulseShader:hasUniform("time") then pulseShader:send("time", t) end

    if gameState == 'PLAYING' then
        dropSpeed = math.max(0.15, 0.5 - (math.floor(score / 1000) * 0.05))

        if canMove(curX, curY + 1, currentShape) then
            dropTimer = dropTimer + dt
            if dropTimer >= dropSpeed then
                curY = curY + 1
                dropTimer = 0
            end
        else
            dropTimer = 0
        end

        -- Lock Delay
        if not canMove(curX, curY + 1, currentShape) then
            lockTimer = lockTimer + dt
            if lockTimer >= LOCK_DELAY then
                lockPiece()
            end
        else
            lockTimer = 0
        end

        -- Key
        if love.keyboard.isDown("left") then
            moveTimer = moveTimer + dt
            if moveTimer >= moveRate then
                if canMove(curX - 1, curY, currentShape) then
                    curX = curX - 1
                    moveTimer = 0
                    resetLockDelay()
                end
            end
        elseif love.keyboard.isDown("right") then
            moveTimer = moveTimer + dt
            if moveTimer >= moveRate then
                if canMove(curX + 1, curY, currentShape) then
                    curX = curX + 1
                    moveTimer = 0
                    resetLockDelay()
                end
            end
        elseif love.keyboard.isDown("down") then
            moveTimer = moveTimer + dt
            if moveTimer >= 0.05 then
                if canMove(curX, curY + 1, currentShape) then
                    curY = curY + 1
                    moveTimer = 0
                else
                    moveTimer = 0
                end
            end
        else
            moveTimer = 0
        end
    end
end

function love.draw()
    local virtualWidth = 800
    local virtualHeight = 700
    local currentWidth = love.graphics.getWidth()
    local currentHeight = love.graphics.getHeight()
    local scale = math.min(currentWidth / virtualWidth, currentHeight / virtualHeight)
    local offsetX = math.floor((currentWidth - virtualWidth * scale) / 2)
    local offsetY = math.floor((currentHeight - virtualHeight * scale) / 2)

    love.graphics.clear(0.1, 0.1, 0.1)
    love.graphics.push("all")
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)

    if gameState == 'MENU' then
        drawText{ text = "TETRIS", x = 0, y = 200, width = 800, align = "center", font = fonts.title }
        drawText{ text = "Press S to Start Game", x = 0, y = 300, width = 800, align = "center", font = fonts.ui, color = {0.5, 1, 0.5} }
        drawText{ text = "Press Q to Quit", x = 0, y = 350, width = 800, align = "center", font = fonts.ui, color = {1, 0.5, 0.5} }

    elseif gameState == 'PLAYING' then
        drawGameContent.draw(grid, currentShape, currentShapeId, curX, curY, pieceQueue, holdShapeId, canHold, score, TETRAMINO, pulseShader, GRID_WIDTH, GRID_HEIGHT, fonts)

    elseif gameState == 'PAUSED' then
        drawGameContent.draw(grid, currentShape, currentShapeId, curX, curY, pieceQueue, holdShapeId, canHold, score, TETRAMINO, pulseShader, GRID_WIDTH, GRID_HEIGHT, fonts)

        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 800, 700)

        drawText{ text = "PAUSED", x = 0, y = 200, width = 800, align = "center", font = fonts.title, color = {1, 1, 1} }
        drawText{ text = "Press P to Resume", x = 0, y = 350, width = 800, align = "center", font = fonts.ui, color = {0.8, 0.8, 0.8} }
        if quitConfirmCounter == 0 then
            drawText{ text = "Press Q twice to Menu", x = 0, y = 400, width = 800, align = "center", font = fonts.ui, color = {0.9, 0.9, 0.9} }
        else
            drawText{ text = "Press Q again to confirm...", x = 0, y = 400, width = 800, align = "center", font = fonts.ui, color = {1, 1, 0} }
        end

    elseif gameState == 'GAMEOVER' then
        love.graphics.clear(0.3, 0.1, 0.1)

        drawText{ text = "GAME OVER", x = 0, y = 250, width = 800, align = "center", font = fonts.title, color = {1, 0.2, 0.2} }
        drawText{ text = "Final Score: " .. score, x = 0, y = 350, width = 800, align = "center", font = fonts.ui, color = {0.8, 0.8, 0.8} }

        if quitConfirmCounter == 0 then
            drawText{ text = "Press Q twice to Menu", x = 0, y = 400, width = 800, align = "center", font = fonts.ui, color = {0.9, 0.9, 0.9} }
        else
            drawText{ text = "Press Q again to confirm...", x = 0, y = 400, width = 800, align = "center", font = fonts.ui, color = {1, 1, 0} }
        end

        drawText{ text = "Press R to Restart immediately", x = 0, y = 450, width = 800, align = "center", font = fonts.ui, color = {0.5, 0.5, 0.5} }
    end

    love.graphics.pop()

end
