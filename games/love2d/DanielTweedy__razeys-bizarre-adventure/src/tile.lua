 
-- Base abstract class for tiles
tile = {}
tile.avoidBonus = {} -- bonus to not being hit
tile.defenseBonus = {} -- bonus against attack damage
tile.staminaCost = {} -- cost  of moving through tiles

local TILE_SIZE = 32 -- 32x32 tiles

function tile.draw(tileType, y, x)
   love.graphics.draw(tileType.sprite, TILE_SIZE * x, TILE_SIZE * y) 
end

-- Different tile types
field = {}
forest = {}
hill = {}
cave = {}
mountain = {}

local TILE_PATH = "Assets/tilesets/"

field.defenseBonus = 0
field.avoidBonus = 0
field.staminaCost = 0
field.sprite = love.graphics.newImage(TILE_PATH .. "tile_land_0.png")

forest.defenseBonus = 0
forest.avoidBonus = 5
forest.staminaCost = 1
forest.sprite = love.graphics.newImage(TILE_PATH .. "tile_tree_0.png")

hill.defenseBonus = 1
hill.avoidBonus = 0
hill.staminaCost = 1
hill.sprite = love.graphics.newImage(TILE_PATH .. "tile_hill_0.png")

cave.defenseBonus = 0
cave.avoidBonus = 0
cave.staminaCost = 0
cave.sprite = love.graphics.newImage(TILE_PATH .. "tile_cave_00.png")

mountain.defenseBonus = 2
mountain.avoidBonus = 10
mountain.staminaCost = 10
mountain.sprite = love.graphics.newImage(TILE_PATH .. "tile_mountain_0.png")

