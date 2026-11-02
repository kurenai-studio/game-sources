-- R. Bassett Jr. 
-- 2026.07.08
-- Start screen
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local start = {}

local onload = true
local waitingForSave = false
local waitTimer = 0
local txt = ""
local txtMenuT = ""
local txtMenuD = ""
local txtMenuB = ""
local txtSave = ""

-- Gamepad single key press mapping
start.button_press = {
	back = function()
		if not waitingForSave then
			savemgr:writeSaveData()
		end
		
		waitingForSave = true
	end,
	start = function()
		if activeState ~= "Level"  and activeState ~= "Paused" then
			currentLevel = 1
			states.Level:load(currentLevel)
		end
	end,
	x = function()
		diff = diff + 1
		if diff > 4 then diff = 1 end
	end,
	y = function()
		activeState = "HighScore"
	end
}

-- Keyboard single key press mapping
start.key_press = {
	escape = function()
		if not waitingForSave then
			savemgr:writeSaveData()
		end
		
		waitingForSave = true
	end,
	space = function()
		if activeState ~= "Level" and activeState ~= "Paused" then
			currentLevel = 1
			states.Level:load(currentLevel)
		end
	end,
	x = function()
		diff = diff + 1
		if diff > 4 then diff = 1 end
	end,
	h = function()
		activeState = "HighScore"
	end
}

function start:onLoad()
	if not onload then
		return
	end

	currentLevel = 1
	states.Level:resetGameProgress()

	txtSave = "\n\n\n\n\n\n\n\nSaving..."
	txtMenuT = "Example Game!\n_________________________________\n\n\n\n"
	txtMenuB = "Press X or (X) to change Difficulty\n\n"
	txtMenuB = txtMenuB .. "Press H or (Y) for High Scores\n\n"
	txtMenuB = txtMenuB .. "F11 or (Menu) to Toggle Fullscreen\n\n\n\n"
	txtMenuB = txtMenuB .. "Press SPACE or (Start) to Play\n\n\n\n"
	txtMenuB = txtMenuB .. "ESC or (Back) to Save and Quit"
	
	onload = false
end


function start:update(dt)
	start:onLoad()

	if waitingForSave then
		waitTimer = waitTimer + dt
		
		if waitTimer > 2 then
			love.event.quit()
		end
		
		txt = txtSave
		
		return
	end
	
	txtMenuD = "Difficulty: ".. diffData[diff].n .. "\n\n\n"
	txt = txtMenuT .. txtMenuD .. txtMenuB
end


function start:draw()
	love.graphics.printf(txt, 0, 20, mX, "center", 0, 1, 1)
end

return start