-- core
local entitycore = require("core.entity")

-- entities
local Player = require("entities.player")

-- modules
local randommodule = require('modules.random')

local rogue = {}
rogue.currentPlayer = {}
rogue.map = {}

--[[const]]
local ROW = 40
--[[const]]
local COLUMN = 30

local takenXPositions = {}
local takenYPositions = {}

local function loadMap()
    for i = 1, ROW do
        rogue.map[i] = {}
        for j = 1, COLUMN do
            local seed = math.random(1, 5)
            if seed == entitycore.Types.WALL then
                rogue.map[i][j] = entitycore.create(entitycore.Types.WALL)
            else
                rogue.map[i][j] = entitycore.create(entitycore.Types.FLOOR)
            end
        end
    end
end

local function addEntitiesToMap(maxNumberOfEntities, entityType)
    for _ = 1, maxNumberOfEntities do
        local availableXPos = randommodule.generate(1, ROW, takenXPositions)
        local availableYPos = randommodule.generate(1, COLUMN, takenYPositions)
        rogue.map[availableXPos][availableYPos] = entitycore.create(entityType)
        table.insert(takenXPositions, availableXPos)
        table.insert(takenYPositions, availableYPos)
    end

end

local function loadEntities()
    addEntitiesToMap(5, entitycore.Types.MINION)
    addEntitiesToMap(5, entitycore.Types.HEALTH)
    addEntitiesToMap(5, entitycore.Types.WEAPON)
    addEntitiesToMap(1, entitycore.Types.BOSS)
    addEntitiesToMap(1, entitycore.Types.SCROLL)
end

local function loadPlayer()
    local availableXPos = randommodule.generate(1, ROW, takenXPositions)
    local availableYPos = randommodule.generate(1, COLUMN, takenYPositions)
    rogue.map[availableXPos][availableYPos] = entitycore.create(entitycore.Types.FLOOR)

    local player = entitycore.create(entitycore.Types.PLAYER)
    rogue.currentPlayer = Player:new {
        xPos = availableXPos,
        yPos = availableYPos,
        health = player.health,
        xp = player.xp,
        atk = player.atk,
        imgSrc = player.imgSrc,
        idleSheet = player.idleSheet
    }
end

local function isValidXPos(xPos)
    return xPos ~= 0 and xPos <= ROW
end

local function isValidYPos(yPos)
    return yPos ~= 0 and yPos <= COLUMN
end

function rogue.isWithinMap(dx, dy)
    return isValidXPos(dx) and isValidYPos(dy)
end

function rogue.getRow()
    return ROW
end

function rogue.getColumn()
    return COLUMN
end

function rogue.loadWorld()
    loadMap()
    loadEntities()
    loadPlayer()
end

return rogue
