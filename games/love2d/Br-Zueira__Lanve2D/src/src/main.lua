-- Main.lua
local client = require 'modules.client'
local server = require 'modules.server'
local Player = require 'modules.player'
local bullet = require 'modules.bullet'

IsServer = false

local selfPlayer = {}

local playerList = {}

local cameraX, cameraY = 0, 0

function love.load(args)
    -- Decides whether the game instance will be a server or a client
    if args[1] == "server" then
        IsServer = true
        love.window.setTitle("Lanve2D: Server")
    else
        love.window.setTitle("Lanve2D: Client")
    end

    -- Physics setup
    if IsServer then
        love.physics.setMeter(32)
        World = love.physics.newWorld(0, 0, true)

        local function preSolve(fixtureA, fixtureB, contact)
            local a = fixtureA:getUserData()
            local b = fixtureB:getUserData()

            if not a or not b then return end

            local bullet, player

            if a.type == "bullet" and b.type == "player" then
                bullet, player = a, b
            elseif b.type == "bullet" and a.type == "player" then
                bullet, player = b, a
            end

            if bullet and player then
                if bullet.shooterID == player.id then
                    contact:setEnabled(false)
                end
            end
        end

        World:setCallbacks(nil, nil, preSolve)
    end

    -- Creates the game instance player
    selfPlayer = Player.new(0, 0, 0)
end

function love.update(dt)
    VW, VH = love.graphics.getDimensions()

    -- Captures every input
    local inputs = {}

    if love.keyboard.isDown('w') then table.insert(inputs, 'w') end
    if love.keyboard.isDown('a') then table.insert(inputs, 'a') end
    if love.keyboard.isDown('s') then table.insert(inputs, 's') end
    if love.keyboard.isDown('d') then table.insert(inputs, 'd') end

    if love.mouse.isDown(1) then
        local mouseX, mouseY = love.mouse.getPosition()
        table.insert(inputs, "aim:" .. mouseX - VW/2 .. ":" .. mouseY - VH/2)
    end

    -- Updates itself first
    selfPlayer:update(dt, inputs, server.eventListener)

    -- Updates players (the way of doing it depends if its the host or a client)
    if IsServer then
        playerList = server.serverUpdate(selfPlayer, dt)

        -- Updates physics
        World:update(dt)
    else
        playerList = client.clientUpdate(selfPlayer, inputs, dt)
    end

    for _, bullet in ipairs(bullet.bulletList) do
        bullet:update(dt)
    end

    -- Camera coordinates
    cameraX = selfPlayer.x - VW / 2
    cameraY = selfPlayer.y - VH / 2
end

function love.draw()
    -- Resets color
    love.graphics.setColor(0.0, 0.0, 0.0, 1.0)

    -- Different ways of accessing the player:draw function depending if its server or client
    if IsServer then
        selfPlayer:draw(cameraX, cameraY)
        for _, client in pairs(playerList) do
            client.player:draw(cameraX, cameraY)
        end
    else
        for _, player in pairs(playerList) do
            player:draw(cameraX, cameraY)
        end
        client.selectServerUI()
    end

    for _, b in pairs(bullet.bulletList) do
        b:draw(cameraX, cameraY)
    end
end