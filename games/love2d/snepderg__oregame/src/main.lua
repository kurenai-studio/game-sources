--! file: main.lua

local lldebugger = require( "lib.debug" )

local UPGRADER_PIXEL_OFFSET = 2 -- The texture is offset by 2 pixels.

local COLOR_WHITE = { 1, 1, 1, 1 }
local COLOR_ORE = { 0, 0.5, 1, 1 }
local COLOR_BEAM = { 0, 1, 1, 0.3 }

local ores = {}

local upgrader = {}
local beam = {}

function love.load()
    upgrader.x = 200
    upgrader.y = 200
    upgrader.size = 4
    upgrader.image = love.graphics.newImage( "img/upgrader.png" )
    upgrader.width = upgrader.image:getWidth() * upgrader.size
    upgrader.height = upgrader.image:getHeight() * upgrader.size
    upgrader.beam = beam

    upgrader.image:setFilter( "nearest", "nearest" )

    beam.x = upgrader.x + ( upgrader.width / 2 ) - upgrader.size * 2
    beam.y = upgrader.y + upgrader.size * UPGRADER_PIXEL_OFFSET
    beam.width = 4 -- why?
    beam.height = upgrader.height - upgrader.size * 4
    beam.color = COLOR_BEAM

    print( beam.width )
end

local function makeOre()
    local ore = {}
    ore.x = 100
    ore.y = 190 + upgrader.height / 2
    ore.width = 20
    ore.height = 20
    ore.speed = 50
    ore.color = COLOR_ORE

    table.insert( ores, ore )
end

function love.keypressed( key )
    if key == "space" then
        makeOre()
    end
end

local function checkCollisions( a, b )
    local aLeft = a.x
    local aRight = a.x + a.width
    local aTop = a.y
    local aBottom = a.y + a.height

    local bLeft = b.x
    local bRight = b.x + b.width
    local bTop = b.y
    local bBottom = b.y + b.height

    return aRight > bLeft
        and aLeft < bRight
        and aBottom > bTop
        and aTop < bBottom
end

function love.update( dt )
    for _, ore in ipairs( ores ) do
        ore.x = ore.x + ore.speed * dt

        if checkCollisions( ore, beam ) then
            ore.color = COLOR_BEAM
        end
    end
end

function love.draw()
    love.graphics.draw( upgrader.image, upgrader.x, upgrader.y, nil, upgrader.size, upgrader.size )

    for _, ore in ipairs( ores ) do
        love.graphics.setColor( ore.color )
        love.graphics.rectangle( "fill", ore.x, ore.y, ore.width, ore.height )
    end

    love.graphics.setColor( beam.color )
    love.graphics.rectangle( "fill", beam.x, beam.y, beam.width * upgrader.size, beam.height )
    love.graphics.setColor( COLOR_WHITE )
end