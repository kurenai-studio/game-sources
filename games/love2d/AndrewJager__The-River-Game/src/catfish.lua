local utils = require "utils"

local catFish = {}

local function createCatfish(world)
    catFish = {}
    local objects = world.map.pObjects
    catFish.targetMaster = utils.getByName("targetGod", objects)
    catFish.tarA = utils.getByName("catTarA", objects)
    catFish.tarB = utils.getByName("catTarB", objects)
    catFish.tarC = utils.getByName("catTarC", objects)
    catFish.tarD = utils.getByName("catTarD", objects)
    catFish.tarE = utils.getByName("catTarE", objects)
    catFish.state = "idle"
    catFish.speed = 35
    catFish.update = 0 --Time before catfish changes state
    catFish.moving = false
    catFish.atProw = false
    catFish.atBack = false
    catFish.jumping = false
    catFish.attack = false
    catFish.canJump = true
    catFish.fish = {}
    local fish = catFish.fish
    fish.pBody = love.physics.newBody(world.physics, catFish.tarE.pBody:getX(), catFish.tarE.pBody:getY(), "kinematic")
    catFish.startY = fish.pBody:getY()
    fish.shape = love.physics.newCircleShape(35)
    fish.fixture = love.physics.newFixture(fish.pBody, fish.shape, 1) 
    fish.fixture:setUserData("catfish")
    fish.fixture:setSensor(true)

    local weld = love.physics.newWeldJoint(catFish.targetMaster.pBody, catFish.tarA.pBody, catFish.targetMaster.pBody:getX(), catFish.targetMaster.pBody:getY())
    local weld2 = love.physics.newWeldJoint(catFish.targetMaster.pBody, catFish.tarB.pBody, catFish.targetMaster.pBody:getX(), catFish.targetMaster.pBody:getY())
    local weld3 = love.physics.newWeldJoint(catFish.targetMaster.pBody, catFish.tarC.pBody, catFish.targetMaster.pBody:getX(), catFish.targetMaster.pBody:getY())
    local weld4 = love.physics.newWeldJoint(catFish.targetMaster.pBody, catFish.tarD.pBody, catFish.targetMaster.pBody:getX(), catFish.targetMaster.pBody:getY())
    local weld5 = love.physics.newWeldJoint(catFish.targetMaster.pBody, catFish.tarE.pBody, catFish.targetMaster.pBody:getX(), catFish.targetMaster.pBody:getY())
    return catFish
end
catFish.load = createCatfish

local function updateCatfish(world, dt, zones)
    local function goToTar(target, world)
        local catX = world.catFish.fish.pBody:getX()
        local tarX = nil 
        if target == "A" then
            tarX = world.catFish.tarA.pBody:getX()
        elseif target == "B" then
            tarX = world.catFish.tarB.pBody:getX()
        elseif target == "C" then
            tarX = world.catFish.tarC.pBody:getX()
        elseif target == "D" then
            tarX = world.catFish.tarD.pBody:getX()
        elseif target == "E" then
            tarX = world.catFish.tarE.pBody:getX()
        end
        local dist = tarX - catX
        local error = 5
        if dist > error then
            world.catFish.fish.pBody:setLinearVelocity(catFish.speed, 0.0)
            world.catFish.moving = true
        elseif dist < -error then
            world.catFish.fish.pBody:setLinearVelocity(-catFish.speed, 0.0)
            world.catFish.moving = true
        else
            catFish.state = "idle"
            world.catFish.moving = false
            world.catFish.fish.pBody:setLinearVelocity(0.0, 0.0)
        end
    end
    local function jump()
        local playerPos = world.player.pBody:getX()
        local catPos = world.catFish.fish.pBody:getX()
        local xVel = 0
        if playerPos > catPos then
            xVel = 75
        else
            xVel = -75
        end
        if world.catFish.canJump then
            world.catFish.fish.pBody:setLinearVelocity(xVel, -350)
            world.catFish.jumping = true
            world.catFish.attack = true
            world.catFish.state = "jump"
            world.catFish.moving = true
        end
    end
    local catFish = world.catFish
    local updateThreshold = 1
    catFish.targetMaster.pBody:setLinearVelocity(world.boatSpeed, 0)

    local threshold = 50
    if (catFish.fish.pBody:getX() < (world.catFish.tarD.pBody:getX() + threshold)) and (catFish.fish.pBody:getX() > (world.catFish.tarD.pBody:getX() - threshold)) then
        catFish.atProw = true
    else
        catFish.atProw = false
    end
    if (catFish.fish.pBody:getX() < (world.catFish.tarB.pBody:getX() + threshold)) and (catFish.fish.pBody:getX() > (world.catFish.tarB.pBody:getX() - threshold)) then
        catFish.atBack = true
    else
        catFish.atBack = false
    end

    if catFish.update > updateThreshold then
        catFish.update = 0
        local next = love.math.random(1, 8)
        if next == 1 or next == 2 or next == 3 then
            catFish.state = "idle"
        elseif next == 4 then
            if catFish.state == "a" then
                catFish.state = "idle"
            else
                catFish.state = "a"
            end
        elseif next == 5 then
            if catFish.state == "b" then
                catFish.state = "idle"
            else
                catFish.state = "b"
            end
        elseif next == 6 then
            if catFish.state == "c" then
                catFish.state = "idle"
            else
                catFish.state = "c"
            end
        elseif next == 7 then
            if catFish.state == "d" then
                catFish.state = "idle"
            else
                catFish.state = "d"
            end
        elseif next == 8 then
            if catFish.state == "e" then
                catFish.state = "idle"
            else
                catFish.state = "e"
            end
        end
    end
    if catFish.state == "idle" then

    elseif catFish.state == "a" then
        goToTar("A", world)
    elseif catFish.state == "b" then
        goToTar("B", world)
    elseif catFish.state == "c" then
        goToTar("C", world)
    elseif catFish.state == "d" then
        goToTar("D", world)
    elseif catFish.state == "e" then
        goToTar("E", world)
    end

    if catFish.atProw and zones.onProw > 0 then
        jump()
    elseif catFish.atBack and zones.onBack > 0 then
        jump()
    elseif catFish.jumping and (zones.onBack > 0 or zones.onProw > 0) then
        jump()
    else
        catFish.attack = false
    end
    if catFish.fish.pBody:getY() < 200 then
        catFish.canJump = false
        catFish.attack = false
    end

    if catFish.jumping and not(catFish.attack) then --Get fish back down

        if catFish.fish.pBody:getY() < catFish.startY then
            catFish.fish.pBody:setLinearVelocity(0.0, 450)
        else
            catFish.jumping = false
            catFish.fish.pBody:setLinearVelocity(0.0, 0.0)
            catFish.state = "idle"
            catFish.moving = false
            catFish.canJump = true
        end
    end

    if not(catFish.moving) then
        catFish.update = catFish.update + dt
    end
end
catFish.update = updateCatfish

return catFish