-- R. Bassett Jr. 
-- 2026.07.08
-- A game level with some silly example code
-- GNU General Public License (GPLv3) - https://www.gnu.org/licenses/gpl-3.0.html

local level = {}

local startTime = 0
local endTime = 0

--
-- Objects and their properties
--

local player = {}
function level:resetPlayer()
	player = {
		x = mX/2, 
		y = mY-32,
		xv = 0,
		yv = 0, 
		size = 16,
		steering = 437.5, -- left/right acceleration
		handling = 250, -- top speed left/right
		responsiveness = 743.75, -- forward (up) acceleration
		acceleration = 150, -- forward (up) top speed
		deceleration = 160, -- backward (down) top speed
		brakes = 918.75, -- backward (down) acceleration
		jumps = diffData[diff].j, 
		health =  diffData[diff].h,
		shotTimer = 0,
		jumpTimer = 0,
		jumping = false,
		shooting = false,
		warpSpeed = 2, -- Really this is the radius of a circle ~(=^D)
		warpX = 0,
		warpY = 0,
		shots = 0,
		hits = 0
	}
end

-- Levels, which are just lists of enemies
local enemies = {
	require("levels/1"),
	require("levels/2"),
	require("levels/3"),
	require("levels/4"),
	require("levels/5"),
	require("levels/6"),
	require("levels/7"),
	require("levels/8"),
	require("levels/9"),
	require("levels/10"),
	require("levels/11"),
	require("levels/12"),
	require("levels/13"),
	require("levels/14"),
	require("levels/15"),
	require("levels/16"),
}
local enemiesTableSize = #enemies
local enemiesInLevelTableSize = 0 -- #enemies[currentLevel], updated in level:load()

local enemyDefaultHealth = {} -- Save here to reset at end of level

local enemyPositions = {
	-- row 1
	{
		{{100,60},{150,60},{200,60},{250,60},{300,60},{350,60},{400,60}}, 	-- rowGroup 1
		{{130,60},{180,60},{230,60},{280,60},{330,60},{380,60},{430,60}},		-- rowGroup 2
		{{160,60},{210,60},{260,60},{310,60},{360,60},{410,60},{460,60}},		-- rowGroup 3
		{{190,60},{240,60},{290,60},{340,60},{390,60},{440,60},{490,60}}, 	-- rowGroup 4
		{{220,60},{270,60},{320,60},{370,60},{420,60},{470,60},{520,60}},		-- rowGroup 5
	},
	-- row 2
	{
		{{100,120},{150,120},{200,120},{250,120},{300,120},{350,120},{400,120}},
		{{130,120},{180,120},{230,120},{280,120},{330,120},{380,120},{430,120}},
		{{160,120},{210,120},{260,120},{310,120},{360,120},{410,120},{460,120}},
		{{190,120},{240,120},{290,120},{340,120},{390,120},{440,120},{490,120}},
		{{220,120},{270,120},{320,120},{370,120},{420,120},{470,120},{520,120}},
	},
	-- row 3
	{
		{{100,180},{150,180},{200,180},{250,180},{300,180},{350,180},{400,180}},
		{{130,180},{180,180},{230,180},{280,180},{330,180},{380,180},{430,180}},
		{{160,180},{210,180},{260,180},{310,180},{360,180},{410,180},{460,180}},
		{{190,180},{240,180},{290,180},{340,180},{390,180},{440,180},{490,180}},
		{{220,180},{270,180},{320,180},{370,180},{420,180},{470,180},{520,180}},
	},
}
local rowGroup = 1 -- Tracks which group of rows is being displayed

local enemyColours = {
	{0, 1, 0},
	{0, 0, 1},
	{1, 0, 1},
	{1, 0, 0}
}

local enemyMove = 0
local enemyMoveDir = 1
local enemyShotTimer = 0
local enemiesAlive = 0
local enemyTotalHealthStart = 0
local enemyTotalHealth = 0

-- 0 is dead/available, 1 is enemy 1, 2 is enemy 2, 3 is the player
local bullets = {
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0},
	{owner = 0, x = 0, y = 0}
}
local bulletsTableSize = #bullets

local bulletSpec = {
	{speed = 300, acc = 1.5, size = 3, wobble = -1, dir = 1, c = {0,1,0.5}}, -- enemy 1
	{speed = 150, acc = 1, size = 14, wobble = -2, dir = 1, c = {0,1,1}}, -- enemy 2
	{speed = 700, acc = -0.8, size = 2, wobble = 1, dir = -1, c = {1,0.72,0}}, -- player
}

local gameProgress = {}
function level:resetGameProgress()
	gameProgress = {
		timePassed = 0, 
		score = 0, 
		accuracy = 0, 
		damageTaken = 0
	}
end

-- Gamepad single key press mapping
level.button_press = {
	back = function()
		states.Level:reset()
		level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end,
	start = function()
		level:doPause()
	end, 
	a = function()
		level:doJump()
	end,
	b = function()
		level:doShoot()
	end
}

-- Keyboard single key press mapping
level.key_press = {
	escape = function()
		states.Level:reset()
		level:resetGameProgress()
		activeState = "Start"
		currentLevel = 1
	end,
	p = function()
		level:doPause()
	end,
	space = function()
		level:doJump()
	end,
	lshift = function()
		level:doShoot()
	end
}

-- Gamepad and Keyboard movement
level.movement = {
	left = function(dt)
		player.xv = math.max(player.handling * -1, player.xv - player.steering * dt)
	end,
	right = function(dt)
		player.xv = math.min(player.handling, player.xv + player.steering * dt)
	end,
	up = function(dt)
		player.yv = math.max(player.acceleration * -1, player.yv - player.responsiveness * dt)
	end,
	down = function(dt)
		player.yv = math.min(player.deceleration, player.yv + player.brakes * dt)
	end
}

--
-- Level Functions
--

-- Called from the Start state or "main menu", where the game starts.
function level:load(lvl)
	currentLevel = lvl
	enemiesAlive = 0
	enemiesInLevelTableSize = #enemies[currentLevel]
	
	for i = 1, enemiesInLevelTableSize, 1 do
		enemyDefaultHealth[i] = enemies[currentLevel][i].health
		enemyTotalHealth = enemyTotalHealth + enemies[currentLevel][i].health
	end
	
	enemiesAlive = level:getEnemiesAlive()
	
	enemyTotalHealthStart = enemyTotalHealth
	
	level.resetPlayer()

	startTime = love.timer.getTime()
	activeState = "Level"
end


function level:reset()
	for i = 1, enemiesInLevelTableSize, 1 do
		enemies[currentLevel][i].health = enemyDefaultHealth[i]
		enemyDefaultHealth[i] =  0
	end
	
	for i = 1, bulletsTableSize, 1 do
		bullets[i].owner = 0
		bullets[i].x = 0
		bullets[i].y = 0
	end

	level:resetPlayer()
	startTime = 0
	endTme = 0
	enemyMove = 0
	enemyTotalHealthStart = 0
	enemyTotalHealth = 0
	enemiesAlive = 0
end


function level:doPause()
	if activeState ~= "Paused" then
		lastState = activeState
		activeState = "Paused"
	else
		activeState = lastState
	end
end


function level:getScore()
	local aBonus = 350 * (player.hits / math.max(1, player.shots)) -- Shot accuracy bonus
	
	local timeAlotted = diffData[diff].tb * enemyTotalHealthStart
	local tBonus = 250 * (timeAlotted / (endTime - startTime)) -- Time bonus
	if tBonus > 250 then tBonus = 250 end
	
	local lBonus = 100 * (enemyTotalHealthStart / enemyTotalHealth) -- Damage done to enemies bonus
	
	local dBonus = 300 * (player.health / diffData[diff].h) -- Damage avoidance bonus
	
	local score = math.floor(aBonus + dBonus + lBonus + dBonus)
	
	return score
end


function level:getTimeToWinString()
	local t = endTime - startTime
	local timeAlotted = diffData[diff].tb * enemyTotalHealthStart
	
	local txt = string.format("%." .. 0 .. "f", t) .. "s / " .. string.format("%." .. 0 .. "f", timeAlotted) .. "s "
	
	if t < timeAlotted then 
		txt = txt .." Bonus!"
	end
	
	return txt
end


function level:getTimePassed()
	local t = love.timer.getTime() - startTime
	
	return tonumber(string.format("%." .. 0 .. "f", t)) -- truncate decimal places
end


function level:getEndGame()
	if currentLevel == enemiesTableSize then
		return true
	end
	
	return false
end


function level:getAccuracy()
	local acc = (player.hits / math.max(1, player.shots)) * 100
	
	return tonumber(string.format("%." .. 0 .. "f", acc)) -- truncate decimal places
end


function level:getDamageString()
	local dBonus = 250 * (player.health / diffData[diff].h)
	txt = string.format("%." .. 0 .. "f", dBonus) .. " / 250 "
	
	if dBonus > 200 then
		txt = txt .. "Great!"
	elseif dBonus > 150 then
		txt = txt .. "Good"
	elseif dBonus > 50 then
		txt = txt .. "OK"
	else
		txt = txt .. "Dodge, Boss! Dodge!"
	end
	
	return txt
end


function level:getDamageTaken()
	return (diffData[diff].h - player.health)
end


function level:updateGameProgress(t, s, a, d)
		gameProgress.timePassed = gameProgress.timePassed  + t
		gameProgress.score = gameProgress.score + s
		gameProgress.damageTaken = gameProgress.damageTaken + d
		
		if currentLevel == 1 then
			gameProgress.accuracy = a
			
			return
		end
		
		gameProgress.accuracy = (gameProgress.accuracy + a) / 2
end


function level:getGameSummary()
	local sp = gameProgress.score / (enemiesTableSize * 1000) * 100
	
	local txt = "Time Played: " .. gameProgress.timePassed .. " Seconds\n\n"
	txt = txt .. "Score: " .. gameProgress.score .. " / " .. (enemiesTableSize * 1000) .."\n\n"
	txt = txt .. "Accuracy: " .. gameProgress.accuracy .. "%\n\n"
	txt = txt .. "Damage Taken: " .. gameProgress.damageTaken .. " / " .. (diffData[diff].h * enemiesTableSize) .. "\n"
	txt = txt .. "_________________________________\n\n"
	
	local grats = "Hey, at least you beat the game!"
	
	if sp > 95 then
		grats = "Incredible!"
	elseif sp > 90 then
		grats = "Amazing!"
	elseif sp > 80 then
		grats = "Awesome!"
	elseif sp > 70 then
		grats = "Nice!"
	elseif sp > 60 then
		grats = "Not Too Shabby"
	elseif sp > 50 then
		grats = "You've got some room to improve"
	end
	
	txt = txt .. grats .. "\n\n"
	
	return txt
end

--
-- Player Functions
--

function level:doJump()
	if player.jumping then
		return
	end 
	
	if player.jumps > 0 then
	player.jumps = player.jumps - 1
	player.jumping = true
	
	player.warpX = player.x
	player.warpY = player.y
	
	
	local jumpX = 0
	
	if (mX/2 - player.x) < 0 then
		jumpX = math.random(player.size, mX/4) -- Jump <--
	else
		jumpX = math.random(mX - player.size, mX - mX/4) -- Jump -->
	end
	
	player.x = jumpX
	player.y = math.random(mY - player.size * 6, mY - player.size - 24)
	end
end


function level:doShoot()
	if player.jumping then
		return
	end 

	if player.shooting then
		return
	end 
	
	-- Find an available bullet and shoot
	for i = 1, bulletsTableSize, 1 do
		if bullets[i].owner == 0 then
			bullets[i].owner = 3
			bullets[i].x = player.x
			bullets[i].y = player.y
			player.shooting = true
			player.shotTimer = 0
			break
		end	
	end
	
	player.shots = player.shots + 1
end

--
-- Enemy Functions
--

function level:getEnemiesAlive()
	local e = 0
	
	for i = 1, enemiesInLevelTableSize, 1 do
		if enemies[currentLevel][i].health > 0 then
			e = e + 1
		end
	end
	
	return e
end


-- Indexed to deal with differences between square and circles
local drawEnemyShapes = {
	function(x, y)
		love.graphics.rectangle("fill", x-16, y-16, 32, 32) -- enemy 1
	end,
	function(x, y)
		love.graphics.circle("fill", x, y, 16) -- enemy 2
	end
}


function level:enemyGetRowSlot(e)
	if enemies[currentLevel][e].row == 2 then
		e = e - 7
	elseif enemies[currentLevel][e].row == 3 then
		e = e - 14
	elseif enemies[currentLevel][e].row == 4 then
		e = e - 21
	end
	
	return e
end


function level:doEnemyShot()
	if level:getEnemiesAlive() < 1 then
		return
	end

	local rng = 0
	local reasonableEffort = 0
	
	while true do
		 rng = math.random(1, enemiesInLevelTableSize)
		 
		 if enemies[currentLevel][rng].health > 0 then
			break
		 end
		 
		 reasonableEffort = reasonableEffort + 1
		 
		 if reasonableEffort > 16 then
			return
		 end
	end
		
	if enemies[currentLevel][rng].health == 0 then
		return
	end
	
	-- Limit how often each time of enemy actually fires
	if math.random(1, 100) < diffData[diff].er[enemies[currentLevel][rng].shape] then
		return
	end
	
	local rowSlot = level:enemyGetRowSlot(rng)
	
	-- Find an available bullet and shoot
	for i = 1, bulletsTableSize, 1 do
		if bullets[i].owner == 0 then
			bullets[i].owner = enemies[currentLevel][rng].shape
			bullets[i].x = enemyPositions[enemies[currentLevel][rng].row][rowGroup][rowSlot][1]
			bullets[i].y = enemyPositions[enemies[currentLevel][rng].row][rowGroup][rowSlot][2]
			break
		end	
	end
end

--
-- Game Loop Functions:
--

function level:update(dt)
	-- Check for win
	if enemiesAlive < 1 then
		endTime = love.timer.getTime()
		activeState = "Win"
		
		return
	end
	
	-- Check for loss
	if player.health < 1 then
		activeState = "Lose"
		return
	end
	
	-- Update bullets
	local enemyX = 0
	local rowSlot = 1
	local a, b, c = 0 
	local accel = 0
	
	for i = 1, bulletsTableSize, 1 do
		if bullets[i].owner > 0 then
			-- Update position
			accel = diffData[diff].baf / (mY - bullets[i].y / 2) * bulletSpec[bullets[i].owner].acc
			bullets[i].y = bullets[i].y + bulletSpec[bullets[i].owner].speed * bulletSpec[bullets[i].owner].dir * dt + accel
			
			-- Round bullet pathing
			if bullets[i].owner == 2 then
				if math.mod(i, 2) == 0 then
					bullets[i].x = bullets[i].x + math.sin(bullets[i].y*dt)*1.18 -- evens shoot right
				else
					bullets[i].x = bullets[i].x + math.sin(bullets[i].y*dt)*1.18 * -1 -- odds shoot left
				end
			end
			
			-- Kill if off the screen
			if bullets[i].y > mY then
				bullets[i].owner = 0
			end
			
			if bullets[i].y < 0 then
				bullets[i].owner = 0
			end
			
			-- Do collisions
			if bullets[i].owner > 0 then
				if  bullets[i].owner == 3 then
					-- Player's bullet, check all living enemy positions
					for j = 1, enemiesInLevelTableSize, 1 do
						-- Lua 5.1 doesn't have a continue/next loop jump, so we need to check bullets[i].owner > 0 
						if enemies[currentLevel][j].health > 0 and bullets[i].owner > 0 then
							rowSlot = level:enemyGetRowSlot(j)

							a = (bullets[i].x - enemyPositions[enemies[currentLevel][j].row][rowGroup][rowSlot][1])
							b = (bullets[i].y - enemyPositions[enemies[currentLevel][j].row][rowGroup][rowSlot][2])
							c = a*a + b*b
						
							-- "Compare the square, because sqrts hurts", so I read, in fancier words.
							if c < (bulletSpec[bullets[i].owner].size + 16)^2 then
								enemies[currentLevel][j].health = math.max(0, enemies[currentLevel][j].health - 1) -- HIT!
								
								if enemies[currentLevel][j].health == 0 then
									enemiesAlive = enemiesAlive - 1
								end 
								
								bullets[i].owner = 0 -- Destroyed!
								player.hits = player.hits + 1
							end
						end
					end
				else
					-- Enemy's bullet, check player's position
					a = math.abs(bullets[i].x - player.x)
					b = math.abs(bullets[i].y - player.y)
					c = a*a + b*b
									
					if c < (player.size + bulletSpec[bullets[i].owner].size)^2 and not player.jumping then
						player.health = math.max(0, player.health - diffData[diff].ed[bullets[i].owner]) -- HIT!
						bullets[i].owner = 0 -- Destroyed!
					end
				end
			end
		end
	end
	
	-- Move enemies
	enemyMove = enemyMove + dt
	if math.floor(enemyMove) == 1 then
		if rowGroup == 5 then enemyMoveDir = -1 end
		if rowGroup == 1 then enemyMoveDir = 1 end
	
		rowGroup = rowGroup + enemyMoveDir	
		enemyMove = 0
	end
	
		-- Enemy shots
	enemyShotTimer = enemyShotTimer + dt
	
	if enemyShotTimer > diffData[diff].fr then
		level:doEnemyShot()
		enemyShotTimer = 0
	end
	
	-- Get player input
	if player.jumping then
		player.jumpTimer = player.jumpTimer + dt
		if math.floor(player.jumpTimer) == 2 then
			player.jumping = false
			player.jumpTimer = 0
		end
		
		player.xv = 0
		player.yv = 0
		
		return
	end
	
	if player.shooting then
		player.shotTimer = player.shotTimer + dt
		
		if player.shotTimer > 0.16 then
			player.shooting = false
			player.shotTimer = 0
		end
	end
	
	local doingKeys = false
	
	-- Keyboard continuous input
	if love.keyboard.isDown("left", "a") then
		level.movement.left(dt)
		doingKeys = true
	end
	if love.keyboard.isDown("right", "d") then
		level.movement.right(dt)
		doingKeys = true
	end
	if love.keyboard.isDown("up", "w") then
		level.movement.up(dt)
		doingKeys = true
	end
	if love.keyboard.isDown("down", "s") then
		level.movement.down(dt)
		doingKeys = true
	end
		

	-- Don't do gamepad if doing joystick and prevent crash from happening when acting upon a nil object
	if joystick and not doingKeys then 	
		-- Gamepad continuous input
		if joystick:isGamepadDown("dpleft") then
			level.movement.left(dt)
		end
		if joystick:isGamepadDown("dpright") then
			level.movement.right(dt)
		end

		if joystick:isGamepadDown("dpup") then
			level.movement.up(dt)
		end
		if joystick:isGamepadDown("dpdown") then
			level.movement.down(dt)
		end
	end
	
	player.x = player.x + player.xv*dt
	player.xv = player.xv * 0.99
	player.y = player.y + player.yv*dt
	player.yv = player.yv * 0.99
	
	-- Clamp player position to desired part of the screen
	if player.x > mX - player.size then
		player.x = mX - player.size
	elseif player.x < player.size then
		player.x = player.size
	end
	
	if player.y > mY - player.size - 18 then
		player.y = mY - player.size - 18
	elseif player.y < mY - player.size * 6 then
		player.y = mY - player.size * 6 
	end
end


function level:draw()
	-- Draw bullets
	for i = 1, bulletsTableSize, 1 do
		if bullets[i].owner > 0 then
			love.graphics.setColor(bulletSpec[bullets[i].owner].c)
			love.graphics.circle("fill", bullets[i].x, bullets[i].y, bulletSpec[bullets[i].owner].size + math.random(bulletSpec[bullets[i].owner].wobble,2))
		end
	end
	
	-- Draw enemies
	local rowSlot = 1
	for i = 1, enemiesInLevelTableSize, 1 do
		if enemies[currentLevel][i].health > 0 then			
			love.graphics.setColor(enemyColours[enemies[currentLevel][i].health])
			
			rowSlot = level:enemyGetRowSlot(i)
			 
			drawEnemyShapes[enemies[currentLevel][i].shape](
				enemyPositions[enemies[currentLevel][i].row][rowGroup][rowSlot][1], -- x
				enemyPositions[enemies[currentLevel][i].row][rowGroup][rowSlot][2] -- y
			)
		end
	end
		
	-- Draw Player
	if not player.jumping then
		love.graphics.setColor(0.3, 0, 0.3, 1)
		love.graphics.circle("fill", player.x, player.y, player.size)
		love.graphics.setColor(1, 0.4, 0.2, 1)
		love.graphics.circle("line", player.x, player.y, player.size)
		love.graphics.rectangle("fill", player.x-5, player.y-24, 10, 40)
		love.graphics.rectangle("fill", player.x-2, player.y-28, 4, 4)
		love.graphics.setColor(0.5, 0, 0.5, 1)
		love.graphics.rectangle("line", player.x-5, player.y-24, 10, 40)
		player.warpSpeed = 2
	else
		love.graphics.setColor(0.667, 1, 0.933)
		-- Warp entrance
		love.graphics.circle("line", player.warpX, player.warpY, math.max(2, 20 - player.warpSpeed))
		love.graphics.circle("line", player.warpX, player.warpY, math.max(1, 12 - player.warpSpeed))
		
		-- Warp exit
		love.graphics.circle("line", player.x, player.y, math.min(player.warpSpeed, 10))
		love.graphics.circle("line", player.x, player.y, math.min(player.warpSpeed, 20))
		
		player.warpSpeed = player.warpSpeed + 0.16
	end
	
	-- Bottom background
	love.graphics.setColor(0.2, 0.2, 0.2)
	love.graphics.rectangle("fill", 0, mY-18, mX, 18)
	
	-- Player Health UI
	love.graphics.setColor(0, 1, 0)
	if player.health < 30 then
		love.graphics.setColor(1, 0, 0) -- red
	elseif player.health < 60 then
		love.graphics.setColor(1, 1, 0) -- yellow
	end
	love.graphics.rectangle("fill", 8, mY-16, player.health*2, 14)
	
	-- Player jumps UI
	love.graphics.setColor(0, 0.588, 0.992)
	for i = 1, player.jumps, 1 do
		love.graphics.rectangle("fill", mX - i*20 - 4, mY-16, 14, 14)
	end
end

return level