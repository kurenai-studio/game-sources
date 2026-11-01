
local abs = math.abs
ASSET_PATH = "Assets/characters/"
SE_PATH = "Assets/SE/"

razey = {}
razey.x = 2 -- board razeys
razey.y = 4 -- board razeys

razey.health = 20 -- base health points
razey.strength = 7 -- base damage  done
razey.defense = 2 -- damage reduction
razey.avoid = 15 -- how easy to hit razey

-- Some razeys can not attack when too close
razey.minRange = 1 -- number of spaces away a razey can attack
razey.maxRange = 2 -- maximum reach of razey's weapon

razey.stamina = 100
razey.maxStamina = 100
razey.player = true
razey.sprite = love.graphics.newImage(ASSET_PATH .. "sprite_Razey0.png")

cavalryman = {}
cavalryman.x = 3 -- board razeys
cavalryman.y = 5 -- board razeys

cavalryman.health = 25 -- base health points
cavalryman.strength = 8 -- base damage  done
cavalryman.defense = 3 -- damage reduction
cavalryman.avoid = 5 -- how easy to hit razey

-- Some razeys can not attack when too close
cavalryman.minRange = 1 -- number of spaces away a razey can attack
cavalryman.maxRange = 1 -- maximum reach of razey's weapon

cavalryman.stamina = 5
cavalryman.maxStamina = 5
cavalryman.player = true
cavalryman.sprite = love.graphics.newImage(ASSET_PATH .. "Horseman.png")

archer = {}
archer.x = 1 -- board razeys
archer.y = 6 -- board razeys

archer.health = 17 -- base health points
archer.strength = 7 -- base damage  done
archer.defense = 2 -- damage reduction
archer.avoid = 10 -- how easy to hit razey

-- Some razeys can not attack when too close
archer.minRange = 2 -- number of spaces away a razey can attack
archer.maxRange = 3 -- maximum reach of razey's weapon

archer.stamina = 4
archer.maxStamina = 4
archer.player = true
archer.sprite = love.graphics.newImage(ASSET_PATH .. "sprite_Archer00.png")

swordsman = {}
swordsman.x = 3 -- board razeys
swordsman.y = 6 -- board razeys

swordsman.health = 23 -- base health points
swordsman.strength = 9 -- base damage  done
swordsman.defense = 2 -- damage reduction
swordsman.avoid = 15 -- how easy to hit razey

-- Some units can not attack when too close
swordsman.minRange = 1 -- number of spaces away archer can attack
swordsman.maxRange = 1 -- maximum reach of weapon

swordsman.stamina = 4
swordsman.maxStamina = 4
swordsman.player = true
swordsman.sprite = love.graphics.newImage(ASSET_PATH .. "sprite_Swordman00.png")


m1 = {}
m1.x = 4 -- board units
m1.y = 6 -- board units

m1.health = 30 -- base health points
m1.strength = 8 -- base damage  done
m1.defense = 3 -- damage reduction
m1.avoid = 5 -- how easy to hit 

-- Some units can not attack when too close
m1.minRange = 1 -- number of spaces away m1 can attack
m1.maxRange = 1 -- maximum reach of weapon
m1.stamina = 5
m1.maxStamina = 5
m1.player = false
m1.sprite = love.graphics.newImage(ASSET_PATH .. "sprite_TreeMonster00.png")

m2 = {}
m2.x = 5 -- board units
m2.y = 5 -- board units

m2.health = 30 -- base health points
m2.strength = 8 -- base damage  done
m2.defense = 3 -- damage reduction
m2.avoid = 5 -- how easy to hit 

-- Some units can not attack when too close
m2.minRange = 1 -- number of spaces away m2 can attack
m2.maxRange = 1 -- maximum reach of weapon
m2.stamina = 5
m2.maxStamina = 5
m2.player = false
m2.sprite = love.graphics.newImage(ASSET_PATH .. "sprite_TreeMonster00.png")


leader = {}
leader.x = 6 -- board units
leader.y = 5 -- board units

leader.health = 23 -- base health points
leader.strength = 0 -- base damage  done
leader.defense = 1 -- damage reduction
leader.avoid = 80 -- how easy to hit 

-- Some units can not attack when too close
leader.minRange = 1 -- number of spaces away m2 can attack
leader.maxRange = 2 -- maximum reach of weapon
leader.stamina = 4
leader.maxStamina = 4
leader.player = false
leader.sprite = love.graphics.newImage(ASSET_PATH .. "sprite_MLeader0.png")


unit = {}

function unit.move(character, dx, dy)
    local totalDistance = math.abs(dx) + math.abs(dy)
    if(totalDistance <= character.stamina) then
        character.x = character.x + dx
        character.y = character.y + dy
        character.stamina = character.stamina - totalDistance
		sound = love.audio.newSource(SE_PATH .. "move.wav","static")
		sound:play()		
	else
		sound = love.audio.newSource(SE_PATH .. "cannot.wav", "static")
		sound:play()		
    end
end

function unit.draw(character)
    local TILE_SIZE = 32
    if(character.sprite:getWidth() > TILE_SIZE) then
        love.graphics.draw(character.sprite, TILE_SIZE * character.x, TILE_SIZE * character.y, 0, .5, .5)
    else
        love.graphics.draw(character.sprite, TILE_SIZE * character.x, TILE_SIZE * character.y)
    end
end

function unit.inRange(character, distance)
    return distance >= character.minRange and distance <= character.maxRange
end

function unit.canFight(character)
    return character.stamina > 0
end

function unit.hitChance(avoidBonus, tileAvoidBonus)
    local baseChance = 100
    return baseChance - (avoidBonus + tileAvoidBonus)
end

function unit.dead(character)
    return character.health < 1
end
