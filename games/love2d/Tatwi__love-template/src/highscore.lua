-- R. Bassett Jr. 
-- 2026.07.20
-- High Score screen
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local highscore = {}

local onload = true
local txtNav = ""
local showing = 5
local ol = 1
local page = 0
local overallHeadings = ""
local overallHL = ""
local overallLevelNames = ""
local overallScores = ""
local levelHeadings = ""
local levelNumbers = ""
local levelScores = ""


highscore.layout ={
	function()
		love.graphics.printf(overallHeadings, 0, 40, mX, "center", 0, 1, 1)
		love.graphics.printf(overallHL, 180, 120, 600, "left", 0, 1, 1)
		love.graphics.printf(overallLevelNames, 280, 120, 600, "left", 0, 1, 1)
		love.graphics.printf(overallScores, 425, 120, 600, "left", 0, 1, 1)
		love.graphics.printf(txtNav, 0, mY-160, mX, "center", 0, 1, 1)
	end,
	function()
		love.graphics.printf(levelHeadings, 0, 40, mX, "center", 0, 1, 1)
		love.graphics.printf(levelNumbers, 260, 120, 600, "left", 0, 1, 1)
		love.graphics.printf(levelScores, 360, 120, 600, "left", 0, 1, 1)
		love.graphics.printf(txtNav, 0, mY-160, mX, "center", 0, 1, 1)
	end
}

highscore.changePage = {
	left = function()
		showing = showing - 1
		page = 0
	end,
	right = function()
		showing = showing + 1
		page = 0
	end,
	up = function()
		page = page + 1
	end,
	down = function()
		page = page - 1
	end
}

-- Gamepad single key press mapping
highscore.button_press = {
	back = function()
		highscore:reset()
		activeState = "Start"
	end,
	dpleft = function()
		highscore.changePage.left()
	end,
	dpright = function()
		highscore.changePage.right()
	end,
	dpup = function()
		highscore.changePage.up()
	end,
	dpdown = function()
		highscore.changePage.down()
	end	
}

-- Keyboard single key press mapping
highscore.key_press = {
	escape = function()
		highscore:reset()
		activeState = "Start"
	end,
	left = function()
		highscore.changePage.left()
	end, 
	right = function()
		highscore.changePage.right()
	end,
	up = function()
		highscore.changePage.up()
	end,
	down = function()
		highscore.changePage.down()
	end
}

function highscore:reset()
	onload = true
	txtNav = ""
	showing = 5
	ol = 1
	page = 0
	overallHeadings = ""
	overallHL = ""
	overallLevelNames = ""
	overallScores = ""
	levelHeadings = ""
	levelNumbers = ""
	levelScores = ""
end


function highscore:onLoad()
	if not onload then
		return
	end

	showing = 5
	ol = 1
	
	onload = false
end


function highscore:update(dt)
	highscore:onLoad()
	
	overallHeadings = ""
	overallHL = ""
	overallLevelNames = ""
	overallScores = ""
	levelHeadings = ""
	levelNumbers = ""
	levelScores = ""
	
	-- Overall, Each level in Normal, Easy, Hard, Crazy modes
	if showing > 5 then
		showing = 1
	end
	if showing < 1 then
		showing = 5
	end
	
	if page > 1 then
		page = 0
	end
	if page < 0 then
		page = 1
	end
	
	if showing == 5 then
		ol = 1
		overallHeadings = "Overall Progress\n\nLevel          Difficulty           Score"
	
		for i = 1, 4, 1 do
			overallHL = overallHL .. savemgr:getHighestLevel(i) .. "\n\n"
			overallLevelNames = overallLevelNames .. diffData[i].n ..  "\n\n"
			overallScores = overallScores .. savemgr:getDiffHS(i) .. "\n\n"
		end
		
		txtNav = "Navigation\n\n(LEFT)                     (RIGHT)\n\nESC or (Back) to Exit"
	else
		ol = 2
		levelHeadings = diffData[showing].n .. "\n\nLevel          Score"

		for i = 1, 8, 1 do
			levelNumbers = levelNumbers .. i + (8 * page) .. "\n"
			levelScores = levelScores .. savemgr:getLevelHS(showing, i + (8 * page)) .. "\n"
			
			txtNav = "Navigation\n\n(LEFT)     (UP)     (DOWN)     (RIGHT)\n\nESC or (Back) to Exit"
		end
	end
end


function highscore:draw()
	highscore.layout[ol]()
end

return highscore