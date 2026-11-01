local class = require 'middleclass'
local entity = class('entity')

local gravity = 850

function entity:initialize(world, x, y, w, h, name)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.name = name
	self.vx, self.vy = 0, 0
	world:add(self, x, y, w, h)
end

function entity:applyGravity(dt)
	self.vy = self.vy + gravity * dt
end

function entity:applyCollisionNormal(nx, ny, bounciness)
	local bounciness = bounciness or 0
	local vx, vy = self.vx, self.vy

  	if (nx < 0 and vx > 0) or (nx > 0 and vx < 0) then
    	vx = -vx * bounciness
  	end

  	if (ny < 0 and vy > 0) or (ny > 0 and vy < 0) then
    	vy = -vy * bounciness
  	end

	self.vx, self.vy = vx, vy
end

function entity:isSleeping()
	return self.vx == 0 and self.vy == 0
end

function entity:draw(colors)
	love.graphics.setColor(colors[1], colors[2], colors[3])
	love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
end

function entity:destory(world)
	world:remove(self)
end

return entity