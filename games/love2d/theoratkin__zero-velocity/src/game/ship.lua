Object = require "classic"
Event = require "event"
Explosion = require "explosion"
local Ship = Object:extend()


local SHIPS = {
	{
		name = "fighter";
		speed = 7;
		damage = 4;
		heatingSpeed = 10;
		coolingSpeed = 100;
		recoverySpeed = 100;
		lasers = {
			{ ox = 6, oy = 14, length = 20, mirror = 1, width = 1 };
			{ ox = 6, oy = 14, length = 20, mirror = -1, width = 1 };
		}
	};
	{
		name = "hauler";
		speed = 5;
		damage = 5;
		heatingSpeed = 20;
		coolingSpeed = 100;
		recoverySpeed = 100;
		lasers = {
			{ ox = 9, oy = 6, length = 40, mirror = 1, width = 1 };
		}
	};
	{
		name = "shuttle";
		speed = 10;
		damage = 10;
		heatingSpeed = 10;
		coolingSpeed = 80;
		recoverySpeed = 100;
		lasers = {
			{ ox = .5, oy = 6, length = 15, mirror = 1, width = 2 };
		}
	};
	{
		name = "icebreaker";
		speed = 3;
		damage = 2;
		heatingSpeed = 10;
		coolingSpeed = 80;
		recoverySpeed = 100;
		lasers = {
			{ ox = .5, oy = 18, length = 100, mirror = 1, width = 2 };
		}
	}
}


function Ship:new()
	self.angle = 0
	self.pauseState = true
	self.active = false
	self.preview = false
	self.ignorefirebutton = false
	self.dead = false

	self.scale = Vector(5, 5)

	self.position = Vector(
		960, 540
	)
	self.explosion = Explosion(true)

	self.sound = love.audio.newSource("res/ship_explosion.ogg", "static")

	self.onGameOver = Event()

	for i, ship in pairs(SHIPS) do
		self:init(ship)
		laser:init(ship.lasers)
	end
end


function Ship:init(ship)
	ship.quad = sprites:getQuad(ship.name)
	ship.body = love.physics.newBody(
		world,
		self.position.x,
		self.position.y,
		"static"
	)
	ship.shape = love.physics.newRectangleShape(
		(ship.quad.h / 2 - ship.quad.ox) * self.scale.x,
		(ship.quad.w / 2 - ship.quad.oy) * self.scale.y,
		ship.quad.h * self.scale.x,
		ship.quad.w * self.scale.y
	)
	ship.fixture = love.physics.newFixture(ship.body, ship.shape)
	ship.fixture:setUserData(self)
	ship.fixture:setSensor(true)
	ship.body:setActive(false)
end


function Ship:shipsCount()
	return #SHIPS
end


function Ship:get()
	return self.ship
end


function Ship:getRangeIndex(value, range)
	local a = 0
	local b = range[1]
	for i = 1, #range do
		if value >= a and value <= b then
			return i
		end
		a = range[i]
		if i <= #range then
			b = range[i + 1]
		end
	end
	return #range + 1
end


function Ship:getStats()
	local ranges = {
		range  = {15, 20, 40, 60},
		damage = {2, 4, 6},
		heat   = {10, 30, 50},
		speed  = {3, 5, 7, 10},
	}
	return {
		range = self:getRangeIndex(self.ship.lasers[1].length, ranges.range),
		damage = self:getRangeIndex(self.ship.damage * #self.ship.lasers, ranges.damage),
		heat = self:getRangeIndex(self.ship.heatingSpeed, ranges.heat),
		speed = self:getRangeIndex(self.ship.speed, ranges.speed),
	}
end


function Ship:set(index)
	if self.ship then
		self.ship.body:setActive(false)
	end
	self.ship = SHIPS[index]
	self.ship.body:setPosition(self.position.x, self.position.y)
	self.ship.body:setActive(true)
	laser:set(self.ship.lasers)
	laser.damageMul = self.ship.damage
	laser.heatingSpeed = self.ship.heatingSpeed
	laser.coolingSpeed = self.ship.coolingSpeed
	laser.recoverySpeed = self.ship.recoverySpeed
end


function Ship:resize(w, h)
	self.position.x = w / 2
	self.position.y = h / 2
	self.ship.body:setPosition(self.position.x, self.position.y)
end


function Ship:update(dt)
	self.explosion:update(dt)
	if self.pauseState then
		return
	end
	if not self.active then
		self.ship.body:setActive(false)
		laser:setActive(false)
		return
	else
		self.ship.body:setActive(true)
	end

	if input:state("right") then
		self.angle = self.angle + self.ship.speed * dt * input:value("right")
	end

	if input:state("left") then
		self.angle = self.angle + self.ship.speed * dt * input:value("left")
	end

	if input:state("fire") then
		if not self.ignorefirebutton then
			if laser:canFire() then
				laser:setActive(true)
			else
				laser:setActive(false)
			end
		end
	else
		self.ignorefirebutton = false
		laser:setActive(false)
	end

	self.ship.body:setAngle(self.angle)
	laser:update(dt)
end


function Ship:draw()
	if not self.active and not self.preview then
		return
	end
	love.graphics.setColor(1, 1, 1, 1)
	if self.dead then
		love.graphics.setColor(.3, .3, .3, 1)
	end
	love.graphics.draw(
		sprites:getImage(),
		self.ship.quad.quad,
		self.position.x, self.position.y,
		self.angle,
		self.scale.x, self.scale.y,
		self.ship.quad.ox, self.ship.quad.oy
	)
	love.graphics.setColor(1, 1, 1, 1)
	if not self.preview then
		laser:draw()
	end
	self.explosion:draw()
end


function Ship:setActive(state)
	self.active = state
end


function Ship:pause(state)
	self.pauseState = state
end


function Ship:onContact(a, b)
	if self.pauseState then
		return
	end
	if a:is(Ship) or b:is(Ship) then
		-- Ignore collision with lasers.
		if a:is(Laser) or b:is(Laser) then
			return
		end
		self.pauseState = true
		laser.sound:pause()
		self.sound:play()
		self.explosion:play(self.position)
		self.onGameOver:invoke()
		self.dead = true
	end
end


return Ship;
