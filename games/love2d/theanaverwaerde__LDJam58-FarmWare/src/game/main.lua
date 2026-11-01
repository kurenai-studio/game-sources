Object = require "lib.classic"
GameSize = 600

local games  = {
	require "wheatGame",
	require "appleGame",
	require "chickenGame",
}

local transitionScreen
local loseScreen

local scene
local currentGameIdx = 0

Stage = 0
Playing = true
Life = 3

local gameSpeed = 1
local gameSpeedStep = .4



function love.load()
	scene = require "titleScreen"()
	transitionScreen = require "transitionScreen"()
	loseScreen = require "loseScreen"
	local music = love.audio.newSource("assets/wolfram.wav", "stream")
	music:setVolume(0.3)
	music:setLooping(true)
	music:play()
end

function love.update(dt)
	if Playing then
		scene:update(dt * gameSpeed)
	end
	transitionScreen:update(dt)
end

function love.draw()
	scene:draw()
	transitionScreen:draw()
end

function NextScene(win)
	if win then
		gameSpeed = gameSpeed + gameSpeedStep
	else
		Life = Life - 1
		if Life <= 0 then
			print("Game Over!")
			gameSpeed = 1
			scene = loseScreen()
			return
		end
	end

	Stage = Stage + 1

	transitionScreen:trigger(win)

	local newIdx
	repeat
		newIdx = math.random(1, #games)
	until newIdx ~= currentGameIdx

	currentGameIdx = newIdx

end

function ApplyNextScene()
	scene = games[currentGameIdx]()
end

function ResetGame()
	Stage = 0
	Life = 3
	gameSpeed = 1
	currentGameIdx = 0
	NextScene(true)
end
