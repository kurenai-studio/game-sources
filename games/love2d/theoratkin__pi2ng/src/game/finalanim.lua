Object = require "classic"
local FinalAnim = Object:extend()


local SUNSTART = 3
local SUNSPEED = 100
local SUNSIZE = 150
local CIRCLES_SPEED = 50
local CIRCLES_COUNT = 15
local DUMMY_CIRCLES = 4


function FinalAnim:new()
	self.active = false
	self.sunColor = COLORS[SUN_COLOR]

	self.explosionSound = love.audio.newSource("res/explosion.ogg", "static")
	self.particles = love.graphics.newParticleSystem(
		love.graphics.newImage("res/pixel_3x3.png"), 200
	)
end


function FinalAnim:reset()
	self.active = false
	self.sunlinear = SUNSTART
	self.sunease = 0
	self.circles = {}
	for i = 1, CIRCLES_COUNT do
		self.circles[i] = 1
	end

	self.particles:setParticleLifetime(1, 5)
	self.particles:setEmissionRate(30)
	self.particles:setEmissionArea(
		"ellipse", SUNSIZE, SUNSIZE, math.pi * 2
	)
	self.particles:setSizeVariation(1)
	self.particles:setLinearAcceleration(-100, -100, 100, 100)
	self.particles:setPosition(center.x, center.y)
	self.particles:setColors(
		self.sunColor[1],
		self.sunColor[2],
		self.sunColor[3],
		1,
		self.sunColor[1],
		self.sunColor[2],
		self.sunColor[3],
		0
	)
	self.particles:stop()
end


function FinalAnim:play()
	self.active = true
	self.explosionSound:play()
	self.particles:start()
end


function FinalAnim:update(dt)
	if not self.active then
		return
	end

	local diag = math.sqrt(size.x * size.x - size.y * size.y) / 2
	if self.circles[DUMMY_CIRCLES] and self.circles[DUMMY_CIRCLES] > diag * 2 then
		for i in pairs(self.circles) do
			self.circles[i] = nil
		end
	elseif self.circles[DUMMY_CIRCLES] then
		for i = DUMMY_CIRCLES, CIRCLES_COUNT do
			self.circles[i] = self.circles[i] + i * dt * CIRCLES_SPEED
		end
	end

	if self.sunlinear < SUNSIZE then
		self.sunlinear = self.sunlinear + SUNSPEED * dt
		self.sunease = SUNSIZE * easeOutCubic(self.sunlinear / SUNSIZE)
	end

	self.particles:update(dt)
end


function FinalAnim:draw()
	if not self.active then
		return
	end

	love.graphics.setColor(COLORS[SUN_LINE_COLOR])
	love.graphics.setLineWidth(3)
	for i, circle in pairs(self.circles) do
		love.graphics.circle(
			"line",
			center.x, center.y,
			circle
		)
	end
	love.graphics.setColor(self.sunColor)
	love.graphics.circle(
		"fill",
		center.x, center.y,
		self.sunease
	)

	love.graphics.draw(self.particles)
end


function FinalAnim:resize(x, y)
	self.particles:setPosition(x / 2, y / 2)
	self.particles:reset()
end


function easeOutCubic(x)
	return 1 - (1 - x) ^ 3
end

return FinalAnim
