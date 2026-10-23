Object   = require "classic"
Asteroid = require "asteroid"
local AsteroidManager = Object:extend()


peakDifficultyTime = 60
maxAsteroidCount = 30


function AsteroidManager:new()
	self.milestone = 0
	self.milestoneTimer = 0
	self.asteroids = {}
	self.pauseState = true 
	self.soundvol = 0
end


function AsteroidManager:addAsteroids(count)
	msg = "Creating " .. count .. " asteroid"
	if count == 1 then msg = msg .. "." else msg = msg .. "s." end
	print(msg)
	for i = 0, count do
		asteroid = Asteroid(self)
		table.insert(self.asteroids, asteroid)
	end
end


function AsteroidManager:easeInQuad(x)
	return x * x
end


function AsteroidManager:update(dt)
	if self.pauseState then
		return
	end
	self.milestoneTimer = self.milestoneTimer + dt
	easedTime = self:easeInQuad(self.milestoneTimer / peakDifficultyTime)
	if self.milestone < easedTime and easedTime <= 1.0 then
		self.milestone = self.milestone + 1.0 / maxAsteroidCount
		print("Milestone #" .. self.milestone * maxAsteroidCount .. " reached.")
		self:addAsteroids(1)
	end
	for i, asteroid in pairs(self.asteroids) do
		asteroid:update(dt)
	end
end


function AsteroidManager:draw()
	for i, asteroid in pairs(self.asteroids) do
		asteroid:draw()
	end
end


function AsteroidManager:laserBeginContact(node)
	if node:is(Asteroid) then
		node.damage = node.damage + 1
	end
end

function AsteroidManager:laserEndContact(node)
	if node:is(Asteroid) then
		if node.damage > 0 then
			node.damage = node.damage - 1
		end
	end
end


function AsteroidManager:onAsteroidDestroy(asteroid)
	session:addScore(asteroid.score)
	asteroid:reset()
end


function AsteroidManager:onGameOver()
	self:pause(true)
end


function AsteroidManager:pause(state)
	self.pauseState = state
	for i, asteroid in pairs(self.asteroids) do
		asteroid:pause(state)
	end
end


function AsteroidManager:setVolume(vol)
	self.soundvol = vol
	for i, asteroid in pairs(self.asteroids) do
		asteroid.sound:setVolume(vol)
	end
end


function AsteroidManager:reset()
	for i, asteroid in pairs(self.asteroids) do
		asteroid:destroy()
		self.asteroids[i] = nil
	end
	self.milestone = 0
	self.milestoneTimer = 0
end


return AsteroidManager
