local grid = require('src.grid')
local config = require('src.config')
local colors = require('src.colors')

local state = setmetatable({}, { __index = config })

function love.load()
    state.windowDimensions = {
        love.graphics.getWidth(),
        love.graphics.getHeight()
    }
    state.currentGrid = grid.createGrid(
        state.windowDimensions,
        state.cellSize,
        config.toroidalGrid
    )
end

function love.mousefocus(focus)
    if not focus then
        state.selectedCell = nil
    end
end

function love.mousemoved(x, y)
    state.mousePos = {x, y}
    state.selectedCell = grid.updateSelectedCell(
        state.currentGrid,
        state.mousePos
    )
end

function love.keypressed(key)
    if key == state.pauseKey then
        state.paused = not state.paused
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if state.useTurns then
        if button ~= state.placeKey or not state.paused then return end
        if grid.spawnCell(
            state.selectedCell,
            state.turn
        )
        then
            state.turn = (state.turn % 2) + 1
        end
    else
        if button ~= 1 and button ~= 2 or not state.paused then return end
        grid.spawnCell(
            state.selectedCell,
            button
        )
    end
end

function love.draw()
    love.graphics.clear(state.backgroundColor)
    grid.drawCells(
        state.currentGrid,
        state.player1Color,
        state.player2Color
    )
    grid.drawGrid(
        state.currentGrid,
        state.gridColor,
        state.gridLineWidth
    )
    grid.drawMouseSelection(
        state.currentGrid,
        state.selectedCell,
        state.gridActiveColor,
        state.gridLineWidth
    )
end

local updateTimer = 0
function love.update(dt)
    updateTimer = updateTimer + dt
    if not state.paused and updateTimer >= state.updateInterval then
        grid.updateGrid(state.currentGrid)
        updateTimer = 0
    end
end