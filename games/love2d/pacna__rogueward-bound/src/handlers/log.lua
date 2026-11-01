-- components
local logcomponent = require('components.log')

-- core
local roguecore = require('core.rogue')
local entitycore = require('core.entity')

local log = {
    Key = "log"
}

local function isEnemy(type)
    return (type == entitycore.Types.MINION or type == entitycore.Types.BOSS)
end

function log.handleMessage(msg)
    if msg.key ~= log.Key then
        return
    end

    local currentPlayer = roguecore.currentPlayer
    if not next(msg.value) then
        if currentPlayer.health > 0 then
            logcomponent.updateLog("You won!")
            return
        end

        logcomponent.updateLog("Game over")
        return
    end

    local logContent = msg.value

    if isEnemy(logContent.type) then
        if logContent.xp ~= 0 then
            logcomponent.updateLog(string.format("Enemy is dead. Player gain +%d xp", logContent.xp))
            return
        end

        logcomponent.updateLog(string.format("Player took %d damage. \n\nEnemy has %d health left", logContent.atk,
            logContent.health))
        return
    end
    if logContent.type == entitycore.Types.SCROLL then
        logcomponent.updateLog("Player found the secret scroll!")
        return
    end

    if logContent.type == entitycore.Types.HEALTH then
        logcomponent.updateLog(string.format("Player gain +%d health", logContent.health))
        return
    end

    if logContent.type == entitycore.Types.WEAPON then
        logcomponent.updateLog(string.format("Player gain +%d atk", logContent.atk))
        return
    end
end

return log
