-- modules
local drawmodule = require('modules.draw')
local colormodule = require('modules.color')

-- core
local roguecore = require("core.rogue")

local player = {
    ID = "player"
}

function player.render()
    local frameIndex = math.floor(roguecore.currentPlayer.currentTime / roguecore.currentPlayer.duration * #roguecore.currentPlayer.frames) + 1

    drawmodule.drawAnimation{
        colorRGBA = colormodule.getColorRGBA(colormodule.Types.WHITE),
        spriteSheet = roguecore.currentPlayer.idleSheet,
        frames = roguecore.currentPlayer.frames[frameIndex],
        xPos = roguecore.currentPlayer.xPos,
        yPos = roguecore.currentPlayer.yPos
    }
end

return player
