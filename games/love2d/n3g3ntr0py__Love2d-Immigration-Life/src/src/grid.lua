local function bindToGrid(grid, pos)
    local row = math.ceil(pos[2] / grid.cellSize)
    local column = math.ceil(pos[1] / grid.cellSize)

    return grid[row][column]
end

return {
    createGrid = function(windowDimensions, cellSize, toroidal)
        local cellAmountX = windowDimensions[1] / cellSize
        local cellAmountY = windowDimensions[2] / cellSize

        local grid = {}
        grid.cellSize = cellSize
        grid.toroidal = toroidal

        for row = 1, cellAmountY do
            grid[row] = {}
            for column = 1, cellAmountX do
                local x = (column - 1) * cellSize
                local y = (row - 1) * cellSize
                -- basically 0 is dead 1 and 2 are different teams
                local state = 0
                grid[row][column] = {x, y, state}
            end
        end

        return grid
    end,

    drawGrid = function(grid, color, lineWidth)
        love.graphics.setColor(color)
        love.graphics.setLineWidth(lineWidth)

        for row = 1, #grid do
            for column = 1, #grid[row] do
                love.graphics.rectangle(
                    'line',
                    grid[row][column][1],
                    grid[row][column][2],
                    grid.cellSize, grid.cellSize
                )
            end
        end
    end,

    drawMouseSelection = function(grid, selectedCell, color, lineWidth)
        if not selectedCell then
            return
        end
        love.graphics.setColor(color)
        love.graphics.setLineWidth(lineWidth)
        love.graphics.rectangle(
            'line',
            selectedCell[1],
            selectedCell[2],
            grid.cellSize, grid.cellSize
        )
    end,

    drawCells = function(grid, team1Color, team2Color)
        for row = 1, #grid do
            for column = 1, #grid[row] do
                if grid[row][column][3] ~= 0 then
                    if grid[row][column][3] == 1 then
                        love.graphics.setColor(team1Color)
                    elseif grid[row][column][3] == 2 then
                        love.graphics.setColor(team2Color)
                    end
                    love.graphics.rectangle(
                        'fill',
                        grid[row][column][1],
                        grid[row][column][2],
                        grid.cellSize, grid.cellSize
                    )
                end
            end
        end
    end,

    updateSelectedCell = function(grid, mousePos)
        local gridSizeX = #grid[1] * grid.cellSize
        local gridSizeY = #grid * grid.cellSize
        if
            not mousePos or
            mousePos[1] < 1 or
            mousePos[1] > gridSizeX or
            mousePos[2] < 1 or
            mousePos[2] > gridSizeY
        then return nil end
        return bindToGrid(grid, mousePos)
    end,

    spawnCell = function(cell, state)
        if not cell then return end
        if cell[3] ~= 0 then return nil end
        cell[3] = state
        return true
    end,

    updateGrid = function(grid)
        local futureGrid = {}

        for row = 1, #grid do
            futureGrid[row] = {}
            for column = 1, #grid[1] do
                futureGrid[row][column] = {}
                local aliveNeighbours = {0, 0}
                for neighbourRow = row - 1, row + 1 do
                    for neighbourColumn = column -1, column + 1 do
                        if not grid.toroidal then
                            if
                                grid[neighbourRow] and
                                grid[neighbourRow][neighbourColumn] and
                                grid[neighbourRow][neighbourColumn] ~= grid[row][column] and
                                grid[neighbourRow][neighbourColumn][3] == 1
                            then
                                aliveNeighbours[1] = aliveNeighbours[1] + 1
                            elseif
                                grid[neighbourRow] and
                                grid[neighbourRow][neighbourColumn] and
                                grid[neighbourRow][neighbourColumn] ~= grid[row][column] and
                                grid[neighbourRow][neighbourColumn][3] == 2
                            then
                                aliveNeighbours[2] = aliveNeighbours[2] + 1
                            end
                        else
                            if
                                grid[(neighbourRow - 1) % #grid + 1][(neighbourColumn - 1) % #grid[1] + 1] ~= grid[row][column] and
                                grid[(neighbourRow - 1) % #grid + 1][(neighbourColumn - 1) % #grid[1] + 1][3] == 1
                            then
                                aliveNeighbours[1] = aliveNeighbours[1] + 1
                            elseif
                                grid[(neighbourRow - 1) % #grid + 1][(neighbourColumn - 1) % #grid[1] + 1] ~= grid[row][column] and
                                grid[(neighbourRow - 1) % #grid + 1][(neighbourColumn - 1) % #grid[1] + 1][3] == 2
                            then
                                aliveNeighbours[2] = aliveNeighbours[2] + 1
                            end
                        end
                    end
                end
                local newState = 0
                local totalNeighbours = aliveNeighbours[1] + aliveNeighbours[2]
                if grid[row][column][3] == 0 then
                    if totalNeighbours == 3 then
                        if aliveNeighbours[1] > aliveNeighbours[2] then
                            newState = 1
                        elseif aliveNeighbours[2] > aliveNeighbours[1] then
                            newState = 2
                        end
                    end
                elseif totalNeighbours == 2 or totalNeighbours == 3 then
                    newState = grid[row][column][3]
                else
                    newState = 0
                end
                futureGrid[row][column][3] = newState
            end
        end

        for row = 1, #grid do
            for column = 1, #grid[1] do
                grid[row][column][3] = futureGrid[row][column][3]
            end
        end
    end
}