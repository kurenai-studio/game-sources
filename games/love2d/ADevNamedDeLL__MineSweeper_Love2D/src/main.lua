-- Minesweeper Game in Love2D (Lua)

local grid
local cellSize = 40
local numRows = 10
local numCols = 10
local numMines = 15
local gameOver = false
local gameWon = false
local currentState = "menu"  -- Can be "menu", "playing", "gameOver"

-- Initialize buttons
local buttons = {}

function love.load()
    print("Game Loaded!")
    love.window.setTitle("Minesweeper")
    love.window.setMode(numCols * cellSize, numRows * cellSize + 30)  -- Increased window height to fit the text

    -- Create buttons for the menu
    buttons = {
        start = { x = 150, y = 100, width = 100, height = 50, text = "Start", onClick = startGame },
        exit = { x = 150, y = 200, width = 100, height = 50, text = "Exit", onClick = love.event.quit },
        restart = { x = 150, y = 100, width = 100, height = 50, text = "Restart", onClick = restartGame },
        backToMenu = { x = 150, y = 200, width = 100, height = 50, text = "Back to Menu", onClick = backToMenu }
    }

    -- Initialize the grid for the game
    grid = generateGrid(numRows, numCols, numMines)
end

-- Main menu buttons
function love.mousepressed(x, y, button, istouch, presses)
    print("Mouse clicked at:", x, y)
    if currentState == "menu" then
        -- Check if start button is clicked
        if isButtonClicked(buttons.start, x, y) then
            buttons.start.onClick()
        end
        -- Check if exit button is clicked
        if isButtonClicked(buttons.exit, x, y) then
            buttons.exit.onClick()
        end
    elseif currentState == "gameOver" then
        -- Check if restart button is clicked
        if isButtonClicked(buttons.restart, x, y) then
            buttons.restart.onClick()
        end
        -- Check if back to menu button is clicked
        if isButtonClicked(buttons.backToMenu, x, y) then
            buttons.backToMenu.onClick()
        end
    elseif currentState == "playing" then
        -- Handle game clicks (Left click to reveal, Right click to flag)
        local row = math.floor(y / cellSize) + 1
        local col = math.floor(x / cellSize) + 1
        
        if row > numRows or col > numCols then return end
        
        local cell = grid[row][col]
        
        if button == 1 then -- Left click (reveal)
            if cell.isRevealed or cell.isFlagged then return end
            cell.isRevealed = true
            if cell.isMine then
                gameOver = true
                gameWon = false
                currentState = "gameOver"
            elseif cell.surroundingMines == 0 then
                revealEmptyCells(row, col)
            end
            checkWinCondition()
        elseif button == 2 then -- Right click (flag)
            if not cell.isRevealed then
                cell.isFlagged = not cell.isFlagged
            end
        end
    end
end

-- Check if a button is clicked
function isButtonClicked(button, x, y)
    local clicked = x >= button.x and x <= button.x + button.width and y >= button.y and y <= button.y + button.height
    if clicked then
        print(button.text .. " button clicked!")
    end
    return clicked
end

-- Generate the grid with mines and numbers
function generateGrid(rows, cols, mines)
    print("Generating grid...")
    local grid = {}
    
    -- Initialize grid cells
    for r = 1, rows do
        grid[r] = {}
        for c = 1, cols do
            grid[r][c] = {
                isMine = false,
                isRevealed = false,
                isFlagged = false,
                surroundingMines = 0
            }
        end
    end
    
    -- Place mines randomly
    local minesPlaced = 0
    while minesPlaced < mines do
        local r = math.random(1, rows)
        local c = math.random(1, cols)
        if not grid[r][c].isMine then
            grid[r][c].isMine = true
            minesPlaced = minesPlaced + 1
        end
    end
    
    -- Calculate surrounding mines for each cell
    for r = 1, rows do
        for c = 1, cols do
            if not grid[r][c].isMine then
                local count = 0
                for i = -1, 1 do
                    for j = -1, 1 do
                        local nr, nc = r + i, c + j
                        if nr >= 1 and nr <= rows and nc >= 1 and nc <= cols and grid[nr][nc].isMine then
                            count = count + 1
                        end
                    end
                end
                grid[r][c].surroundingMines = count
            end
        end
    end
    
    return grid
end

-- Reveal surrounding empty cells recursively
function revealEmptyCells(r, c)
    for i = -1, 1 do
        for j = -1, 1 do
            local nr, nc = r + i, c + j
            if nr >= 1 and nr <= numRows and nc >= 1 and nc <= numCols then
                local cell = grid[nr][nc]
                if not cell.isRevealed and not cell.isMine then
                    cell.isRevealed = true
                    if cell.surroundingMines == 0 then
                        revealEmptyCells(nr, nc)
                    end
                end
            end
        end
    end
end

-- Check if all non-mine cells are revealed (win condition)
function checkWinCondition()
    local revealedCells = 0
    for r = 1, numRows do
        for c = 1, numCols do
            if grid[r][c].isRevealed and not grid[r][c].isMine then
                revealedCells = revealedCells + 1
            end
        end
    end
    -- If all non-mine cells are revealed, the player wins
    if revealedCells == (numRows * numCols - numMines) then
        gameWon = true
        gameOver = true
        currentState = "gameOver"
    end
end

-- Start a new game
function startGame()
    currentState = "playing"
    gameOver = false
    gameWon = false
    grid = generateGrid(numRows, numCols, numMines)
end

-- Restart the game
function restartGame()
    currentState = "playing"
    gameOver = false
    gameWon = false
    grid = generateGrid(numRows, numCols, numMines)
end

-- Go back to the main menu
function backToMenu()
    currentState = "menu"
end

-- Draw the game screen
function love.draw()
    print("Drawing state:", currentState)
    -- Draw grid based on the current state
    if currentState == "menu" then
        -- Draw the menu screen with buttons
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Minesweeper", 150, 50)
        drawButton(buttons.start)
        drawButton(buttons.exit)
    elseif currentState == "playing" then
        -- Draw the game grid
        for r = 1, numRows do
            for c = 1, numCols do
                local x = (c - 1) * cellSize
                local y = (r - 1) * cellSize
                local cell = grid[r][c]

                -- Draw the cell background
                if cell.isRevealed then
                    if cell.isMine then
                        love.graphics.setColor(1, 0, 0)
                        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
                    else
                        love.graphics.setColor(0.8, 0.8, 0.8)
                        love.graphics.rectangle("fill", x, y, cellSize, cellSize)
                        if cell.surroundingMines > 0 then
                            love.graphics.setColor(0, 0, 0)
                            love.graphics.print(cell.surroundingMines, x + 12, y + 12)
                        end
                    end
                else
                    love.graphics.setColor(0.6, 0.6, 0.6)
                    love.graphics.rectangle("fill", x, y, cellSize, cellSize)
                end

                -- Draw flag icon if flagged
                if cell.isFlagged then
                    love.graphics.setColor(0, 0, 1)
                    love.graphics.print("F", x + 12, y + 12)
                end

                -- Draw grid lines
                love.graphics.setColor(0, 0, 0)
                love.graphics.rectangle("line", x, y, cellSize, cellSize)
            end
        end
    elseif currentState == "gameOver" then
        -- Draw the Game Over screen
        love.graphics.setColor(1, 0, 0)
        love.graphics.print(gameWon and "You Win!" or "Game Over", 150, 50)
        drawButton(buttons.restart)
        drawButton(buttons.backToMenu)
    end

    -- Draw persistent "Made By" text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Made By ADevNamedDeLL", 10, love.graphics.getHeight() - 30)
end

-- Draw buttons
function drawButton(button)
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(button.text, button.x + 10, button.y + 15)
end
