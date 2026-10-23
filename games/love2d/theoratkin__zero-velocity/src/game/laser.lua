Object = require "classic"
Vector = require "vector"
local Laser = Object:extend()

function Laser:new(asteroidManager)
	self.active = false
	self.angle = 0
	self.asteroidManager = asteroidManager

	self.fuelConsumptionRate = 10

	self.heat = 0
	self.overheat = false
	self.damageMul = 0

	self.position = Vector()
	self.scale = 5

	self.sound = love.audio.newSource("res/laser.ogg", "static")
	self.sound:setLooping(true)
	self.overheatingSound = love.audio.newSource("res/overheating.ogg", "static")
end


function Laser:init(lasers)
	for i, laser in pairs(lasers) do
		local body = love.physics.newBody(
			world,
			0, laser.length * self.scale / 2,
			"dynamic"
		)
		local shape = love.physics.newRectangleShape(
			0, laser.length * self.scale / 2, self.scale, laser.length * self.scale
		)
		local fixture = love.physics.newFixture(body, shape)
		fixture:setUserData(self)
		fixture:setSensor(true)

		laser.body = body
		laser.shape = shape
		laser.fixture = fixture

		laser.body:setActive(false)
	end
end


function Laser:set(lasers)
	if self.lasers then
		for i, laser in pairs(lasers) do
			laser.body:setActive(false)
		end
	end
	self.lasers = lasers
	if self.lasers then
		for i, laser in pairs(lasers) do
			laser.body:setActive(true)
		end
	end
end


-- Returns true on overheat
function Laser:updateHeat(dt)
	-- Heating
	if self.active then
		if self.heat >= 100 or self.overheat then
			self:onOverheating()
			return true
		end
		self.heat = self.heat + dt * self.heatingSpeed
		session:reduceScore(self.fuelConsumptionRate * dt)

	-- Cooling
	else
		local speed = self.coolingSpeed
		if self.overheat then
			speed = self.recoverySpeed
		end
		self.heat = self.heat - dt * speed

		if self.heat <= 0 then
			self.overheat = false
			self.heat = 0
		end
	end

	return false
end


function Laser:update(dt)
	if self:updateHeat(dt) then
		return
	end

	if not self.active then
		return
	end

	self.angle = ship.angle
	self.position = ship.position

	for i, laser in pairs(self.lasers) do
		laser.body:setAngle(self.angle)
	end
end


function Laser:canFire()
	return not self.overheat and session:getScore() ~= 0
end


function Laser:getDamage()
	return self.damageMul * self.heat
end


function Laser:setActive(state)
	self.active = state
	for i, laser in pairs(self.lasers) do
		laser.body:setActive(state)
	end
	if state then
		self.sound:play()
	else
		self.sound:pause()
	end
end


function Laser:reset()
	self:setActive(false)
	self.heat = 0
end


function Laser:onOverheating()
	self.overheat = true
	self.overheatingSound:play()
end


function Laser:drawLaser(cs, sn, laser)
	local offset = Vector(
		laser.oy * self.scale,
		(laser.ox * self.scale - self.scale / 2) * laser.mirror
	)
	r = self.position + offset
	r:rotate(self.position, cs, sn)
	laser.body:setPosition(r.x, r.y)

	love.graphics.setLineWidth(laser.width * self.scale)
	love.graphics.line(
		r.x, r.y,
		r.x + cs * laser.length * self.scale,
		r.y + sn * laser.length * self.scale
	)
end


function Laser:draw()
	if not self.active then
		return
	end

	local perc = self.heat / 100
	love.graphics.setColor(1, 0, 0, perc)

	local cs = math.cos(self.angle + math.rad(90))
	local sn = math.sin(self.angle + math.rad(90))

	for i, laser in pairs(self.lasers) do
		self:drawLaser(cs, sn, laser)
	end

	love.graphics.setColor(1, 1, 1, 1)
end


function Laser:beginContact(a, b)
	if ship.pauseState then
		return
	end
	if a:is(Laser) then
		self.asteroidManager:laserBeginContact(b)
	elseif b:is(Laser) then
		self.asteroidManager:laserBeginContact(a)
	end
end


function Laser:endContact(a, b)
	if ship.pauseState then
		return
	end
	if a:is(Laser) then
		self.asteroidManager:laserEndContact(b)
	elseif b:is(Laser) then
		self.asteroidManager:laserEndContact(a)
	end
end


return Laser
