-- modules
local imgmodule = require("modules.img")

local entity = {}

--[[const]]
entity.Types = {
    WALL = 1,
    FLOOR = 2,
    MINION = 3,
    BOSS = 4,
    HEALTH = 5,
    WEAPON = 6,
    PLAYER = 7,
    SCROLL = 8
}

local function createWall()
    return { type = entity.Types.WALL, health = 0, xp = 0, atk = 0, imgSrc = "", idleSheet = nil }
end

local function createFloor()
    return { type = entity.Types.FLOOR, health = 0, xp = 0, atk = 0, imgSrc = "", idleSheet = nil }
end

local function createMinion()
    return { type = entity.Types.MINION, health = 10, xp = 1, atk = 1, imgSrc = imgmodule.getMinion(), idleSheet = nil }
end

local function createBoss()
    return { type = entity.Types.BOSS, health = 50, xp = 100, atk = 5, imgSrc = imgmodule.getBoss(), idleSheet = nil }
end

local function createHealth()
    return { type = entity.Types.HEALTH, health = 10, xp = 0, atk = 0, imgSrc = imgmodule.getHealth(), idleSheet = nil }
end

local function createChest()
    return { type = entity.Types.WEAPON, health = 0, xp = 0, atk = 10, imgSrc = imgmodule.getChest(), idleSheet = nil }
end

local function createPlayer()
    return { type = entity.Types.PLAYER, health = 30, xp = 0, atk = 5, imgSrc = imgmodule.getPlayer(), idleSheet = love.graphics.newImage(imgmodule.getPlayerIdle()) }
end

local function createScroll()
    return { type = entity.Types.SCROLL, health = 0, xp = 5, atk = 0, imgSrc = imgmodule.getScroll(), idleSheet = nil }
end

function entity.create(type)
    if type == entity.Types.WALL then
        return createWall()
    end

    if type == entity.Types.FLOOR then
        return createFloor()
    end

    if type == entity.Types.MINION then
        return createMinion()
    end

    if type == entity.Types.BOSS then
        return createBoss()
    end

    if type == entity.Types.HEALTH then
        return createHealth()
    end

    if type == entity.Types.WEAPON then
        return createChest()
    end

    if type == entity.Types.PLAYER then
        return createPlayer()
    end

    if type == entity.Types.SCROLL then
        return createScroll()
    end
end

return entity
