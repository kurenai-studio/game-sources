-- modules
local drawmodule = require('modules.draw')
local colormodule = require('modules.color')

local log = {
    ID = "log"
}

local displayedText = "Have fun!"

local logRGBA = colormodule.getColorRGBA(colormodule.Types.WHITE)

function log.updateLog(text)
    displayedText = text
end

function log.render()
    drawmodule.drawText {
        colorRGBA = logRGBA,
        text = "Game log",
        fontSize = 28,
        xPos = 44,
        yPos = 21
    }
    drawmodule.drawText {
        colorRGBA = logRGBA,
        text = displayedText,
        fontSize = 18,
        xPos = 44,
        yPos = 22.5
    }
end

return log
