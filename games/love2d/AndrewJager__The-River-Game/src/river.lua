--Main map functions

local river = {}
local utils = require "utils"
local playerGen = require "player"
local catFish = require "catfish"
local rayHandler = require "godrays"
local worldCopy = {} --Hacky, but I don't care
local debug = false

local boatGod = nil
local deck = nil
local deckBack = nil
local prow = nil
local platform = nil
local platformB = nil
local rockerL = nil
local rockerR = nil
local prowZone = nil
local backZone = nil
local lightZone = nil
local belowZone = nil
local prowWall = nil
local backWall = nil

local items = {}
local debris = {}

local zones = {}
zones.footing = 0
zones.inLight = 0
zones.onProw = 0
zones.onBack = 0
zones.onBelow = 0
zones.onDock = 0

local waterA = love.graphics.newImage("images/waterA.png")
local waterB = love.graphics.newImage("images/waterB.png")
local waterC = love.graphics.newImage("images/waterC.png")
local water = waterA
local water2 = waterB
local waterUpdate = 0
local waterOffset = 0
local waterUpdate2 = 25
local waterOffset2 = 0
local levelMax = 3000

local plantA = love.graphics.newImage("images/plantA.png")
local plantB = love.graphics.newImage("images/plantB.png")
local plantC = love.graphics.newImage("images/plantC.png")
local plantD = love.graphics.newImage("images/plantD.png")
local reedA = love.graphics.newImage("images/reedA.png")
local reedB = love.graphics.newImage("images/reedB.png")
local reedC = love.graphics.newImage("images/reedC.png")
local reedD = love.graphics.newImage("images/reedD.png")
local fishImage = love.graphics.newImage("images/catfish.png")
local boatImage = love.graphics.newImage("images/boat.png")
local playerImage = love.graphics.newImage("images/player.png")
local dockImage = love.graphics.newImage("images/dock.png")
local sprites = {}
local rays = {}

local light = nil

local function loadRiver(world)
    love.physics.setMeter(64) 
    world.physics = love.physics.newWorld(0, 9.81*64, true)
    world.physics:setCallbacks(beginCallback, endCallback)
    world.map = loader.load(world.physics)
    world.helpText = "Arrow keys to move"
    world.boatSpeed = 0
    world.boatMin = 500
    world.boatMax = levelMax
    world.lampAngle = 0
    world.lampOn = false
    world.message = "Retrive as much salvage from the riverbed as you can"
    world.messageb = "Go to the edges of the boat to use the grabber"
    world.messagec = "Go to the top the boat to use the spotlight and drive the boat"
    world.messaged = "Don't fall in the water, or get eaten by the catfish"
    world.score = 0

    world.player = playerGen.loadPlayer(world)
    worldCopy = world
    local objects = world.map.pObjects
    for i=1, #objects do
        objects[i].pFixture = love.physics.newFixture(objects[i].pBody, objects[i].pShape, 2.0)
        objects[i].pBody:setFixedRotation(objects[i].pFixRotation)
        objects[i].pBody:setSleepingAllowed(false)
        objects[i].pFixture:setUserData(objects[i].data)
        if objects[i].isSensor then
            objects[i].pFixture:setSensor(true)
        end
    end

    world.catFish = catFish.load(world)

    boatGod = utils.getByName("boatGod", objects)
    deck = utils.getByName("Deck", objects)
    deck.pBody:setAngularDamping(10.0)
    deck.pBody:setLinearDamping(10.0)
    deck.pFixture:setDensity(15)
    deckBack = utils.getByName("DeckBack", objects)
    prow = utils.getByName("Prow", objects)
    platform = utils.getByName("Platform", objects)
    platformB = utils.getByName("Platform2", objects)
    world.platformB = platformB
    rockerL = utils.getByName("rockerL", objects)
    rockerR = utils.getByName("rockerR", objects)
    prowZone = utils.getByName("prowZone", objects)
    backZone = utils.getByName("backZone", objects)
    lightZone = utils.getByName("lightZone", objects)
    belowZone = utils.getByName("belowZone", objects)
    prowWall = utils.getByName("ProwWall", objects)
    backWall = utils.getByName("DeckBackWall", objects)

    local rope = love.physics.newRopeJoint(boatGod.pBody, deck.pBody, boatGod.pBody:getX(), boatGod.pBody:getY(), deck.pBody:getX(), deck.pBody:getY(), 350)
    local rope2 = love.physics.newRopeJoint(rockerL.pBody, deck.pBody, rockerL.pBody:getX(), rockerL.pBody:getY(), rockerL.pBody:getX(), deck.pBody:getY(), 350)
    local rope3 = love.physics.newRopeJoint(rockerR.pBody, deck.pBody, rockerR.pBody:getX(), rockerR.pBody:getY(), rockerR.pBody:getX(), deck.pBody:getY(), 350)
    local weld = love.physics.newWeldJoint(deck.pBody, deckBack.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld2 = love.physics.newWeldJoint(deck.pBody, prow.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld3 = love.physics.newWeldJoint(deck.pBody, platform.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld4 = love.physics.newWeldJoint(deck.pBody, platformB.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld5 = love.physics.newWeldJoint(deck.pBody, prowZone.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld6 = love.physics.newWeldJoint(deck.pBody, backZone.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld7 = love.physics.newWeldJoint(deck.pBody, lightZone.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld8 = love.physics.newWeldJoint(deck.pBody, belowZone.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld9 = love.physics.newWeldJoint(deck.pBody, prowWall.pBody, deck.pBody:getX(), deck.pBody:getY())
    local weld10 = love.physics.newWeldJoint(deck.pBody, backWall.pBody, deck.pBody:getX(), deck.pBody:getY())

    local plantCount = 15
    for i = 1, plantCount do
        local choice = love.math.random(1, 4)
        local newSprite = {}
        if choice == 1 then
            newSprite.image = plantA
            newSprite.offset = -100
        elseif choice == 2 then
            newSprite.image = plantB
            newSprite.offset = -310
        elseif choice == 3 then
            newSprite.image = plantC
            newSprite.offset = 0
        elseif choice == 4 then
            newSprite.image = plantD
            newSprite.offset = -100
        end
        newSprite.x = love.math.random(200, levelMax)
        newSprite.y = 50
        sprites[i] = newSprite
    end
    local reedCount = 100
    for i = plantCount + 1, reedCount + plantCount do
        local choice = love.math.random(1, 4)
        local newSprite = {}
        if choice == 1 then
            newSprite.image = reedA
            newSprite.offset = -460
        elseif choice == 2 then
            newSprite.image = reedB
            newSprite.offset = -510
        elseif choice == 3 then
            newSprite.image = reedC
            newSprite.offset = -460
        elseif choice == 4 then
            newSprite.image = reedD
            newSprite.offset = -460
        end
        newSprite.offset = newSprite.offset - love.math.random(0, 80)
        newSprite.x = love.math.random(200, levelMax)
        newSprite.y = 50
        sprites[i] = newSprite
    end

    local itemsCount = 15
    for i = 1, itemsCount do
        blackBox = {}
        blackBox.value = love.math.random(50, 100)
        blackBox.pBody = love.physics.newBody(world.physics, love.math.random(800, levelMax), 500, "dynamic")
        blackBox.shape = love.physics.newRectangleShape(0, 0, blackBox.value, 50)
        blackBox.fixture = love.physics.newFixture(blackBox.pBody, blackBox.shape, 0.01)
        blackBox.fixture:setUserData("item")
        blackBox.fixture:setFriction(blackBox.value)
        items[i] = blackBox
    end
    local debrisCount = 65
    for i = 1, debrisCount do
        blackBox = {}
        blackBox.value = love.math.random(1, 5)
        blackBox.pBody = love.physics.newBody(world.physics, love.math.random(800, levelMax), 300, "dynamic")
        blackBox.shape = love.physics.newRectangleShape(0, 0, blackBox.value * 20, 10)
        blackBox.fixture = love.physics.newFixture(blackBox.pBody, blackBox.shape, 0.1)
        blackBox.fixture:setUserData("item")
        blackBox.fixture:setFriction(blackBox.value)
        debris[i] = blackBox
    end
    local raysCount = 15
    for i = 1, raysCount do
        local x = love.math.random(250, levelMax)
        ray = rayHandler.createRay(75, x, 0, x + love.math.random(35, 70), 0, x + love.math.random(-150, 150), 600)
        ray.spreadX = love.math.random(50, 200)
        rays[i] = ray
    end
end
river.load = loadRiver

local function updateRiver(world, dt)
    boatGod.pBody:setLinearVelocity(world.boatSpeed,0.0)
    rockerL.pBody:setLinearVelocity(world.boatSpeed,0.0)
    rockerR.pBody:setLinearVelocity(world.boatSpeed, 0)

    for i = #debris, 1, -1 do
        if debris[i].pBody:isDestroyed() then
            table.remove(debris,i)
        end
    end
    for i = #items, 1, -1 do
        if items[i].pBody:isDestroyed() then
            table.remove(items,i)
        end
    end
    for i = 1, #rays do
        rayHandler.updateRay(rays[i], dt)
    end

    local waterUpdateTime = 50
    if waterUpdate >= waterUpdateTime then
        if water == waterA then
            water = waterB
        elseif water == waterB then
            water = waterC
        elseif water == waterC then
            water = waterA
        end
        waterUpdate = 0
        waterOffset = 0
    else
        waterUpdate = waterUpdate + 1
        waterOffset = waterOffset + 0.5
    end
    if waterUpdate2 >= waterUpdateTime then
        if water2 == waterA then
            water2 = waterB
        elseif water2 == waterB then
            water2 = waterC
        elseif water2 == waterC then
            water2 = waterA
        end
        waterUpdate2 = 0
        waterOffset2 = 0
    else
        waterUpdate2 = waterUpdate2 + 1
        waterOffset2 = waterOffset2 + 0.5
    end
    playerGen.updatePlayer(world, dt, zones)
    catFish.update(world, dt, zones)

    world.physics:update(dt)
end
river.update = updateRiver

local function drawRiver(world)
    love.graphics.translate(-world.player.pBody:getX() + 450, 0)
    for i = 1, #rays do
        rayHandler.drawRay(rays[i])
    end
    love.graphics.setColor(1,1,1)
    for i = 1, #sprites do
        love.graphics.draw(sprites[i].image, sprites[i].x, sprites[i].y, 0, 0.5, 0.5, 0, sprites[i].offset)
    end

    love.graphics.push()
    love.graphics.setColor(0.2,0.2,0.2)
    love.graphics.translate(world.player.pBody:getX() - 450 - waterOffset2, 0)
    love.graphics.scale(0.5,0.5)
    love.graphics.draw(water2, -50, 750)
    love.graphics.pop()

    if world.player.magnet.pBody ~= nil then
        love.graphics.setColor(0.15, 0.1, 0.2)
        love.graphics.line(world.player.pBody:getX(), world.player.pBody:getY(), world.player.magnet.pBody:getX(), world.player.magnet.pBody:getY())
    end

    love.graphics.setColor(0.3,0.3,0.3)
    love.graphics.draw(playerImage, world.player.pBody:getX(), world.player.pBody:getY(), 0, 0.4, 0.4, 60, 100)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(dockImage, -70, 105, 0, 0.3, 0.3)
    love.graphics.draw(boatImage, deck.pBody:getX(), deck.pBody:getY(), deck.pBody:getAngle(), 0.5, 0.5, 470, 305)
    local x, y = world.catFish.fish.pBody:getLinearVelocity()
    if y == 0 then
        if x > 0 then
            love.graphics.draw(fishImage, world.catFish.fish.pBody:getX(), world.catFish.fish.pBody:getY(), world.catFish.fish.pBody:getAngle(), -0.2, 0.2, 290, 290)
        else
            love.graphics.draw(fishImage, world.catFish.fish.pBody:getX(), world.catFish.fish.pBody:getY(), world.catFish.fish.pBody:getAngle(), 0.2, 0.2, 290, 290)
        end
    elseif y > 0 then
        love.graphics.draw(fishImage, world.catFish.fish.pBody:getX(), world.catFish.fish.pBody:getY(), math.rad(-90), 0.2, 0.2, 290, 290)
    elseif y < 0 then
        love.graphics.draw(fishImage, world.catFish.fish.pBody:getX(), world.catFish.fish.pBody:getY(), math.rad(90), 0.2, 0.2, 290, 290)
    end

    love.graphics.setColor(0.380, 0.368, 0.360)
    for i=1, #items do
        if items[i].pBody:isDestroyed() == false then
            love.graphics.polygon("fill", items[i].pBody:getWorldPoints(items[i].shape:getPoints()))
        end
    end
    love.graphics.setColor(0.4, 0.215, 0.039)
    for i=1, #debris do
        if debris[i].pBody:isDestroyed() == false then
            love.graphics.polygon("fill", debris[i].pBody:getWorldPoints(debris[i].shape:getPoints()))
        end
    end

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.stencil(lightStencil, "replace", 1)
    love.graphics.push()
    love.graphics.translate(world.player.pBody:getX() - 450 - waterOffset, 0)
    love.graphics.scale(0.5,0.5)
    love.graphics.setStencilTest("equal", 0)
    love.graphics.draw(water, -50, 750)
    love.graphics.pop()
    love.graphics.setStencilTest()

    if worldCopy.lampOn then
        love.graphics.setColor(0.972, 0.984, 0.494, 0.5)
        lightPos = platformB.pBody
        local x = worldCopy.lampAngle
        local y = 800
        polygon = love.graphics.polygon('fill', lightPos:getX(), lightPos:getY(), x - 150, y, x + 150, y)
    end

    if debug == true then
        love.graphics.setColor(0.76, 0.18, 0.05)
        love.graphics.circle("fill", world.player.pBody:getX(), world.player.pBody:getY(), world.player.shape:getRadius())
        love.graphics.circle("fill", world.catFish.fish.pBody:getX(), world.catFish.fish.pBody:getY(), world.catFish.fish.shape:getRadius())
        if world.player.magnet.pBody ~= nil then
            love.graphics.setColor(0.18, 0.76, 0.05)
            love.graphics.circle("fill", world.player.magnet.pBody:getX(), world.player.magnet.pBody:getY(), world.player.magnet.shape:getRadius())
        end
        local objects = world.map.pObjects
        for i=1, #objects do
            love.graphics.setColor(unpack(objects[i].color))
            love.graphics.polygon("fill", objects[i].pBody:getWorldPoints(objects[i].pShape:getPoints()))
        end
    end

    love.graphics.setFont(world.font)
    love.graphics.translate(world.player.pBody:getX() - 450, 0)
    love.graphics.setColor(0.4, 0.4, 0.4)
    if world.helpText ~= "" then
        love.graphics.rectangle("fill", 150, 15, 600, 25)
        love.graphics.setColor(1,1,1)
        love.graphics.print(world.helpText, 155, 20)
    end
    if world.message ~= "" then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", 150, 500, 600, 85)
        love.graphics.setColor(1,1,1)
        love.graphics.print(world.message, 155, 505)
        love.graphics.print(world.messageb, 155, 520)
        love.graphics.print(world.messagec, 155, 535)
        love.graphics.print(world.messaged, 155, 550)
        love.graphics.print("(press h to hide)", 155, 565)
    end
    love.graphics.print("Score: "..world.score, 15, 20)
end
river.draw = drawRiver

function beginCallback(a, b, col)
    if a:getUserData() == "player" or b:getUserData() == "player" then
        if a:getUserData() == "boat" or b:getUserData() == "boat" then
            zones.footing = zones.footing + 1
        elseif a:getUserData() == "prowZone" or b:getUserData() == "prowZone" then
            zones.onProw = zones.onProw + 1
        elseif a:getUserData() == "backZone" or b:getUserData() == "backZone" then
            zones.onBack = zones.onBack + 1
        elseif a:getUserData() == "lightZone" or b:getUserData() == "lightZone" then
            zones.inLight = zones.inLight + 1
        elseif a:getUserData() == "belowZone" or b:getUserData() == "belowZone" then
            zones.onBelow = zones.onBelow + 1
        elseif a:getUserData() == "dockZone" or b:getUserData() == "dockZone" then
            zones.onDock = zones.onDock + 1
        elseif a:getUserData() == "catfish" or b:getUserData() == "catfish" then
            worldCopy.level = "gameOver"
        end
    end

    if a:getUserData() == "item" or b:getUserData() == "item" then
        if a:getUserData() == "magnet" or b:getUserData() == "magnet" then
            local magnet = worldCopy.player.magnet
            magnet.makeWeld = true
            if magnet.canWeld then
                if a:getUserData() == "item" then
                    magnet.weldObject = a:getBody()
                else
                    magnet.weldObject = b:getBody()
                end
            end
        end
    end
end

function endCallback(a, b, col)
    if a:getUserData() == "player" or b:getUserData() == "player" then
        if a:getUserData() == "boat" or b:getUserData() == "boat" then
            zones.footing = zones.footing - 1
        elseif a:getUserData() == "prowZone" or b:getUserData() == "prowZone" then
            zones.onProw = zones.onProw - 1
        elseif a:getUserData() == "backZone" or b:getUserData() == "backZone" then
            zones.onBack = zones.onBack - 1
        elseif a:getUserData() == "belowZone" or b:getUserData() == "belowZone" then
            zones.onBelow = zones.onBelow - 1
        elseif a:getUserData() == "lightZone" or b:getUserData() == "lightZone" then
            zones.inLight = zones.inLight - 1
        elseif a:getUserData() == "dockZone" or b:getUserData() == "dockZone" then
            zones.onDock = zones.onDock - 1
        end
    end
end

function lightStencil()
    if worldCopy.lampOn then
        lightPos = platformB.pBody
        local x = worldCopy.lampAngle
        local y = 800
        polygon = love.graphics.polygon('fill', lightPos:getX(), lightPos:getY(), x - 150, y, x + 150, y)
    end
end

return river