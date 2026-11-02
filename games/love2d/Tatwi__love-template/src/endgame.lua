-- R. Bassett Jr. 
-- 2026.07.23
-- End Game screen
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local endgame = {}

local onload = true
local txt = ""

-- Gamepad single key press mapping
endgame.button_press = {
	back = function()
		endgame:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end
}

-- Keyboard single key press mapping
endgame.key_press = {
	escape = function()
		endgame:reset()
		states.Level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end
}

function endgame:reset()
	onload = true
	txt = ""
end

function endgame:onLoad(dt)
	if not onload then
		return
	end
	
	txt = diffData[diff].n .. " Mode\nCompletion Summary\n_________________________________\n\n"
	txt = txt .. states.Level:getGameSummary()
	
	txt = txt .. "Thanks for playing!\n\nPress ESC or (Back) to Exit\n\n\nR.Bassett Jr. (Tatwi) 2026"
	
	currentLevel = 1
	
	onload = false
end


function endgame:update(dt)
	endgame:onLoad()
end


function endgame:draw()
	love.graphics.printf(txt, 0, 20, mX, "center", 0, 1, 1)
end

return endgame