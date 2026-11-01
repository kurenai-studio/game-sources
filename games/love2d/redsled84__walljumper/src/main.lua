math.randomseed(os.time())
local map01 = require 'maps.map_01'
local solids = {}
local world = require 'world'
local timer = require 'timer'
local player = require 'player'
local particles = require 'particles'
local map = require 'map'
local camera = require 'camera'

local cam = camera()

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function love.load()
	world.load()
	player:load(64, 32, 32, 32)
	player:setSpawn(64, 32)
	map:load()

	love.graphics.setBackgroundColor(205,205,205)
end

local printTimer = timer:new(1)
function love.update(dt)
	--[[
	printTimer:update(dt, function()
		print(collectgarbage('count'))
	end)
	--]]
	player:update(dt)
	particles:update(dt)
	-- cam:lookAt(math.floor(player.x), math.floor(player.y))
	cam:lookAt(round(player.x, 0), round(player.y, 0))
end

function love.draw()
	cam:attach()

	
	player:draw({255, 0, 0})

	love.graphics.setColor(255,255,255)
	map:drawTiles()
	local items, len = world.bump:getItems()
	map:drawCoins(items, len)
	
	local fps = tostring(love.timer.getFPS())
	love.graphics.print(fps)

	particles:draw()

	cam:detach()

	love.graphics.setColor(255,255,255)
	love.graphics.print(player.score, 10, 10)

	if player.dead then
		love.graphics.setColor(0,0,0)
		love.graphics.print("DEAD", love.graphics.getWidth()/2, love.graphics.getHeight()/2)
	end
end

function love.keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end
	if key == 'r' then
		love.event.quit('restart')
	end

	player:jump(key)
end