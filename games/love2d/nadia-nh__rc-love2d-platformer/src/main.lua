-- main.lua — entry point for the game

-- Require the game modules
local player = require("player")
local platforms = require("platforms")
local coins = require("coins")

-- Physics/gameplay constants
local gravity = 700       -- downward acceleration
local jumpStrength = 400
local OUT_OF_BOUNDS_Y

-- Images will be stored here after loading
local images = {}

-- Sizes of assets (filled in after loading images)
local platformWidth
local platformHeight
local coinWidth
local coinHeight

function love.load()
    -- Set window title and size
    love.window.setTitle("RC Love2D Platformer")
    love.window.setMode(800, 450)
    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Player falls this far below the screen before respawning
    OUT_OF_BOUNDS_Y = windowHeight + 100

    -- Load images from the assets folder
    images.playerImg   = love.graphics.newImage("assets/player.png")
    images.platformImg = love.graphics.newImage("assets/platform.png")
    images.coinImg     = love.graphics.newImage("assets/coin.png")

    -- Store image sizes for positioning objects later
    platformWidth  = images.platformImg:getWidth()
    platformHeight = images.platformImg:getHeight()
    coinWidth      = images.coinImg:getWidth()
    coinHeight     = images.coinImg:getHeight()

    -- Initialize modules with loaded images
    player.load(images)
    coins.load(images)
    platforms.load(images)

    -- Create ground and floating platforms with coins
    initializePlatforms()
end

-- Set up ground platforms plus groups of floating platforms and coins
function initializePlatforms()
    local groundY = 380

    for i = 1, 3 do
        platforms.addPlatform(platformWidth * (i - 1), groundY)
    end

    local floatingStartX = platformWidth * 3 + 30
    local floatingStartY = groundY - 80
    addFloatingPlatforms(floatingStartX, floatingStartY, 3, true)

    floatingStartX = floatingStartX + platformWidth * 3 + 40
    floatingStartY = floatingStartY - 60
    addFloatingPlatforms(floatingStartX, floatingStartY, 4, true)

    floatingStartX = floatingStartX + platformWidth * 4 + 50
    floatingStartY = floatingStartY + 100
    addFloatingPlatforms(floatingStartX, floatingStartY, 1, false)

    floatingStartX = floatingStartX + platformWidth + 60
    floatingStartY = floatingStartY - 70
    addFloatingPlatforms(floatingStartX, floatingStartY, 2, true)
end

-- Helper method to add a row of floating platforms, with optional coins on them
function addFloatingPlatforms(startX, startY, count, addCoins)
    for i = 1, count do
        platforms.addPlatform(
            startX + platformWidth * (i - 1),
            startY
        )

        if addCoins then
            coins.addCoin(
                startX + platformWidth * (i - 1) + (platformWidth - coinWidth) / 3,
                startY - coinHeight
            )
        end
    end
end

function love.update(dt)
    -- Save previous player Y for collision resolution
    local previousY = player.y

    -- Move player and apply gravity
    player.update(dt, gravity)

    -- Check for collisions with platforms and resolve landing
    platforms.resolveCollisions(player, previousY)
    platforms.update(dt)

    -- Check if player touches any coins
    coins.handleCollection(player)
    coins.update(dt)

    -- If player has fallen too far, respawn and reset coins
    if player.y > OUT_OF_BOUNDS_Y then
        player.respawn()
        coins.reset()
    end
end

function love.keypressed(key)
    if key == "up" or key == "w" then
        player.jump(jumpStrength)
    end

    if key == "escape" then
        love.event.quit()
    end
end

function love.draw()
    drawBackground()
    platforms.draw()
    coins.draw()
    player.draw()
    drawUIText()
end

-- Clear screen with a sky blue color
function drawBackground()
    love.graphics.clear(0.4, 0.7, 1.0)
end

-- Draw simple UI text for coins and controls
function drawUIText()
    love.graphics.print("Coins: " .. coins.getCount(), 10, 10)
    love.graphics.print("Arrows or a/d to move, Up or w to jump, Esc to quit", 10, 30)
end
