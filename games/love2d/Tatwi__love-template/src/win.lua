-- R. Bassett Jr. 
-- 2026.07.20
-- Win / Level Complete screen
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local win = {}

local onload = true
local score = 0
local timeTaken = ""
local accuracy = 0
local damage = ""
local isNewHighScore = false
local txt = ""
local txtWinT = ""
local txtWinB = ""
local txtScore = ""

-- Gamepad single key press mapping
win.button_press = {
	back = function()
		win:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end,
	a = function()
		if states.Level:getEndGame() then
			win:reset()
			--states.Level:reset() -- THE BUG HAPPENS HERE. 
			activeState = "EndGame"
		else
			win:reset()
			states.Level:load(currentLevel + 1)
		end	
	end
}

-- Keyboard single key press mapping
win.key_press = {
	escape = function()
		win:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end,
	space = function()
		if states.Level:getEndGame() then
			win:reset()
			activeState = "EndGame"
		else
			win:reset()
			states.Level:load(currentLevel + 1)
		end
	end
}

function win:reset()
	onload = true
	score = 0
	timeTaken = ""
	accuracy = 0
	damage = ""
	isNewHighScore = false
	txt = ""
end


function win:onLoad()
	if not onload then
		return
	end
	
	score = states.Level:getScore()
	isNewHighScore = savemgr:compare(diff, currentLevel, score)
	timeTaken = states.Level:getTimeToWinString()
	accuracy = states.Level:getAccuracy()
	damage = states.Level:getDamageString()
	
	local dmg = states.Level:getDamageTaken()
	local timePassed = states.Level:getTimePassed()
	
	states.Level:updateGameProgress(timePassed, score, accuracy, dmg)
	
	-- Gathered and used all level data, reset it now.
	states.Level:reset()
	
	if isNewHighScore then
		savemgr:setHS(diff, currentLevel, score)
		txtScore = txt .. "New High Score!\n" .. score .. " / 1000\n\n"
	else
		txtScore = txt .. "Score:\n" .. score .. " / 1000\n\n"
	end
	
	if states.Level:getEndGame() then
		txtWinT = "Final Level Complete - You Win!\n\n"
		txtWinB = "Press SPACE or (A) to for Game Summary\n\nESC or (Back) to Quit"
	else
		txtWinT = "Level " .. currentLevel .. " Complete!\n\n"
		txtWinB = "Press SPACE or (A) to Continue\n\nESC or (Back) to Exit"
	end
	
	txt = txtWinT
	txt = txt .. txtScore
	txt = txt .. "Time:\n" .. timeTaken .. "\n\n"
	txt = txt .. "Accuracy:\n " .. string.format("%." .. 0 .. "f", accuracy) .. "%\n\n"
	txt = txt .. "Damage Avoidance:\n" .. damage .. "\n\n\n"
	txt = txt .. txtWinB
	
	onload = false
end


function win:update(dt)
	win:onLoad()
end


function win:draw()
	love.graphics.printf(txt, 0, 20, mX, "center", 0, 1, 1)
end

return win