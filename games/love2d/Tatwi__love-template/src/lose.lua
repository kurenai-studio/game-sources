-- R. Bassett Jr. 
-- 2026.07.20
-- Lose / Game Over screen
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local lose = {}

local onload = true
local score = 0
local scoreTxt = ""
local timeTaken = ""
local accuracy = 0
local isNewHighScore = false
local txt = ""

-- Gamepad single key press mapping
lose.button_press = {
	back = function()
		lose:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end
}

-- Keyboard single key press mapping
lose.key_press = {
	escape = function()
		lose:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end
}

function lose:reset()
	onload = true
	score = 0
	timeTaken = ""
	accuracy = 0
	isNewHighScore = false
	txt = ""
end

function lose:onLoad()
	if not onload then
		return
	end
	
	score = states.Level:getScore()
	isNewHighScore = savemgr:compare(diff, currentLevel, score)
	timeTaken = states.Level:getTimePassed()
	accuracy = states.Level:getAccuracy()
	
	if isNewHighScore then
		savemgr:setHS(diff, currentLevel, score)
		scoreTxt = txt .. "New High Score!\n" .. score .. " / 1000\n\n"
	else
		scoreTxt = txt .. "Score:\n" .. score .. " / 1000\n\n"
	end
	
	txt = "Level " .. currentLevel .. " Failed\n\n\nGame Over\n\n\n"
	txt = txt .. scoreTxt
	txt = txt .. "Accuracy:\n " .. accuracy .. "%\n\n"
	txt = txt .. "Time:\n" .. timeTaken .. "\n\n\n"
	txt = txt .. "ESC or (Back) to Exit"
	
	-- Gathered and used all level data, reset it now.
	states.Level:reset()
	
	onload = false
end


function lose:update(dt)
	lose:onLoad()
end


function lose:draw()
	love.graphics.printf(txt, 0, 20, mX, "center", 0, 1, 1)
end

return lose