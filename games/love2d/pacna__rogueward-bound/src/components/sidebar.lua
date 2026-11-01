-- modules
local colormodule = require('modules.color')
local drawmodule = require('modules.draw')
local imgmodule = require("modules.img")

-- core
local roguecore = require("core.rogue")

-- components
local logcomponent = require('components.log')
local statscomponent = require('components.stats')

local sidebar = {
    ID = "sidebar"
}

local keyRGBA = colormodule.getColorRGBA(colormodule.Types.WHITE)

local function drawKeys()
    local imgXPosition = roguecore.getRow() + 4
    local textXPosition = roguecore.getRow() + 5.5

    local imgYInitPosition = 3.5
    local textYInitPosition = 3.7

    drawmodule.drawText {
        colorRGBA = keyRGBA,
        text = "Key",
        fontSize = 28,
        xPos = imgXPosition,
        yPos = 1.5
    }

    for header, src in pairs(imgmodule.getKeys()) do
        drawmodule.drawImage {
            colorRGBA = keyRGBA,
            imgPath = src,
            xPos = imgXPosition,
            yPos = imgYInitPosition
        }
        drawmodule.drawText {
            colorRGBA = keyRGBA,
            text = header,
            fontSize = 18,
            xPos = textXPosition,
            yPos = textYInitPosition
        }

        imgYInitPosition = imgYInitPosition + 1.75
        textYInitPosition = textYInitPosition + 1.75
    end
end

function sidebar.render()
    drawmodule.drawBorders {
        colorRGBA = colormodule.getColorRGBA(colormodule.Types.RED),
        xPos = 42,
        yPos = 1,
        width = 360 + drawmodule.getTileSize(),
        height = drawmodule.getTileSize() * roguecore.getColumn()
    }

    drawKeys()
    statscomponent.render()
    logcomponent.render()
end

return sidebar
