Object = require "classic"
local Ball = Object:extend()

local SIZE = 10
local MIN_SPEED = 100
local MAX_SPEED = 400
local SPEED_STEP = 2
local ANGLE_LIMIT = 45


function Ball:new(ui)
	self:resize(love.graphics.getDimensions())
	self.ui = ui

	math.randomseed(os.time())
	self:reset()
	self.currentRacket = racket1
	self.active = false

	self.particles = love.graphics.newParticleSystem(
		love.graphics.newImage("res/pixel_3x3.png"), 30
	)
	self.particles:setParticleLifetime(1, 1)
	self.particles:setEmissionRate(10000)
	self.particles:setEmitterLifetime(1)
	self.particles:setEmissionArea(
		"uniform", 3, 3, math.pi * 2
	)
	self.particles:setSizeVariation(1)
	self.particles:stop()

	self.breakSound = love.audio.newSource("res/break.ogg", "static")
end


function Ball:reset()
	self.position = { x = self.center.x, y = self.center.y }
	self.speedPerc = 0
	self.speed = MIN_SPEED
	self.score = 0
	self.angle = 0
	self.direction = {x = 0, y = 0}
	RADIUS = 100
end

function Ball:start()
	self:reset()
	self.angle =
		self.currentRacket.angle +
		math.rad(math.random(-ANGLE_LIMIT, ANGLE_LIMIT))
	self.direction = {x = math.cos(self.angle), y = math.sin(self.angle)}
	self.active = true
end


function Ball:distance()
	local x = self.position.x - self.center.x
	local y = self.position.y - self.center.y
	return math.sqrt(x * x + y * y)
end


function Ball:gameover()
	return self:distance() > RADIUS + 50
end


function Ball:angleFromCenter()
	local dy = self.position.y - self.center.y;
	local dx = self.position.x - self.center.x;
	local angle = math.atan2(dy, dx)
	if angle < 0 then
		angle = angle + math.pi * 2
	end
	return angle
end


function Ball:racket()
	if self:distance() >= RADIUS then
		return false
	end

	local angle = self:angleFromCenter()
	local r = self.currentRacket
	local length = math.rad(r.length / 2 + r.width)
	if  (self:distance() >= RADIUS - SIZE - r.width / 2) and
		((math.abs(angle - r.angle) < length) or
		(angle < length and r.angle > math.pi * 2 - length) or
		(r.angle < length and angle > math.pi * 2 - length))
	then
		return true
	end
	return false
end


function Ball:ping()
	if self.speedPerc < 100 then
		self.speedPerc = self.speedPerc + SPEED_STEP
		self.speed = MIN_SPEED + (MAX_SPEED - MIN_SPEED) * (self.speedPerc / 100)
	end
	self.score = self.score + 1
	RADIUS = 100 + self.speedPerc

	self.angle =
		self:angleFromCenter() + math.pi +
		math.rad(math.random(-ANGLE_LIMIT, ANGLE_LIMIT))

	if self.speedPerc == 100 then
		self.angle = self:angleFromCenter() - math.pi
	end

	if self.angle >= math.pi * 2 then
		self.angle = self.angle - math.pi * 2
	end
	if self.angle < 0 then
		self.angle = self.angle + math.pi * 2
	end
	self.direction = {x = math.cos(self.angle), y = math.sin(self.angle)}

	self.currentRacket.flash = 1
	self.currentRacket.flashColor = {0, 0, 0}
	if flashing and self.speedPerc >= 60 then
		color = math.random(2, #COLORS)
		self.currentRacket.flashColor = COLORS[color]
	end
	local sound = math.random(3)
	self.currentRacket.sounds[sound]:seek(0)
	self.currentRacket.sounds[sound]:setPitch(0.5 + 0.5 * self.speedPerc / 100)
	self.currentRacket.sounds[sound]:play()
	self.currentRacket = self.currentRacket.opposite
end


function Ball:update(dt)
	if not self.active then
		return
	end

	local tolerance = 10
	if  self.speedPerc == 100 and
		math.abs(self.position.x - self.center.x) < tolerance and
		math.abs(self.position.y - self.center.y) < tolerance 
	then
		self.position.x = self.center.x
		self.position.y = self.center.y
		self.active = false
		if not finalanim.active then
			finalanim:play()
			ui.restartAngle = racket2.angle
			ui.state = "win"
		end
	else
		self.position.x = self.position.x + self.direction.x * self.speed * dt
		self.position.y = self.position.y + self.direction.y * self.speed * dt
	end

	if self:racket() then
		self:ping()
	end
	if self:gameover() then
		self.breakSound:play()
		self.particles:stop()
		self.particles:setPosition(self.position.x, self.position.y)
		self.particles:setColors(
			self.currentRacket.color[1],
			self.currentRacket.color[2],
			self.currentRacket.color[3],
			1,
			self.currentRacket.color[1],
			self.currentRacket.color[2],
			self.currentRacket.color[3],
			0
		)
		self.particles:setSpeed(
			self.direction.x * self.speed,
			self.direction.y * self.speed
		)
		self.particles:setLinearAcceleration(
			self.direction.x * self.speed,
			self.direction.y * self.speed,
			self.direction.x * self.speed * 2,
			self.direction.y * self.speed * 2
		)
		self.particles:start()
		self:start()
	end

	self.ui.score = self.score
	self.ui.speedPerc = self.speedPerc

	self.particles:update(dt)
end


function Ball:draw()
	if not self.active then
		return
	end

	-- Outer ball
	love.graphics.setColor(
		self.currentRacket.color[1] * 0.5,
		self.currentRacket.color[2] * 0.5,
		self.currentRacket.color[3] * 0.5
	)
	love.graphics.circle("fill", self.position.x, self.position.y, SIZE, 5)

	-- Inner ball
	love.graphics.setColor(self.currentRacket.color)
	love.graphics.circle("fill", self.position.x, self.position.y, SIZE / 2, 5)

	-- Orbit
	--[[
	love.graphics.setColor(1, 1, 1, 0.2)
	love.graphics.setLineWidth(1)
	love.graphics.circle("line", self.center.x, self.center.y, RADIUS)
	love.graphics.setColor(1, 1, 1, 1)
	--]]
	
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.particles, 0, 0)
end


function Ball:resize(x, y)
	if self.position then
		local d = self:distance()
		local a = self:angleFromCenter()
		self.position.x = x / 2 + math.cos(a) * d
		self.position.y = y / 2 + math.sin(a) * d
	end

	self.size = {x = x, y = y}
	self.center = {x = x / 2, y = y / 2}
end


return Ball
