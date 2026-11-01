-- core
local entitycore = require("core.entity")
local roguecore = require('core.rogue')

-- factories
local publisher = require('factories.messagebus.publisher')

local brawl = {
    Key = "brawl"
}

local function battle(participants, xPos, yPos)
    local enemyRemainingHealth = participants.enemy.health - participants.player.atk

    if enemyRemainingHealth > 0 then
        roguecore.map[xPos][yPos].health = enemyRemainingHealth
        -- Seems like the enemy can take a hit. Now it's the player's turn :(
        participants.player:subtractHealth(participants.enemy.atk)
        publisher.send(publisher.Types.LOG,
            { type = participants.enemy.type, health = enemyRemainingHealth, atk = participants.enemy.atk, xp = 0 })
    end

    if participants.player.health <= 0 then
        publisher.send(publisher.Types.LOG, {})
        publisher.send(publisher.Types.DONE, {})
        return
    end

    if enemyRemainingHealth <= 0 then
        roguecore.map[xPos][yPos] = entitycore.create(entitycore.Types.FLOOR)
        participants.player:setPos { x = xPos, y = yPos }
        participants.player:addXP(participants.enemy.xp)
        publisher.send(publisher.Types.LOG,
            { type = participants.enemy.type, health = 0, atk = 0, xp = participants.enemy.xp })

        if participants.enemy.type == entitycore.Types.BOSS then
            publisher.send(publisher.Types.LOG, {})
            publisher.send(publisher.Types.DONE, {})
            return
        end
    end

end

function brawl.handleMessage(msg)
    if msg.key ~= brawl.Key then
        return
    end

    -- if the player is dead then do nothing
    if roguecore.currentPlayer.health <= 0 then
        return
    end

    local xPos = msg.value.xPos
    local yPos = msg.value.yPos
    local enemy = roguecore.map[xPos][yPos]

    battle({ enemy = enemy, player = roguecore.currentPlayer }, xPos, yPos)
end

return brawl
