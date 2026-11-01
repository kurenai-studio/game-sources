-- modules
local drawmodule = require('modules.draw')
local colormodule = require('modules.color')

-- core
local roguecore = require("core.rogue")

local stats = {
    ID = "stats"
}

local statsRGBA = colormodule.getColorRGBA(colormodule.Types.WHITE)

function stats.render()
    drawmodule.drawText {
        colorRGBA = statsRGBA,
        text = "Player Stats",
        fontSize = 28,
        xPos = 44,
        yPos = 15
    }

    local playerStats = {
        {label = "HP", value = roguecore.currentPlayer.health},
        {label = "XP", value = roguecore.currentPlayer.xp},
        {label = "Atk", value = roguecore.currentPlayer.atk}
    }

    for i, stat in ipairs(playerStats) do
        drawmodule.drawText {
            colorRGBA = statsRGBA,
            text = stat.label .. ": " .. stat.value,
            fontSize = 18,
            xPos = 44,
            yPos = 16 + i
        }
    end
end

return stats
