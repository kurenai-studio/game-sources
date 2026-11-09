-- Server.lua
local Player = require "modules.player"
local enet = require "enet"
local socket = require "socket"

local Server = {}

-- Opens a connection as host
local host = enet.host_create("*:6789")

-- List of connected clients (doesnt include itself)
local playerList = {}
local nextId = 1

-- Socket for LAN discovering
local udp = socket.udp4()
udp:setsockname("*", 6788)
udp:settimeout(0)

function Server.serverUpdate(selfPlayer, dt)
    while true do
        -- If a device pings for a game LAN discover, responds it
        local message, ip, port = udp:receivefrom()

        if not message then break end

        if message == "LANVE2D_DISCOVER" then
            udp:sendto("LANVE2D_HOST", ip, port)
        end
    end

    -- Captures network events
    local event = host:service(0)
    while event do
        -- If its a message
        if event.type == "receive" then
            -- If the message is a input update, stores it to later update players
            local inputStr = event.data:match("^input:(.*)$")
            if inputStr then
                local inputList = {}
                for input in inputStr:gmatch("%S+") do
                    table.insert(inputList, input)
                end
                playerList[event.peer].inputs = inputList
            end

        -- If its a client that connected
        elseif event.type == "connect" then
            -- Sent them their id in the match
            event.peer:send("your_id:" .. nextId)

            -- Creates a new player on server that represents the new client
            local newPlayer =  Player.new(0, 0, nextId, {1.0, 0.0, 0.0, 1.0})

            -- Stores the new player
            playerList[event.peer] = { id=nextId, player=newPlayer, inputs={} }
            nextId = nextId + 1

        -- If its a client that disconnected
        elseif event.type == "disconnect" then
            -- Gets the player that represents the disconnected client and eliminates it from playerList
            -- And tells clients to do the same
            local player = playerList[event.peer]

            if player then
                host:broadcast("player_disconnected:" .. player.id)
                playerList[event.peer].player.body:destroy()
                playerList[event.peer].player = nil
                playerList[event.peer] = nil
            end
        end
        event = host:service(0)
    end

    -- Updates players and broadcast updated data to clients
    host:broadcast("update_player:" .. 0 .. ":" .. selfPlayer.x .. ":" .. selfPlayer.y, 0, "unreliable")
    for _, player in pairs(playerList) do
        if player.player then
            player.player:update(dt, player.inputs, Server.eventListener)
            host:broadcast(
                "update_player:" ..
                player.id .. ":" ..
                player.player.x .. ":" ..
                player.player.y,
                0, "unreliable"
            )
        end
    end

    return playerList
end

function Server.eventListener(e)
    if e.type == "spawn_bullet" then
        host:broadcast(
            "spawn_bullet:" .. e.data.x ..
            ":" .. e.data.y ..
            ":" .. e.data.direction ..
            ":" .. e.data.id ..
            ":" .. e.data.shooterID
        )
    elseif e.type == "destroy_bullet" then
        host:broadcast(
            "destroy_bullet:" .. e.data.id
        )
    end
end

return Server