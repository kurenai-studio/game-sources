--Player functions

local player = {}

local function loadPlayer(world)
    local player = {} --Create player
    player.pBody = love.physics.newBody(world.physics, 50, 350, "dynamic")
    player.pBody:setFixedRotation(true)
    player.shape = love.physics.newCircleShape(20)
    player.fixture = love.physics.newFixture(player.pBody, player.shape, 1) 
    player.fixture:setUserData("player")
    player.fixture:setFriction(2.0)
    player.dead = false
    player.locked = false
    player.tool = ""
    player.magnet = {}
    player.spaceReleased = false
    return player
end
player.loadPlayer = loadPlayer

local function updatePlayer(world, dt, zones)
    local player = world.player
    local x, y = player.pBody:getLinearVelocity()
    local speed = 150
    if not(player.locked) then
        if world.keys.right then
            player.pBody:setLinearVelocity(speed, y)
        elseif world.keys.left then
            player.pBody:setLinearVelocity(-speed, y)
        end
        if zones.footing >= 1 then
            if world.keys.up then
                player.pBody:applyForce(0, -3000)
            end
        end
    end

    if player.magnet.pBody == nil then
        spawnMagnet(world)
    end

    if player.pBody:getY() > 400 then
        world.level = "gameOver"
    end

    --actions
    if zones.inLight >= 1 then
        world.helpText = "X to turn light on/off. Press Z and C to rotate light. Press A and D to drive boat"
        if world.keys.x == false then
            world.cReleased = true
        end
        if world.keys.x then
            if world.cReleased then
                if world.lampOn then
                    world.lampOn = false
                else
                    world.lampOn = true
                    world.lampAngle = world.platformB.pBody:getX()
                end
            end
            world.cReleased = false
        end
        if world.keys.a then
            world.boatSpeed = -75
            if player.pBody:getX() < world.boatMin then
                world.boatSpeed = 0
            end
            --world.lampAngle = 0
            --world.lampOn = false
        elseif world.keys.d then
            world.boatSpeed = 75
            if player.pBody:getX() > world.boatMax then
                world.boatSpeed = 0
            end
            --world.lampAngle = 0
            --world.lampOn = false
        else
            world.boatSpeed = 0
        end
        if world.keys.z then
            world.lampAngle = world.lampAngle - 15
        elseif world.keys.c then
            world.lampAngle = world.lampAngle + 15
        end
    elseif zones.onBelow >= 1 then
        
    elseif zones.onDock >= 1 then
        world.helpText = "Arrow keys to move and jump"
    elseif zones.onProw >= 1 then
        world.helpText = "Space to drop grabber. Space to retrive grabber"
        if world.keys.space and player.magnet.magnetDown == false then
            dropMagnet(world)
            player.magnet.pBody:applyForce(100, 0)
            player.locked = true
        elseif world.keys.space and player.magnet.magnetDown and player.spaceReleased  then
            player.magnet.raiseMagnet = true
        end
        if player.magnet.raiseMagnet then
            if player.magnet.rope:getMaxLength() > 25 then
                raiseMagnet(world)
            else
                player.magnet.rope:destroy()
                if player.magnet.weld:isDestroyed() == false then
                    player.magnet.weld:destroy()
                    local weldObject = player.magnet.weldObject
                    local fixture = player.magnet.weldObject:getFixtures()
                    local score = fixture[1]:getFriction()
                    world.score = world.score + score
                    weldObject:destroy()
                end
                player.magnet.pBody:setPosition(player.pBody:getX(), player.pBody:getY())
                player.magnet.magnetDown = false
                player.magnet.raiseMagnet = false
                player.magnet.canWeld = true
                player.magnet.makeWeld = false
                player.magnet.weld = love.physics.newWeldJoint(player.pBody, player.magnet.pBody, player.pBody:getX(), player.pBody:getY())
                player.locked = false
            end
        end
        if player.magnet.pBody ~= nil then
            if player.magnet.makeWeld and player.magnet.canWeld then
                player.magnet.weld = love.physics.newWeldJoint(player.magnet.weldObject, player.magnet.pBody, player.magnet.pBody:getX(), player.magnet.pBody:getY())
                local fixture = player.magnet.weldObject:getFixtures()
                fixture[1]:setSensor(true)
                player.magnet.canWeld = false
            end
        end
    elseif zones.onBack >= 1 then
        world.helpText = "Space to drop grabber. Space to retrive grabber"
        if world.keys.space and player.magnet.magnetDown == false then
            dropMagnet(world)
            player.magnet.pBody:applyForce(-100, 0)
            player.locked = true
        elseif world.keys.space and player.magnet.magnetDown and player.spaceReleased  then
            player.magnet.raiseMagnet = true
        end
        if player.magnet.raiseMagnet then
            if player.magnet.rope:getMaxLength() > 25 then
                raiseMagnet(world)
            else
                player.magnet.rope:destroy()
                if player.magnet.weld:isDestroyed() == false then
                    player.magnet.weld:destroy()
                    local weldObject = player.magnet.weldObject
                    local fixture = player.magnet.weldObject:getFixtures()
                    local score = fixture[1]:getFriction()
                    world.score = world.score + score
                    weldObject:destroy()
                end
                player.magnet.pBody:setPosition(player.pBody:getX(), player.pBody:getY())
                player.magnet.magnetDown = false
                player.magnet.raiseMagnet = false
                player.magnet.canWeld = true
                player.magnet.makeWeld = false
                player.magnet.weld = love.physics.newWeldJoint(player.pBody, player.magnet.pBody, player.pBody:getX(), player.pBody:getY())
                player.locked = false
            end
        end
    else
        world.helpText = ""
        world.boatSpeed = 0
    end

    if world.keys.space == true then
        world.player.spaceReleased = false
    else
        world.player.spaceReleased = true
    end

    if world.keys.h then
        world.message = ""
    end
end
player.updatePlayer = updatePlayer

function spawnMagnet(world)
    local magnet = world.player.magnet
    local player = world.player.pBody
    magnet.pBody = love.physics.newBody(world.physics, player:getX(), player:getY(), "dynamic")
    magnet.pBody:setFixedRotation(true)
    magnet.shape = love.physics.newCircleShape(5)
    magnet.fixture = love.physics.newFixture(magnet.pBody, magnet.shape, 1) 
    magnet.fixture:setUserData("magnet")
    magnet.fixture:setSensor(true)
    magnet.magnetDown = false
    magnet.weld = love.physics.newWeldJoint(player, magnet.pBody, player:getX(), player:getY())
    magnet.makeWeld = false
    magnet.canWeld = true
end

function dropMagnet(world)
    local magnet = world.player.magnet
    local player = world.player.pBody
    local ropeLength = 325
    magnet.weld:destroy()
    magnet.magnetDown = true
    magnet.raise = false
    magnet.rope = love.physics.newRopeJoint(player, magnet.pBody, player:getX(), player:getY(), magnet.pBody:getX(), magnet.pBody:getY(), ropeLength)
    magnet.ropeLength = ropeLength
end

function raiseMagnet(world)
    world.player.magnet.ropeLength = world.player.magnet.ropeLength - 3
    world.player.magnet.rope:setMaxLength(world.player.magnet.ropeLength)
end

return player