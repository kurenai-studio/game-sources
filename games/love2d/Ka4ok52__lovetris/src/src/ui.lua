local drawText = require('drawText')
local drawGameContent = {}

local PALETTE = {
    {0, 1, 1},       -- I
    {0.1, 0.1, 0.9}, -- J
    {1, 0.5, 0},     -- L
    {1, 1, 0.1},     -- O
    {0.1, 1, 0.1},   -- S
    {0.5, 0.1, 0.9}, -- T
    {1, 0.1, 0.1}    -- Z
}
local CELL_SIZE = 30
local OFFSET_X = 250
local OFFSET_Y = 80
local UI_X = 570
local HOLD_X = 90

function drawGameContent.draw(grid, currentShape, currentShapeId, curX, curY, pieceQueue, holdShapeId, canHold, score, TETRAMINO, pulseShader, GRID_WIDTH, GRID_HEIGHT, fonts)
-- CUP    
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", OFFSET_X, OFFSET_Y, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)

    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            local drawX = (x-1) * CELL_SIZE + OFFSET_X
            local drawY = (y-1) * CELL_SIZE + OFFSET_Y

            if grid[y][x] ~= 0 then
                local c = PALETTE[grid[y][x]]
                love.graphics.setColor(c)
                love.graphics.rectangle("fill", drawX, drawY, CELL_SIZE, CELL_SIZE)
            else
                love.graphics.setColor(0.10, 0.10, 0.10)
                love.graphics.rectangle("line", drawX, drawY, CELL_SIZE, CELL_SIZE)
            end
        end
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setLineWidth(4)
    love.graphics.rectangle("line", OFFSET_X - 2, OFFSET_Y - 2, GRID_WIDTH * CELL_SIZE + 4, GRID_HEIGHT * CELL_SIZE + 4)
    love.graphics.setLineWidth(2)

-- Tetramino
    if currentShape then
        local cc = PALETTE[currentShapeId]
        love.graphics.setColor(cc)
        love.graphics.setShader(pulseShader)
        for y = 1, #currentShape do
            for x = 1, #currentShape[y] do
                if currentShape[y][x] ~= 0 then
                    local drawX = (curX + x - 2) * CELL_SIZE + OFFSET_X
                    local drawY = (curY + y - 2) * CELL_SIZE + OFFSET_Y
                    love.graphics.rectangle("fill", drawX, drawY, CELL_SIZE, CELL_SIZE)
                end
            end
        end
        love.graphics.setShader()
    end

-- HOLD
    drawText{ text = "HOLD", x = HOLD_X, y = OFFSET_Y - 35, font = fonts.ui, color = {1, 1, 1}, width = 140, align = "center" }

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", HOLD_X, OFFSET_Y, 140, 140)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", HOLD_X, OFFSET_Y, 140, 140)

    if holdShapeId then
        local hShape = TETRAMINO[holdShapeId]
        local hColor = PALETTE[holdShapeId]
        if canHold then love.graphics.setColor(hColor) else love.graphics.setColor(0.4, 0.4, 0.4) end

        local holdCell = 24
        local startX = HOLD_X + (140 - #hShape * holdCell) / 2
        local startY = OFFSET_Y + (140 - #hShape * holdCell) / 2

        for r = 1, #hShape do
            for c = 1, #hShape[r] do
                if hShape[r][c] ~= 0 then
                    love.graphics.rectangle("fill", startX + (c-1)*holdCell, startY + (r-1)*holdCell, holdCell, holdCell)
                    love.graphics.rectangle("line", startX + (c-1)*holdCell, startY + (r-1)*holdCell, holdCell, holdCell)
                    if canHold then love.graphics.setColor(hColor) else love.graphics.setColor(0.4, 0.4, 0.4) end
                end
            end
        end
    end

-- NEXT and SCORE
    drawText{ text = "NEXT", x = UI_X, y = OFFSET_Y - 35, font = fonts.ui, color = {1, 1, 1}, width = 140, align = "center" }

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", UI_X, OFFSET_Y, 140, 340)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("line", UI_X, OFFSET_Y, 140, 340)

    for i = 1, #pieceQueue do
        local pid = pieceQueue[i]
        local ps = TETRAMINO[pid]
        local pc = PALETTE[pid]

        local slotY = OFFSET_Y + (i-1) * 85
        local nextCell = 18

        local dxStart = UI_X + (140 - #ps * nextCell) / 2
        local dyStart = slotY + (85 - #ps * nextCell) / 2

        love.graphics.setColor(pc)
        for r = 1, #ps do
            for c = 1, #ps[r] do
                if ps[r][c] ~= 0 then
                    love.graphics.rectangle("fill", dxStart + (c-1)*nextCell, dyStart + (r-1)*nextCell, nextCell, nextCell)
                    love.graphics.rectangle("line", dxStart + (c-1)*nextCell, dyStart + (r-1)*nextCell, nextCell, nextCell)
                    love.graphics.setColor(pc)
                end
            end
        end
    end

    drawText{ text = "SCORE", x = UI_X, y = OFFSET_Y + 360, font = fonts.ui, color = {1, 1, 1}, width = 140, align = "center" }
    drawText{ text = string.format("%05d", score), x = UI_X, y = OFFSET_Y + 395, font = fonts.ui, color = {1, 1, 1}, width = 140, align = "center" }
end

return drawGameContent
