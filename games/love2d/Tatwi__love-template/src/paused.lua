-- R. Bassett Jr. 
-- 2026.07.08
-- Paused screen
-- Game time still passes to prevent manipulation of the score 
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local paused = {}

local txt = ""

-- Gamepad single key press mapping
paused.button_press = {
	back = function()
		states.Level:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end,
	start = function()
		if activeState ~= "Paused" then
			lastState = activeState
			activeState = "Paused"
		else
			activeState = lastState
		end
	end
}

-- Keyboard single key press mapping
paused.key_press = {
	escape = function()
		states.Level:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end,
	p = function()
		if activeState ~= "Paused" then
			lastState = activeState
			activeState = "Paused"
		else
			activeState = lastState
		end
	end
}


function paused:update(dt)
	txt = "GAME PAUSED\n\n\nTime passed in this level: " .. states.Level:getTimePassed() .. "s"
end


function paused:draw()
	love.graphics.printf(txt, 0, mY/2-60, mX, "center", 0, 1, 1)
end


return paused