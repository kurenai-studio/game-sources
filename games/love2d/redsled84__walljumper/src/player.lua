local class = require 'middleclass'
local world = require 'world'
local timer = require 'timer'
local entity = require 'entity'
local particles = require 'particles'
local player = class('player', entity)

local coinVX = love.audio.newSource("sound/coinpickup.wav", "static")
coinVX:setVolume(0.3)
local hitVX = love.audio.newSource("sound/hit.wav", "static")

local frc, acc, dec, top, low = 700, 500, 2000, 350, 50

function player:load(x, y, w, h)
	self:initialize(world.bump, x, y, w, h, 'player')
	self.onGround = false
	self.wallJumpLeft = false
	self.wallJumpRight = false

	self.jumpFactor = -400
	self.wallJumpFactor = 350
	self.wallVelocity = 200
	self.boosterVelocity = 1600
	self.score = 0
	self.dieTimer = timer:new(2)
	self.bloodSpray = 0
	self.dead = false
end

function player:setSpawn(x, y)
	self.ox = x
	self.oy = y
end

function player:update(dt)
	self.onGround = false
	self:applyGravity(dt)
	self:applyCollisions(dt)
	self:applyWallVelocity(dt)
	if not self.dead then
    	self:move(dt)
	else
		self:updateDead(dt)
	end
    self:checkWallJump()
end

function collisionFilter(item, other)
	if other.name == "coin" or other.name == 'particle' then
		return "cross"
	else
		return "slide"
	end
end

function player:applyCollisions(dt)
	local futureX, futureY = self.x + (self.vx * dt), self.y + (self.vy * dt)
	local nextX, nextY, cols, len = world.bump:move(self, futureX, futureY, collisionFilter)

	for i = 1, len do
		local col = cols[i]
		if col.other.name ~= "coin" and col.other.name ~= "particle" then
			self:applyCollisionNormal(col.normal.x, col.normal.y)
		end
		if col.normal.y == -1 then
			self.onGround = true
		end
		if col.other.name == "spike" then
			self:setDead(dt)
		end
		if col.other.name == "coin" then
			self:addScore(col.other)
		end
		if col.other.name == "booster" and col.normal.y == -1 then
			self.vx = self.boosterVelocity
		end
	end

	self.x = nextX
	self.y = nextY
end

function player:setDead(dt)
	self.dead = true
	if self.bloodSpray == 0 then
		particles:load(30, 10, 145, player.x+player.w/2, player.y, 4, 4)
		hitVX:play()
		self.bloodSpray = self.bloodSpray + 1
	end
end

function player:updateDead(dt)
	self.dieTimer:update(dt, function()
		self.x = self.ox
		self.y = self.oy
		world.bump:update(self, self.x, self.y)
		self.dead = false
		self.bloodSpray = 0
		self.vx = 0
		self.vy = 0
	end)
end

function player:addScore(item)
	self.score = self.score + 1
	world.bump:remove(item)
	if coinVX:isPlaying() then
		coinVX:stop()
		coinVX:play()
	else
		coinVX:play()
	end
end

function player:applyWallVelocity(dt)
	if (self.wallJumpRight or self.wallJumpLeft) and self.vy > 0 then
		if self.vy < self.wallVelocity then
			self.vy = self.vy + low * dt
		else
			self.vy = self.wallVelocity
		end
	end
end

function player:move(dt)
	local lk = love.keyboard
    local vx = self.vx

    if lk.isDown('right') then
        if vx < 0 then
            vx = vx + dec * dt
        elseif vx < top then
            vx = vx + acc * dt
        end
    elseif lk.isDown('left') then
        if vx > 0 then
            vx = vx - dec * dt
        elseif vx > -top then
            vx = vx - acc * dt
        end
    else
        if math.abs(vx) < low then
            vx = 0
        elseif vx > 0 then
            vx = vx - frc * dt
        elseif vx < 0 then
            vx = vx + frc * dt
        end
    end

	self.vx = vx
end

function player:checkWallJump(dt)
	self.wallJumpLeft = false
	self.wallJumpRight = false

	local items, len = world.bump:getItems()
	local wallJumpWidth = 2
	for i = 1, len do
		local item = items[i]
		local x1, x2 = self.x - wallJumpWidth, self.x + self.w
		local y = self.y
		local h = self.h

		if item.name == "solid" then
			-- Check left side for wall jumping
			if x1 < item.x + item.width and x1 + wallJumpWidth > item.x and
			y < item.y + item.height and y + h > item.y then
				self.wallJumpLeft = true
			end

			-- Check right side for wall jumping
			if x2 < item.x + item.width and x2 + wallJumpWidth > item.x and
			y < item.y + item.height and y + h > item.y then
				self.wallJumpRight = true
			end
		end
	end
end

function player:jump(key)
	if key == 'up' and not self.dead then
		if self.onGround then
			self.vy = self.jumpFactor
		end
		if self.wallJumpRight and not self.onGround then
			self.vx = -self.wallJumpFactor
			self.vy = self.jumpFactor
		end
		if self.wallJumpLeft and not self.onGround then
			self.vx = self.wallJumpFactor
			self.vy = self.jumpFactor
		end
	end
end

return player