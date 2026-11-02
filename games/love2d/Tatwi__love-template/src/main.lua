-- R. Bassett Jr. 
-- 2026.07.08
-- Starting point for a game that uses game states
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

function love.load()
	-- Max window size
	mX, mY = 640, 480
	
	-- Canvas scale. Everything is drawn onto it, so it must be scaled when switching to fullscreen.
	csX, csY = 1, 1
	
	-- Canvas position
	cX, cY = 0, 0
	
	canvas = love.graphics.newCanvas(mX, mY)
	
	font = love.graphics.newFont(18)
	love.graphics.setFont(font)
	
	states = {}
	states.Start = require("start")
	states.Paused = require("paused")
	states.Level = require("level")
	states.Win = require("win")
	states.Lose	= require("lose")
	states.EndGame = require("endgame")
	states.HighScore = require("highscore")
	activeState = "Start"
	lastState = "Start"	
	currentLevel = 1
	
	saveData = {}
	savemgr = require("savemgr")
	
	if not savemgr:saveExists() then
		saveData = savemgr:createSaveData()
	else
		saveData = savemgr:loadSaveData()
	end
	
	-- Difficulty
	diff = 1
	
	-- fr: How quickly the enemies have a chance to fire
	-- er: The likelihood an enemy will fire when given the chance
	-- h: The player's health
	-- j: How many jumps/warps the player can make
	-- ed: Enemy damage, Square, Circles
	-- n: The name of the difficulty setting
	-- tb: Time(s) per enemy health point the player has to earn the full 250 time bonus points
	-- baf: Bullet acceleration factor. Larger numbers increase the pace of the game.
	diffData = {
		{fr = 0.33, h = 200, j = 6, tb = 3, n = "Normal", baf = 400, ed = {8, 15}, er = {50, 30}},
		{fr = 1.2, h = 200, j = 10, tb = 5, n = "Easy", baf = 100, ed = {2, 8}, er = {70, 50}},
		{fr = 0.28, h = 150, j = 4, tb = 2, n = "Hard", baf = 700, ed = {8, 20}, er = {40, 20}},
		{fr = 0.24, h = 100, j = 3, tb = 1, n = "Crazy", baf = 1000, ed = {10,25}, er = {30, 15}},
	}
		
	local joysticks = love.joystick.getJoysticks()
	joystick = joysticks[1]
end


local function toggleFullscreen()
	fullscreen = not fullscreen
	love.window.setFullscreen(fullscreen, "exclusive")
	
	if fullscreen then
		-- scale the canvas
		local fsX, fsY = love.graphics.getDimensions()
		csX = fsX / mX
		csY = fsY / mY
		
		-- Maintain 4:3 aspect ratio and center on wide screens
		if csY ~= csX then
			csX = csY
			cX = (fsX - mX * csX) / 2
		end
	else
		csX, csY = 1, 1
		cX = 0
	end
end


function love.update(dt)
	states[activeState]:update(dt)
end


function love.draw()
	love.graphics.setCanvas(canvas)
		love.graphics.clear(0, 0, 0, 0)
		states[activeState]:draw()
	love.graphics.setCanvas()
	
	love.graphics.setBlendMode("alpha")
	love.graphics.setColor(1, 1, 1, 1)
	
	love.graphics.draw(canvas, cX, cY, 0, csX, csY)
end


function love.gamepadpressed(joystick, button)
	if states[activeState].button_press[button] then
		states[activeState].button_press[button]()
	end
	
	if button == "guide" then
		toggleFullscreen()
	end
end


function love.keypressed(key)
	if states[activeState].key_press[key] then
		states[activeState].key_press[key]()
	end
	
	if key == "f11" then
		toggleFullscreen()
	end
end