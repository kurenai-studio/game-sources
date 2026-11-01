local draw = {}

-- [[const]]
local TILE_SIZE = 32
-- [[const]]
local GRID_X_PADDING = 0
-- [[const]]
local GRID_Y_PADDING = 0


local function nextXPos(xPos)
    return GRID_X_PADDING + (xPos * TILE_SIZE)
end

local function nextYPos(yPos)
    return GRID_Y_PADDING + (yPos * TILE_SIZE)
end

function draw.getTileSize()
    return TILE_SIZE
end

function draw.drawAnimation(configs)
    love.graphics.setColor(configs.colorRGBA.red, configs.colorRGBA.green, configs.colorRGBA.blue)
    love.graphics.draw(configs.spriteSheet, configs.frames, nextXPos(configs.xPos), nextYPos(configs.yPos))
end

function draw.drawText(configs)
    local font = love.graphics.newFont(configs.fontSize)
    love.graphics.setFont(font)
    love.graphics.setColor(configs.colorRGBA.red, configs.colorRGBA.green, configs.colorRGBA.blue)
    love.graphics.print(configs.text, nextXPos(configs.xPos), nextYPos(configs.yPos))
end

function draw.drawImage(configs)
    if configs.imgPath == "" then
        return
    end

    love.graphics.setColor(configs.colorRGBA.red, configs.colorRGBA.green, configs.colorRGBA.blue)
    local img = love.graphics.newImage(configs.imgPath)
    love.graphics.draw(img, nextXPos(configs.xPos), nextYPos(configs.yPos))
end

function draw.drawTile(colorRGBA, xPos, yPos)
    love.graphics.setColor(colorRGBA.red, colorRGBA.green, colorRGBA.blue)
    love.graphics.rectangle("fill", nextXPos(xPos), nextYPos(yPos), TILE_SIZE, TILE_SIZE)
end

function draw.drawBorders(configs)
    love.graphics.setColor(configs.colorRGBA.red, configs.colorRGBA.green, configs.colorRGBA.blue)
    love.graphics.rectangle("line", nextXPos(configs.xPos), nextYPos(configs.yPos), configs.width, configs.height)
end

return draw
