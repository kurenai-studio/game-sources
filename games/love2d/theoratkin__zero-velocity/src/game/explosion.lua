Object = require "classic"
local Explosion = Object:extend()


function Explosion:new(big)
	if not big then
		self.particles = love.graphics.newParticleSystem(
			love.graphics.newImage("res/pixel_10x10.png"), 30
		)
	else
		self.particles = love.graphics.newParticleSystem(
			love.graphics.newImage("res/pixel_20x20.png"), 30
		)
	end

	self.particles:setParticleLifetime(.5, .5)
	--self.particles:setEmissionRate(30)
	--self.particles:setEmissionArea(
	--	"ellipse", 1, 1, math.pi * 2
	--)
	self.particles:setSizeVariation(1)
	self.particles:setLinearAcceleration(-600, -600, 600, 600)
	self.particles:setColors(
		255, 0, 0, 255,
		255, 255, 255, 255,
		255, 0, 0, 0
	)
	self.particles:setSizes(0.5, 0.5)
end


function Explosion:play(pos)
	self.particles:setPosition(pos.x, pos.y)
	self.particles:emit(20)
end


function Explosion:update(dt)
	self.particles:update(dt)
end


function Explosion:draw()
	love.graphics.draw(self.particles)
end

return Explosion
