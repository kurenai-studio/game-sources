-- coins.lua
-- Manages coin placement, collection, and rendering

local coins = {}

local coinImg
local coinWidth
local coinHeight
local coinCount = 0

function coins.load(images)
    -- Load coin sprite and get the image size
    coinImg = images.coinImg
    coinWidth = coinImg:getWidth()
    coinHeight = coinImg:getHeight()
end

-- Add a coin at a given world position
function coins.addCoin(x, y)
    table.insert(coins, {
        x = x,
        y = y,
        w = coinWidth,
        h = coinHeight,
        collected = false
    })
end

-- Placeholder in case we add animations or effects later
function coins.update(dt)
end

-- Check for player/coin overlap and collect coins
function coins.handleCollection(player)
    for _, coin in ipairs(coins) do
        if not coin.collected and isColliding(player, coin) then
            coin.collected = true
            coinCount = coinCount + 1
        end
    end
end

function coins.getCount()
    return coinCount
end

-- Reset all coins to uncollected state
function coins.reset()
    for _, coin in ipairs(coins) do
        coin.collected = false
    end
    coinCount = 0
end

function coins.draw()
    for _, coin in ipairs(coins) do
        if not coin.collected then
            love.graphics.draw(coinImg, coin.x, coin.y)
        end
    end
end

-- Axis-Aligned Bounding Box (AABB) collision check
function isColliding(obj1, obj2)
    local x1 = obj1.x
    local y1 = obj1.y
    local w1 = obj1.w
    local h1 = obj1.h
    local x2 = obj2.x
    local y2 = obj2.y
    local w2 = obj2.w
    local h2 = obj2.h
    
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

return coins
