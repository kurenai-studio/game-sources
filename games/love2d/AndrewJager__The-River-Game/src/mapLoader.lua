--Load maps from tiled

local utils = require "utils"

local loader = {}

local function loadMap(physics)
    local mapSrc = require 'Tiled/riverMap'
    local map = {}
    map.pObjects = {}
    map.sprites = {}
    local mapObjects = utils.getByName("Object Layer 1", mapSrc.layers).objects
    for i = 1, #mapObjects do
        map.pObjects[i] = {}
        map.pObjects[i].name = mapObjects[i].name
        local x, y = utils.getMidPoint(mapObjects[i].x, mapObjects[i].y, mapObjects[i].width, mapObjects[i].height, mapObjects[i].rotation)
        map.pObjects[i].pBody = love.physics.newBody(physics, x, y, mapObjects[i].type)
        map.pObjects[i].color = utils.hex2rgb(mapObjects[i].properties.color)
		map.pObjects[i].pShape = love.physics.newRectangleShape(0,0, mapObjects[i].width, mapObjects[i].height, math.rad(mapObjects[i].rotation))
		map.pObjects[i].pFixRotation = mapObjects[i].properties.LockRot
        map.pObjects[i].data = mapObjects[i].properties.data
        map.pObjects[i].isSensor = mapObjects[i].properties.isTrigger
    end
    return map
end

loader.load = loadMap

return loader