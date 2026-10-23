Object = require "classic"
Explosion = require "explosion"
local Asteroid = Object:extend()

function Asteroid:new(manager)
	self.scale = Vector(5, 5)
	self.manager = manager
	self.pauseState = false
	self.angle = 0

	self.points = self:gen()
	self.positions = {}

	self.fullHealth = self.segments * 5
	self.score = self.segments * 50

	triangles = love.math.triangulate(self.points)

	self.body = love.physics.newBody(
		world,
		0,
		0,
		"dynamic"
	)
	for i, triangle in pairs(triangles) do
		self.shape = love.physics.newPolygonShape(triangle)
		self.fixture = love.physics.newFixture(self.body, self.shape)
		self.fixture:setUserData(self)
		--self.fixture:setSensor(true)
	end

	self.explosion = Explosion()
	self.sound = love.audio.newSource("res/asteroid_explosion.ogg", "static")
	self.sound:setVolume(manager.soundvol)

	self:reset()
end


function Asteroid:gen()
	local segments = math.random(3, 10)
	local minradius = math.random(3, 6) * segments
	local maxradius = minradius * 2
	local angles = {0}
	local points = {}
	for i = 2, segments do
		angles[i] = angles[i - 1] + (math.pi * 2 / segments)
	end
	for i, angle in pairs(angles) do
		local radius = minradius + love.math.random() * (maxradius - minradius)
		points[i * 2 - 1] = math.cos(angle) * radius
		points[i * 2] = math.sin(angle) * radius
	end
	self.segments = segments
	return points
end


function Asteroid:reset()
	if self.position then
		self.explosion:play(self.position)
		self.sound:play()
	end

	self.health = self.fullHealth
	self.damage = 0

	-- Determening rotation
	local rotationdir  = love.math.random(1, 2)
	if rotationdir == 2 then rotationdir = -1 end
	self.rotationspeed = love.math.random(1, 3) * rotationdir

	-- Determening angle of approach
	local angle = math.rad(love.math.random(0, 360))
	self.dir = Vector(math.cos(angle), math.sin(angle))
	--local w = love.graphics:getWidth()
	--local h = love.graphics:getHeight()
	local w = 1920
	local h = 1080
	local diag = math.sqrt(w * w + h * h) / 2;
	local distance = love.math.random(diag + 50, diag + 300)
	self.position = ship.position + self.dir * distance
	self:updatePositions()
	self.resetbody = true

	self.speed = -love.math.random(50, 80)
end


function Asteroid:updatePositions()
	local cs = math.cos(self.angle)
	local sn = math.sin(self.angle)
	for i = 1, self.segments do
		local v = Vector(
			self.position.x + self.points[i * 2 - 1],
			self.position.y + self.points[i * 2]
		)
		v:rotate(self.position, cs, sn)
		self.positions[i * 2 - 1] = v.x
		self.positions[i * 2] = v.y
	end
end


function Asteroid:update(dt)
	if self.resetbody then
		self.resetbody = false
		self.body:setPosition(self.position.x, self.position.y)
	end
	if self.pauseState then
		self.body:setLinearVelocity(0, 0)
		self.body:setActive(false)
		return
	else
		self.body:setActive(true)
		self.body:setLinearVelocity(self.dir.x * self.speed, self.dir.y * self.speed)
	end
	self.health = self.health - dt * laser:getDamage() * self.damage
	if self.health <= 0 then
		self.manager:onAsteroidDestroy(self)
		return
	end

	self.angle = self.angle + self.rotationspeed * dt
	self.position.x = self.body:getX()
	self.position.y = self.body:getY()
	self.body:setAngle(self.angle)

	self:updatePositions()

	self.explosion:update(dt)
end


function Asteroid:draw()
	local perc = self.health / self.fullHealth
	love.graphics.setColor(1, perc, perc, 1)
	love.graphics.setLineWidth(5)

	love.graphics.polygon("line", self.positions)
	if self.index then
		love.graphics.setColor(1, 1, 1, .2)
		local f = love.graphics.getFont()
		love.graphics.print(
			self.index,
			self.position.x - f:getWidth(self.index) / 2,
			self.position.y + f:getLineHeight() / 2
		)
	end

	love.graphics.setColor(1, 1, 1, 1)
	self.explosion:draw()
end


function Asteroid:pause(state)
	self.pauseState = state
end


function Asteroid:destroy()
	self.body:destroy()
	self.body:release()
end


return Asteroid
