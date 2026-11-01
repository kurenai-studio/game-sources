local img = {}

local basePath = "assets/"

function img.getKeys()
    return {
        BOSS = img.getBoss(),
        CHEST = img.getChest(),
        MINION = img.getMinion(),
        HEALTH = img.getHealth(),
        PLAYER = img.getPlayer(),
        SCROLL = img.getScroll()
    }
end
function img.getBoss()
    return basePath .. "boss.png"
end

function img.getChest()
    return basePath .. "chest.png"
end

function img.getMinion()
    return basePath .. "minion.png"
end

function img.getHealth()
    return basePath .. "heart.png"
end

function img.getPlayer()
    return basePath .. "player.png"
end

function img.getPlayerIdle()
    return basePath .. "player_idle.png"
end

function img.getScroll()
    return basePath .. "scroll.png"
end

return img
