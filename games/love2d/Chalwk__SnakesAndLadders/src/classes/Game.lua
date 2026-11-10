-- Snakes and Ladders - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_random = math.random
local math_floor = math.floor
local table_insert = table.insert

local Game = {}
Game.__index = Game

function Game.new()
    local instance = setmetatable({}, Game)

    instance.screenWidth = 1200
    instance.screenHeight = 800
    instance.players = {
        {
            position = 1,
            color = {1, 0.2, 0.2}, -- Red
            name = "Player 1",
            token = "🍕" -- Pizza emoji as token
        },
        {
            position = 1,
            color = {0.2, 0.5, 1}, -- Blue
            name = "Player 2",
            token = "🍔" -- Burger emoji as token
        }
    }
    instance.currentPlayer = 1
    instance.diceValue = 1
    instance.gameOver = false
    instance.winner = nil
    instance.moves = 0
    instance.board = {}
    instance.snakes = {}
    instance.ladders = {}
    instance.diceRolling = false
    instance.animationProgress = 0
    instance.moveAnimation = false
    instance.targetPosition = 1
    instance.animationPlayer = 1

    instance:initBoard()
    instance:initSnakesAndLadders()

    return instance
end

function Game:initBoard()
    -- Create 10x10 board (100 squares)
    self.board = {}
    for i = 1, 100 do
        self.board[i] = {
            number = i,
            row = math_floor((i - 1) / 10),
            col = (i - 1) % 10
        }
    end
end

function Game:initSnakesAndLadders()
    -- Food-themed snakes (bad food that makes you go down)
    self.snakes = {
        {from = 16, to = 6, name = "Spoiled Milk", color = {0.7, 0.9, 0.7}},
        {from = 47, to = 26, name = "Moldy Cheese", color = {0.9, 0.9, 0.6}},
        {from = 49, to = 11, name = "Rotten Apple", color = {0.8, 0.3, 0.3}},
        {from = 56, to = 53, name = "Stale Bread", color = {0.8, 0.7, 0.5}},
        {from = 62, to = 19, name = "Burnt Toast", color = {0.4, 0.3, 0.2}},
        {from = 64, to = 60, name = "Soggy Cereal", color = {0.6, 0.6, 0.8}},
        {from = 87, to = 24, name = "Expired Yogurt", color = {1, 1, 0.8}},
        {from = 93, to = 73, name = "Freezer Burn", color = {0.7, 0.9, 1}},
        {from = 95, to = 75, name = "Wilted Salad", color = {0.3, 0.7, 0.3}},
        {from = 98, to = 78, name = "Melted Ice Cream", color = {1, 0.8, 0.9}}
    }

    -- Food-themed ladders (good food that helps you climb)
    self.ladders = {
        {from = 1, to = 38, name = "Rainbow Lollipop", color = {1, 0.5, 0.9}},
        {from = 4, to = 14, name = "Gummy Bear Stairs", color = {1, 0.8, 0.9}},
        {from = 9, to = 31, name = "Chocolate Bar", color = {0.6, 0.3, 0.1}},
        {from = 21, to = 42, name = "Ice Cream Cone", color = {1, 0.9, 0.7}},
        {from = 28, to = 84, name = "Cupcake Tower", color = {1, 0.7, 0.9}},
        {from = 36, to = 44, name = "French Fry Ladder", color = {1, 0.8, 0.4}},
        {from = 51, to = 67, name = "Pizza Slide", color = {1, 0.5, 0.2}},
        {from = 71, to = 91, name = "Donut Stack", color = {0.8, 0.5, 0.9}},
        {from = 80, to = 100, name = "Cake Staircase", color = {1, 0.9, 0.9}}
    }
end

function Game:setScreenSize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Game:startNewGame()
    self.players[1].position = 1
    self.players[2].position = 1
    self.currentPlayer = 1
    self.diceValue = 1
    self.gameOver = false
    self.winner = nil
    self.moves = 0
    self.diceRolling = false
    self.moveAnimation = false
end

function Game:update(dt)
    if self.gameOver then return end

    if self.diceRolling then
        self.animationProgress = self.animationProgress + dt * 10
        if self.animationProgress >= 1 then
            self.diceRolling = false
            self:finishDiceRoll()
        end
    end

    if self.moveAnimation then
        self.animationProgress = self.animationProgress + dt * 3
        if self.animationProgress >= 1 then
            self.moveAnimation = false
            self:checkSnakesAndLadders()
        end
    end
end

function Game:draw()
    self:drawBoard()
    self:drawSnakesAndLadders()
    self:drawPlayers()
    self:drawUI()

    if self.gameOver then
        self:drawGameOver()
    end
end

function Game:drawBoard()
    local boardSize = math.min(self.screenWidth * 0.7, self.screenHeight * 0.7)
    local startX = (self.screenWidth - boardSize) / 2
    local startY = (self.screenHeight - boardSize) / 2 + 20
    local cellSize = boardSize / 10

    -- Draw board background
    love.graphics.setColor(1, 0.95, 0.9)
    love.graphics.rectangle("fill", startX, startY, boardSize, boardSize)

    -- Draw grid and numbers
    love.graphics.setColor(0.3, 0.2, 0.1)
    love.graphics.setLineWidth(2)

    for i = 1, 100 do
        local row = math_floor((i - 1) / 10)
        local col = (i - 1) % 10

        -- Reverse direction for even rows (snake pattern)
        if row % 2 == 1 then
            col = 9 - col
        end

        local x = startX + col * cellSize
        local y = startY + (9 - row) * cellSize -- Start from bottom

        -- Draw cell
        love.graphics.setColor(1, 0.98, 0.95)
        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
        love.graphics.setColor(0.8, 0.7, 0.6)
        love.graphics.rectangle("line", x, y, cellSize, cellSize)

        -- Draw number
        love.graphics.setColor(0.4, 0.3, 0.2)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print(i, x + 5, y + 5)
    end
end

function Game:drawSnakesAndLadders()
    local boardSize = math.min(self.screenWidth * 0.7, self.screenHeight * 0.7)
    local startX = (self.screenWidth - boardSize) / 2
    local startY = (self.screenHeight - boardSize) / 2 + 20
    local cellSize = boardSize / 10

    -- Draw ladders
    for _, ladder in ipairs(self.ladders) do
        local fromPos = self:getBoardPosition(ladder.from, startX, startY, boardSize, cellSize)
        local toPos = self:getBoardPosition(ladder.to, startX, startY, boardSize, cellSize)

        love.graphics.setColor(ladder.color)
        love.graphics.setLineWidth(4)
        love.graphics.line(fromPos.x + cellSize/2, fromPos.y + cellSize/2,
                          toPos.x + cellSize/2, toPos.y + cellSize/2)

        -- Draw ladder rungs
        local steps = 5
        for i = 1, steps - 1 do
            local progress = i / steps
            local x = fromPos.x + cellSize/2 + (toPos.x - fromPos.x) * progress
            local y = fromPos.y + cellSize/2 + (toPos.y - fromPos.y) * progress
            love.graphics.setLineWidth(2)
            love.graphics.line(x - 10, y - 5, x + 10, y + 5)
        end
    end

    -- Draw snakes
    for _, snake in ipairs(self.snakes) do
        local fromPos = self:getBoardPosition(snake.from, startX, startY, boardSize, cellSize)
        local toPos = self:getBoardPosition(snake.to, startX, startY, boardSize, cellSize)

        love.graphics.setColor(snake.color)
        love.graphics.setLineWidth(6)

        -- Curved snake body
        local controlX = (fromPos.x + toPos.x) / 2 + 30
        local controlY = (fromPos.y + toPos.y) / 2 - 40

        love.graphics.line(fromPos.x + cellSize/2, fromPos.y + cellSize/2,
                          controlX, controlY,
                          toPos.x + cellSize/2, toPos.y + cellSize/2)

        -- Snake head
        love.graphics.circle("fill", fromPos.x + cellSize/2, fromPos.y + cellSize/2, 8)

        -- Snake eyes
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", fromPos.x + cellSize/2 - 3, fromPos.y + cellSize/2 - 3, 2)
        love.graphics.circle("fill", fromPos.x + cellSize/2 + 3, fromPos.y + cellSize/2 - 3, 2)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", fromPos.x + cellSize/2 - 3, fromPos.y + cellSize/2 - 3, 1)
        love.graphics.circle("fill", fromPos.x + cellSize/2 + 3, fromPos.y + cellSize/2 - 3, 1)
    end

    love.graphics.setLineWidth(1)
end

function Game:drawPlayers()
    local boardSize = math.min(self.screenWidth * 0.7, self.screenHeight * 0.7)
    local startX = (self.screenWidth - boardSize) / 2
    local startY = (self.screenHeight - boardSize) / 2 + 20
    local cellSize = boardSize / 10

    for i, player in ipairs(self.players) do
        local pos = self:getBoardPosition(player.position, startX, startY, boardSize, cellSize)

        -- Animate movement
        if self.moveAnimation and self.animationPlayer == i then
            local startPos = self:getBoardPosition(self.animationStartPos, startX, startY, boardSize, cellSize)
            pos.x = startPos.x + (pos.x - startPos.x) * self.animationProgress
            pos.y = startPos.y + (pos.y - startPos.y) * self.animationProgress
        end

        -- Draw player token
        love.graphics.setColor(player.color)
        love.graphics.circle("fill", pos.x + cellSize/2, pos.y + cellSize/2, cellSize/3)

        -- Player number
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(i, pos.x + cellSize/2 - 4, pos.y + cellSize/2 - 7)

        -- Food emoji token
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.print(player.token, pos.x + cellSize/2 - 10, pos.y + cellSize/2 - 25)
    end
end

function Game:drawUI()
    -- Current player indicator
    love.graphics.setColor(self.players[self.currentPlayer].color)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print(self.players[self.currentPlayer].name .. "'s Turn", 20, 20)

    -- Dice
    local diceX = self.screenWidth - 120
    local diceY = 20
    local diceSize = 80

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", diceX, diceY, diceSize, diceSize, 10)
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("line", diceX, diceY, diceSize, diceSize, 10)

    -- Dice dots
    love.graphics.setColor(0.2, 0.2, 0.2)
    local dotPositions = {
        [1] = {{0.5, 0.5}},
        [2] = {{0.25, 0.25}, {0.75, 0.75}},
        [3] = {{0.25, 0.25}, {0.5, 0.5}, {0.75, 0.75}},
        [4] = {{0.25, 0.25}, {0.75, 0.25}, {0.25, 0.75}, {0.75, 0.75}},
        [5] = {{0.25, 0.25}, {0.75, 0.25}, {0.5, 0.5}, {0.25, 0.75}, {0.75, 0.75}},
        [6] = {{0.25, 0.25}, {0.75, 0.25}, {0.25, 0.5}, {0.75, 0.5}, {0.25, 0.75}, {0.75, 0.75}}
    }

    local dots = dotPositions[self.diceValue] or {}
    for _, dot in ipairs(dots) do
        love.graphics.circle("fill", diceX + dot[1] * diceSize, diceY + dot[2] * diceSize, 5)
    end

    -- Instructions
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("Press SPACE to roll dice", 20, 60)
    love.graphics.print("Press R to restart", 20, 90)
end

function Game:drawGameOver()
    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, self.screenHeight)

    -- Winner message
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf(self.players[self.winner].name .. " Wins!", 0, self.screenHeight/2 - 50, self.screenWidth, "center")

    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Click anywhere to continue", 0, self.screenHeight/2 + 30, self.screenWidth, "center")
end

function Game:getBoardPosition(cellNumber, startX, startY, boardSize, cellSize)
    local row = math_floor((cellNumber - 1) / 10)
    local col = (cellNumber - 1) % 10

    -- Reverse direction for even rows (snake pattern)
    if row % 2 == 1 then
        col = 9 - col
    end

    local x = startX + col * cellSize
    local y = startY + (9 - row) * cellSize

    return {x = x, y = y}
end

function Game:rollDice()
    if self.gameOver or self.diceRolling or self.moveAnimation then return end

    self.diceRolling = true
    self.animationProgress = 0
end

function Game:finishDiceRoll()
    self.diceValue = math_random(1, 6)
    self:moveCurrentPlayer()
end

function Game:moveCurrentPlayer()
    local player = self.players[self.currentPlayer]
    local newPosition = player.position + self.diceValue

    if newPosition > 100 then
        -- Can't move beyond the board
        self:nextTurn()
        return
    end

    self.animationStartPos = player.position
    player.position = newPosition
    self.moveAnimation = true
    self.animationProgress = 0
    self.animationPlayer = self.currentPlayer
end

function Game:checkSnakesAndLadders()
    local player = self.players[self.currentPlayer]
    local message = nil

    -- Check for ladders
    for _, ladder in ipairs(self.ladders) do
        if player.position == ladder.from then
            player.position = ladder.to
            message = player.name .. " climbed " .. ladder.name .. " to " .. ladder.to .. "!"
            break
        end
    end

    -- Check for snakes
    for _, snake in ipairs(self.snakes) do
        if player.position == snake.from then
            player.position = snake.to
            message = player.name .. " slid down " .. snake.name .. " to " .. snake.to .. "!"
            break
        end
    end

    -- Check for win
    if player.position == 100 then
        self.gameOver = true
        self.winner = self.currentPlayer
        return
    end

    self:nextTurn()
end

function Game:nextTurn()
    self.currentPlayer = self.currentPlayer == 1 and 2 or 1
    self.moves = self.moves + 1
end

function Game:handleClick(x, y)
    if self.gameOver then
        return true
    end
    return false
end

function Game:resetGame()
    self:startNewGame()
end

function Game:isGameOver()
    return self.gameOver
end

function Game:setFonts(fonts)
    self.fonts = fonts
end

return Game