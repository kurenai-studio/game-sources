-- Client.lua
local Player = require "modules.player"
local bullet = require "modules.bullet"
local enet = require "enet"
local socket = require "socket"
local host = enet.host_create()

-- Local playerList (includes itself) and client's own id (yet to be received)
local myId = nil
local playerList = {}

-- Searches LAN for server
local server = nil
local serverList = {}
local isOnMatch = false

local discovery = socket.udp4()
local discoveryTimer = 0
discovery:setoption("broadcast", true)
discovery:setsockname("*", 0)
discovery:settimeout(0)

local client = {}

function client.clientUpdate(selfPlayer, inputs, dt)
    -- If not on a match, searches for one, otherwise continues execution normally
    if not isOnMatch and not server then
        client.searchServer(dt)
        return {}
    end

    -- Resets server list if on a match
    serverList = {}

    -- Captures events
    local event = host:service(0)
    while event do
        -- If it received a message from the server
        if event.type == "receive" then
            -- If its a new id message, assigns it to itself
            local newId = event.data:match("^your_id:(%d+)$")
            if newId then
                myId = tonumber(newId)
            end

            -- If its an update player order, update the said player
            local id, x, y = event.data:match("^update_player:(%d+):([%d%.%-]+):([%d%.%-]+)$")
            if id and x and y then -- Ensures the fields aren't null
                id = tonumber(id)
                x = tonumber(x)
                y = tonumber(y)
                if playerList[id] then
                    -- Updates player data
                    playerList[id].x = x
                    playerList[id].y = y
                else
                    -- If its to update itself, adds itself to playerList
                    if id and id == myId then
                        playerList[id] = selfPlayer
                        selfPlayer.x = x
                        selfPlayer.y = y
                    elseif id then
                        -- If its a new player, create it
                        playerList[id] = Player.new(x, y, id, {1.0, 0.0, 0.0, 1.0})
                    end
                end
            end

            -- If its a player that disconnected, removes it from playerList
            local disconnectedId = event.data:match("^player_disconnected:(%d+)$")
            if disconnectedId then
                disconnectedId = tonumber(disconnectedId)
                if disconnectedId then
                    playerList[disconnectedId] = nil
                end
            end

            local x, y, direction, id, shooterID = event.data:match(
                "^spawn_bullet:([%-]?%d+%.?%d*):([%-]?%d+%.?%d*):([%-]?%d+%.?%d*):(%d+):(%d+)$"
            )
            if x and y and direction and id and shooterID then
                x = tonumber(x)
                y = tonumber(y)
                id = tonumber(id)
                shooterID = tonumber(shooterID)
                direction = tonumber(direction)
                if x and y and direction then
                    bullet.new(x, y, direction, nil, shooterID, id)
                end
            end

            local id = event.data.match("^destroy_bullet:(%d+)$")
            if id then
                id = tonumber(id)
                if id then
                    bullet.bulletList[id] = nil
                end
            end

        -- If it connected to a new server, pings it
        elseif event.type == "connect" then
            event.peer:send("ping")

        -- if it disconnected from a server, ensure match data is erased
        elseif event.type == "disconnect" then
            myId = nil
            playerList = {}
            isOnMatch = false
            server = nil
        end
        event = host:service(0)
    end

    if server then
        -- Sends its own inputs every frame
        server:send("input:" .. table.concat(inputs, " "))
    end

    return playerList
end

function client.searchServer(dt)
    if isOnMatch or server then return end

    -- Sends discover packages every 2 seconds for the whole network, including localhost
    discoveryTimer = discoveryTimer + dt
    if discoveryTimer >= 2 then
        discoveryTimer = 0
        local msg = "LANVE2D_DISCOVER"
        discovery:sendto(msg, "255.255.255.255", 6788)
    end

    -- Processes every received package to see if its a game host
    while true do
        local message, ip, _ = discovery:receivefrom()

        if not message then
            break
        end

        if message == "LANVE2D_HOST" then
            serverList[ip] = {
                ip = ip,
                port = 6789
            }
        end
    end

    -- Logic for selecting a server
    client.selectServerLogic()
end

-- Server selection data
local selectedServerIndex = 1
local selectedServer = ""

-- Imitates the functioning of love.keypressed without needing a hook
local isArrowDown = false
local isEnterDown = false

local servers = {}

function client.selectServerUI()
    -- This ui should only appear when client not on a match
    if isOnMatch then return end

    -- If no server found, prints it
    if #servers == 0 then
        love.graphics.setColor(0.2, 0.5, 0.2, 1.0)
        love.graphics.print("No servers found", 10, 10)
        selectedServer = ""
        selectedServerIndex = 1
        return -- Ensures the following logic only applies where there is at least one server
    end

    -- Organizes the UI properly
    local fontHeight = (love.graphics.getFont()):getHeight()
    for i, server in ipairs(servers) do
        -- Shows which server was selected
        if i == selectedServerIndex then
            love.graphics.setColor(0.0, 1.0, 0.0, 1.0)
            selectedServer = server.ip -- Stores the selected server IP so it doesnt need to be fetched lateer
        else
            love.graphics.setColor(0.2, 0.5, 0.2, 1.0)
        end

        -- Prints the found servers
        love.graphics.print("Server: " .. server.ip, 10, (i - 1) * fontHeight + 10)
    end
end

function client.selectServerLogic()
    -- This logic should only happen when client not on a match
    if isOnMatch then return end

    servers = {}
    for _, server in pairs(serverList) do
        servers[#servers + 1] = server
    end

    table.sort(servers, function (a, b)
        return a.ip < b.ip
    end)

    -- Server selection input
    -- Navigates through the server list
    if love.keyboard.isDown("up") then
        if isArrowDown then return end
        isArrowDown = true
        selectedServerIndex = ((selectedServerIndex) % #servers) + 1
    elseif love.keyboard.isDown("down") then
        if isArrowDown then return end
        isArrowDown = true
        selectedServerIndex = ((selectedServerIndex - 2) % #servers) + 1
    else
        isArrowDown = false
    end

    -- Pressing enter connects to a server
    if selectedServer ~= "" and love.keyboard.isDown("return") then
        if isEnterDown then return end
        isEnterDown = true
        isOnMatch = true
        server = host:connect(selectedServer .. ":6789")
    else
        isEnterDown = false
    end
end

return client