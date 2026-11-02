local sti = require 'sti'
local bump = require 'bump.bump'
local enemy = require 'enemy'
local character = require 'player'
local hp = require 'health_potion'
local sw = require 'potion_swiftness'
local tr = require 'treasure'

local cellsize = 16
local map_path = 'assets/dungeon/final_version.lua'

-------------------------------------------------------------------------------
-- Added sounds.
swing = love.audio.newSource('assets/sounds/attack/swing.wav', 'stream')
swing:setVolume(0.3)
swing:setLooping(false)

drink = love.audio.newSource('assets/sounds/potions/bottle.wav', 'stream')
drink:setVolume(0.4)
drink:setLooping(false)

impact = love.audio.newSource('assets/sounds/enemy/attack_impact.wav', 'stream')
impact:setVolume(0.5)
impact:setLooping(false)

walking = love.audio.newSource('assets/sounds/walking/walk1.mp3', 'stream')
walking:setVolume(0.5)
walking:setLooping(false)

enemy_voice = love.audio.newSource('assets/sounds/enemy/shade11.wav', 'stream')
enemy_voice:setVolume(0.2)
enemy_voice:setLooping(false)

enemy_attack = love.audio.newSource('assets/sounds/enemy/attack_small.wav', 'stream')
enemy_attack:setVolume(0.5)
enemy_attack:setLooping(false)

keys = love.audio.newSource('assets/sounds/keys/metal-ringing.wav', 'stream')
keys:setVolume(0.5)
keys:setLooping(false)
-------------------------------------------------------------------------------

-- Load all sprite quads.
-----------------------------------------------------------------------
local spr_list = love.graphics.newImage('assets/dungeon/0x72_16x16DungeonTileset.v4.png')

-- Load specific player sprite.
local char_spr = love.graphics.newQuad(80, 144, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load generic enemy sprite.
local en_spr = love.graphics.newQuad(80, 176, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load second enemy sprite.
local en_spr_second = love.graphics.newQuad(32, 176, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load third enemy sprite.
local en_spr_third = love.graphics.newQuad(32, 160, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load fourth enemy sprite.
local en_spr_fourth = love.graphics.newQuad(48, 192, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load fifth enemy sprite.
local en_spr_fifth = love.graphics.newQuad(16, 192, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load health potion sprite
local health_pt = love.graphics.newQuad(112, 208, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load potion of swiftness sprite.
local pt_swift = love.graphics.newQuad(144, 208, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load enemy troll sprite.
local troll_spr = love.graphics.newQuad(96, 176, 32, 32, spr_list:getWidth(), spr_list:getHeight())

-- Load treasure chest sprite.
local tresr_spr = love.graphics.newQuad(240, 176, 16, 16, spr_list:getWidth(), spr_list:getHeight())

-- Load final treasure chest sprite.
local tresr_spr0 = love.graphics.newQuad(224, 176, 16, 16, spr_list:getWidth(), spr_list:getHeight())
-----------------------------------------------------------------------

-- local timer = 5
-- local initialtime = love.timer.getTime()

-----------------------------------------------------------------------
local map = sti(map_path, {'bump'}, 0, 0)

-- Create physics world.
local world = bump.newWorld(cellsize)

-- Create potions layer.
local layer0 = map:addCustomLayer('Potions', 2)

-- Create layer for characters.
local layer = map:addCustomLayer('Sprites', 7)

-- Create layer for trasure keys.
local layer1 = map:addCustomLayer('Tresr', 3)

map:bump_init(world)
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Position main character on spawn points.
local spawn = {}
spawn.key = {}
spawn.returning = {}
spawn.ambush = {}
for k, object in pairs(map.objects) do
    if object.name == 'Player' then
        spawn.returning.a = object
    elseif object.name == 'Player0' then
        spawn.returning.b = object
    elseif object.name == 'Player1' then
        spawn.returning.c = object
    elseif object.name == 'Player2' then
        spawn.returning.d = object
    elseif object.name == 'Spawn' then
        spawn.original = object
    elseif object.name == 'Player_' then
        spawn.a = object
    elseif object.name == 'Player0_' then
        spawn.b = object
    elseif object.name == 'Player1_' then
        spawn.c = object
    elseif object.name == 'Player2_' then
        spawn.d = object
        -- Load treasure positions
    elseif object.name == 'key' then
        spawn.key[1] = object
    elseif object.name == 'key0' then
        spawn.key[2] = object
    elseif object.name == 'key1' then
        spawn.key[3] = object
    elseif object.name == 'key2' then
        spawn.key[4] = object
    elseif object.name == 'key3' then
        spawn.key[5] = object
    elseif object.name == 'trololo' then
        spawn.ambush[1] = object
    elseif object.name == 'trololo0' then
        spawn.ambush[2] = object
    end
end
-----------------------------------------------------------------------

-- Create player obj.
-----------------------------------------------------------------------
local playerob = character:new()
playerob:setPos(spawn.original.x, spawn.original.y)

-- Set player sprite.
playerob:setSprite(char_spr)
-----------------------------------------------------------------------

-- Create layer sprite space to display on map.
-----------------------------------------------------------------------
layer.sprites = {
    player = playerob
}
--table.insert(layer.sprites, player)
-----------------------------------------------------------------------

-- Layer for setting all potions.
-----------------------------------------------------------------------
layer0.potions = {}
-----------------------------------------------------------------------

-- Layer for setting all treasures.
-----------------------------------------------------------------------
layer1.treasures = {}
-----------------------------------------------------------------------

-- Generate enemies.
-----------------------------------------------------------------------
local enemies = {}
local coord = {}
coord.x, coord.y = 200, 200
math.randomseed(os.clock() * 100000000000)
for i = 1, 220 do
    enemies[i] = enemy:new()
    enemies[i]:setPos(coord.x, coord.y)
    if i % 2 == 0 or i % 5 == 0 then
        enemies[i]:changeDir(-1)
    end
    
    if i < 100 then
        enemies[i]:setSprite(en_spr)
        coord.x, coord.y = math.random(200, 1850), math.random(200, 1850)
    elseif i < 130 then
        enemies[i]:setSprite(en_spr)
        coord.x, coord.y = math.random(2545, 3100), math.random(60, 746)
    elseif i < 160 then
        enemies[i]:setSprite(en_spr_third)
        coord.x, coord.y = math.random(3704, 4432), math.random(36, 765)
    elseif i < 200 then
        enemies[i]:setSprite(en_spr_second)
        coord.x, coord.y = math.random(2563, 3234), math.random(1175, 1758)
    elseif i < 210 then
        enemies[i]:setSprite(en_spr_fourth)
        coord.x, coord.y = math.random(8864, 9216), math.random(8864, 9020)
    else
        enemies[i]:setSprite(en_spr_fifth)
        coord.x, coord.y = math.random(9168, 9580), math.random(9425, 9566)
    end
    table.insert(layer.sprites, enemies[i])
end
enemies[221] = enemy:new()
enemies[221]:setPos(spawn.returning.a.x, spawn.returning.a.y)
enemies[221]:setSprite(troll_spr)
enemies[221]:changeDamage(10)
enemies[221]:changeType('enemy_troll')
table.insert(layer.sprites, enemies[221])

-----------------------------------------------------------------------
local tmp = {}

-- Generate health potion objects.
-----------------------------------------------------------------------
local hpotions = {}
coord.x, coord.y = 300, 300
math.randomseed(os.clock() * 100000000000)
for i = 1, 180 do
    hpotions[i] = hp:new()
    hpotions[i]:setPos(coord.x, coord.y)
    hpotions[i]:setSprite(health_pt)
    
    if math.random(10) % 5 == 0 then
        hpotions[i]:damage()
    end
    if i < 60 then
        coord.x, coord.y = math.random(200, 1850), math.random(200, 1850)
    elseif i < 90 then
        coord.x, coord.y = math.random(2545, 3100), math.random(60, 746)
    elseif i < 120 then
        coord.x, coord.y = math.random(3704, 4432), math.random(36, 765)
    elseif i < 160 then
        coord.x, coord.y = math.random(2563, 3234), math.random(1175, 1758)
    else
        coord.x, coord.y = math.random(8828, 9560), math.random(8834, 9560)
    end

    table.insert(layer0.potions, hpotions[i])
end
-----------------------------------------------------------------------

-- Generate potion of swiftness objects.
-----------------------------------------------------------------------
local swpotions = {}
coord.x, coord.y = 280, 280
math.randomseed(os.clock() * 100000000000)
for i = 1, 180 do
    swpotions[i] = sw:new()
    swpotions[i]:setSprite(pt_swift)
    swpotions[i]:setPos(coord.x, coord.y)
    if i < 60 then
        coord.x, coord.y = math.random(200, 1850), math.random(200, 1850)
    elseif i < 90 then
        coord.x, coord.y = math.random(2545, 3100), math.random(60, 746)
    elseif i < 120 then
        coord.x, coord.y = math.random(3704, 4432), math.random(36, 765)
    elseif i < 160 then
        coord.x, coord.y = math.random(2563, 3234), math.random(1175, 1758)
    else
        coord.x, coord.y = math.random(8828, 9560), math.random(8834, 9560)
    end
    table.insert(layer0.potions, swpotions[i])
end
-----------------------------------------------------------------------

-- Generate treasure box objects.
-----------------------------------------------------------------------
local treasr = {}
for i = 1, 5 do
    treasr[i] = tr:new()
    treasr[i]:setSprite(tresr_spr)
    treasr[i]:setPos(spawn.key[i].x, spawn.key[i].y)
    if i == 3 then
        treasr[i].final = true
        treasr[i]:setSprite(tresr_spr0)
    end
    table.insert(layer1.treasures, treasr[i])
end
-----------------------------------------------------------------------

-----------------------------------------------------------------------
function drawDebug(scale, scale0)
    -- Debug functionality removed - use bump library's built-in debugging if needed
    love.graphics.setColor(255, 255, 255)
end

-- Filter how to collide with various objects.
local playerFilter = function(item, other)
    if other.name == 'health_potion' then
        return 'cross'
    elseif other.name == 'potion_of_swiftness' then
        return 'cross'
    elseif other.name == 'trigger' then
        return 'cross'
    elseif other.name == 'trigger_boss' then
        return 'cross'
    else
        return 'slide'
    end
    -- else return nil
end

-- Calculate distance between two points.
function dist(x1, y1, x2, y2)
    return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

-- Implement player movement.
local initialtime = love.timer.getTime()
local timer = 2
function movePlayer(direction, p, dt)
    local goalX, goalY = p:move(direction, p, dt)

    local actualX, actualY, cols, len = world:move(p, goalX, goalY, playerFilter)
    p.xPos, p.yPos = actualX, actualY

    -- Scan square around character and return what's around him.
    local x1, y1 = p.xPos - 100, p.yPos - 100
    local w, h = 200, 200
    local items, len1 = world:queryRect(x1, y1, w, h)

    -- Tried implementing fog of war.. Not possible at this time.. Beginning again...
    --[[ for i = 1, len1 do
        if items[i].x ~= nil and items[i].y ~= nil then
            --world.get
            local nx, ny = map:convertPixelToTile(items[i].x, items[i].y)
            nx, ny = math.floor(nx), math.floor(ny)
            local xcoord, ycoord = items[i].x, items[i].y

            local tileInstance = map:getInstanceByPixel(xcoord, ycoord, 'fog')
            if tileInstance ~= nil then
                map:removeInstance(tileInstance)
                print('success')
            end
        end
    end ]]

    -- deal with the collisions.
    if love.timer.getTime() - initialtime > timer then
        p:changeSpeed(50)
    end

    for i = 1, len do
        -- Teleport for first dungeon and back.
        --------------------------------------------
        if cols[i].other.name == 'ladder' then
            teleportPlayer(p, spawn.a)
        elseif cols[i].other.name == 'ladder_' then
            teleportPlayer(p, spawn.returning.a)
            --------------------------------------------
            -- Teleport to second dungeon.
            --------------------------------------------
        elseif cols[i].other.name == 'ladder0' then
            -- To be fixed to different return spot.
            teleportPlayer(p, spawn.b)
        elseif cols[i].other.name == 'ladder0_' then
            teleportPlayer(p, spawn.returning.b)
            --------------------------------------------
            -- Teleport to third dungeon.
            --------------------------------------------
        elseif cols[i].other.name == 'ladder1' then
            teleportPlayer(p, spawn.c)
        elseif cols[i].other.name == 'ladder1_' then
            teleportPlayer(p, spawn.returning.c)
            --------------------------------------------
            -- Teleport to fourth dungeon.
            --------------------------------------------
        elseif cols[i].other.name == 'ladder2' then
            teleportPlayer(p, spawn.d)
        elseif cols[i].other.name == 'ladder2_' then
            teleportPlayer(p, spawn.returning.d)
            --------------------------------------------
            -- Handle drinking health potion.
            --------------------------------------------
        elseif cols[i].other.name == 'health_potion' then
            local potion = cols[i].other
            p:heal(potion:take(p), world)
            world:remove(potion)
            drink:play()
            --------------------------------------------
            -- Handle drinking potion of swiftness.
            --------------------------------------------
        elseif cols[i].other.name == 'potion_of_swiftness' then
            local potion = cols[i].other
            p:changeSpeed(potion:take())
            world:remove(potion)
            initialtime = love.timer.getTime()
            drink:play()
            --------------------------------------------
            -- Handle grabbing keys.
            --------------------------------------------
        elseif cols[i].other.name == 'treasure' and cols[i].other.final == false then
            local treasure = cols[i].other
            keys:play()
            world:remove(treasure)
            treasure:take()
            p:takeKey()
            print(p.keys)
            --------------------------------------------
            -- Handle last treasure.
            --------------------------------------------
        elseif cols[i].other.name == 'treasure' and cols[i].other.final == true and p.keys >= 4 then
            local treasure = cols[i].other
            keys:play()
            world:remove(treasure)
            treasure:take()
            p:takeKey()
            p:takeFinalKey()
            print(p.keys)
            --------------------------------------------

            --------------------------------------------
        elseif cols[i].other.name == 'trigger' then
            world:remove(cols[i].other)
            local en = {}
            for i = 1, 2 do
                en[i] = enemy:new()
                en[i]:setPos(spawn.ambush[i].x, spawn.ambush[i].y)
                en[i]:setSprite(troll_spr)
                en[i]:changeDamage(5)
                en[i]:changeType('enemy_troll')
                table.insert(layer.sprites, en[i])
                world:add(en[i], en[i].xPos, en[i].yPos, 10, 20)
            end
            --------------------------------------------

            --------------------------------------------
        elseif cols[i].other.name == 'trigger_boss' and p.keys < 4 then
            world:remove(cols[i].other)
            local en = {}
            for i = 1, 5 do
                en[i] = enemy:new()
                en[i]:setPos(math.random(8825, 9094), math.random(9334, 9565))
                en[i]:setSprite(troll_spr)
                en[i]:changeDamage(5)
                en[i]:changeType('enemy_troll')
                table.insert(layer.sprites, en[i])
                world:add(en[i], en[i].xPos, en[i].yPos, 10, 20)
            end
            --------------------------------------------
        else
            print('collided with ' .. tostring(cols[i].other))
        end
    end

end

-- Enemy movement across map. Trajectory is pretty simple (square movement).
function moveEnemy(e, p, dt)
    local goalX, goalY
    local walkingdir
    goalX, goalY = e:walk(e.xPos, e.yPos, dt)

    local x1, y1 = e.xPos - 100, e.yPos - 100
    local w, h = 200, 200
    local items, len1 = world:queryRect(x1, y1, w, h)

    for i = 1, len1 do
        if items[i].name == 'player' then
            -- print(items[i].info)
            goalX, goalY = e:chase(p.xPos, p.yPos, dt)
        end
    end

    -- If close enough to player, simply attack.
    if e.name == 'enemy' then
        if dist(e.xPos, e.yPos, p.xPos, p.yPos) < 10 then
            if p.health <= 0 then
                p:die()
                p:revive()
                p:resetPos()
                world:remove(p)
                world:add(p, p.xPos, p.yPos, 16 / 10, 16 / 50)
            end
            enemy_attack:play()
            p.health = e:attack(p)
            impact:play()
        end
    elseif e.name == 'enemy_troll' then
        if dist(e.xPos + 16, e.yPos + 16, p.xPos, p.yPos) < 30 then
            if p.health <= 0 then
                p:die()
                p:revive()
                p:resetPos()
                world:remove(p)
                world:add(p, p.xPos, p.yPos, 16 / 10, 16 / 50)
            end
            enemy_attack:play()
            p.health = e:attack(p)
        end
    end
    local actualX, actualY, cols, len = world:move(e, goalX, goalY, playerFilter)

    -- Flip sprite direction.
    if actualX < e.xPos then
        e:flipEnemy(1)
    elseif actualX > e.xPos then
        e:flipEnemy(-1)
    end
    e.xPos, e.yPos = actualX, actualY

    -- Direction switching implemented. Fixed collision release teleportation.

    for i = 1, len do
        if cols[i].other.name ~= 'player' then
            e.dir = e.dir * -1
        end
    end
end

-- Choose which enemy needs to take damage.
function enemySelector(p, dt)
    local x1, y1 = p.xPos - 100, p.yPos - 100
    local w, h = 200, 200
    local items, len = world:queryRect(x1, y1, w, h)

    for i = 1, len do
        if items[i].name == 'enemy' then
            local target = items[i]
            if dist(p.xPos, p.yPos, target.xPos, target.yPos) < 10 then
                if target.health <= 0 then
                    enemy_voice:play()
                    target.alive = false
                    world:remove(target)
                    break
                end
                target.health = p:attack(target)
            end
        end
    end
end

-- Teleports player to another map.
function teleportPlayer(p, pos)
    p.xPos, p.yPos = pos.x, pos.y
    --local oX, oY = po.xPos, po.yPos
    --p.x, p.y = oX, oY
    world:remove(p)
    -- world:add(p, p.x, p.y, p.sprite:getWidth() / 100, p.sprite:getHeight() / 50)
    world:add(p, p.xPos, p.yPos, 16 / 10, 16 / 50)
end
-----------------------------------------------------------------------

-- Helper functions for main.
------------------------------------------------------------------
function map:drawHealth()
    return layer.sprites.player.health
end

function map:getAliveStatus()
    return layer.sprites.player.alive
end

function map:getWinStatus()
    return layer.sprites.player.win
end

function map:getKeys()
    return layer.sprites.player.keys
end

function map:getLives()
    return layer.sprites.player.lives
end
------------------------------------------------------------------

-----------------------------------------------------------------------

-- Add character to collision world.
world:add(layer.sprites.player, layer.sprites.player.xPos, layer.sprites.player.yPos, 16 / 10, 16 / 50)

-- Add enemies to collision world.
for key, value in pairs(layer.sprites) do
    if value.name == 'enemy' then
        world:add(value, value.xPos, value.yPos, 16 / 10, 16 / 50)
    elseif value.name == 'enemy_troll' and value.alive == true then
        world:add(value, value.xPos, value.yPos, 10, 20)
    end
end

-- Add potions to collision world.
for key, value in pairs(layer0.potions) do
    if value.name == 'health_potion' then
        world:add(value, value.x, value.y, 16, 16)
    elseif value.name == 'potion_of_swiftness' then
        world:add(value, value.x, value.y, 16, 16)
    end
end

-- Add treasures to collision world.
for key, value in pairs(layer1.treasures) do
    if value.name == 'treasure' then
        world:add(value, value.x, value.y, 16, 16)
    end
end

-- Remove unneeded object layer.
map:removeLayer("Spawn Point")
-----------------------------------------------------------------------

-- Draw player and the rest of the characters on layer Sprite.
-----------------------------------------------------------------------
layer.draw = function(self)

    -- Draw player sprite on layer.
    love.graphics.draw(spr_list, self.sprites.player.sprite, math.floor(self.sprites.player.xPos),
        math.floor(self.sprites.player.yPos), 0, self.sprites.player.dir, 1, 16 / 2, 16 / 1.1)

    -- Draw enemy sprites on layer.
    for key, value in pairs(self.sprites) do
        if value.name == 'enemy' and value.alive == true then
            local enemy = value
            love.graphics.draw(spr_list, enemy.sprite, math.floor(enemy.xPos), math.floor(enemy.yPos), 0, enemy.flip, 1,
                16 / 2, 16 / 1.1)
        elseif value.name == 'enemy_troll' and value.alive == true then
            local enemy = value
            love.graphics.draw(spr_list, enemy.sprite, math.floor(enemy.xPos), math.floor(enemy.yPos), 0, enemy.flip, 1,
                32 / 2, 32 / 2)
        end
    end

    -- Temporarily draw a point at our location so we know
    -- that our sprite is offset properly.
    -- love.graphics.setPointSize(10)
    -- love.graphics.points(math.floor(self.sprites.tr.x), math.floor(self.sprites.tr.y))

end

layer0.draw = function(self)
    -- Draw health potion sprites.
    for key, value in pairs(self.potions) do
        if value.name == 'health_potion' and value.taken == false then
            love.graphics
                .draw(spr_list, value.sprite, math.floor(value.x), math.floor(value.y), 0, 1, 1, 16 / 2, 16 / 2)
        elseif value.name == 'potion_of_swiftness' and value.taken == false then
            love.graphics
                .draw(spr_list, value.sprite, math.floor(value.x), math.floor(value.y), 0, 1, 1, 16 / 2, 16 / 2)
        end
    end
end

layer1.draw = function(self)
    -- Draw treasure sprites.
    for key, value in pairs(self.treasures) do
        if value.name == 'treasure' and value.key == true then
            love.graphics
                .draw(spr_list, value.sprite, math.floor(value.x), math.floor(value.y), 0, 1, 1, 16 / 2, 16 / 2)
        end
    end
end
-----------------------------------------------------------------------

-----------------------------------------------------------------------
layer0.update = function(self, dt)
end

layer.update = function(self, dt)
    -- 50 pixels per second
    local speed = self.sprites.player.speed

    -- Implemented enemy smart movement.
    for key, value in pairs(self.sprites) do
        if value.name == 'enemy' then
            local enemy = value
            if enemy.alive == true then
                moveEnemy(enemy, self.sprites.player, dt)
            end
        end
        if value.name == 'enemy_troll' then
            local enemy = value
            if enemy.alive == true then
                moveEnemy(enemy, self.sprites.player, dt)
            end
        end
    end

    -- Move player up.
    if love.keyboard.isDown('w') or love.keyboard.isDown('up') then
        self.sprites.player.yPos = self.sprites.player.yPos - speed * dt
        movePlayer('up', self.sprites.player, dt)
        walking:play()

    end

    -- Move player down.
    if love.keyboard.isDown('s') or love.keyboard.isDown('down') then
        self.sprites.player.yPos = self.sprites.player.yPos + speed * dt
        movePlayer('down', self.sprites.player, dt)
        walking:play()
    end

    -- Move player left.
    if love.keyboard.isDown('a') or love.keyboard.isDown('left') then
        self.sprites.player.xPos = self.sprites.player.xPos - speed * dt
        movePlayer('left', self.sprites.player, dt)
        self.sprites.player:flip(1)
        walking:play()
    end

    -- Move player right.
    if love.keyboard.isDown('d') or love.keyboard.isDown('right') then
        self.sprites.player.xPos = self.sprites.player.xPos + speed * dt
        movePlayer('right', self.sprites.player, dt)
        self.sprites.player:flip(-1)
        walking:play()
    end

    -- Attack with player.
    if love.keyboard.isDown('k') then
        enemySelector(self.sprites.player, dt)
        swing:play()
    end

end

layer1.update = function(self, dt)
end
-----------------------------------------------------------------------

return map
