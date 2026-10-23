Object = require "classic"
local Racket = Object:extend()


local SPEED = 3


function Racket:new(opposite)
	self:resize(love.graphics.getDimensions())
	self.width = 5
	self.startLength = 20
	self.length = self.startLength
	self.flash = 0
	self.flashColor = {1, 1, 1}

	if not opposite then
		self.angle = 0
		self.color = COLORS[RACKET1_COLOR]
	else
		self.angle = math.pi
		self.color = COLORS[RACKET2_COLOR]
	end

	self.sounds = {
		love.audio.newSource("res/crystal1.ogg", "static"),
		love.audio.newSource("res/crystal2.ogg", "static"),
		love.audio.newSource("res/crystal3.ogg", "static"),
	}

	for i, sound in pairs(self.sounds) do
		sound:setVolume(0.5)
		sound:setPitch(0.5)
	end
end


function Racket:update(dt)
	if input:state("left") then
		self.angle = self.angle + SPEED * dt * input:value("left")
	elseif input:state("right") then
		self.angle = self.angle + SPEED * dt * input:value("right")
	end
	if self.angle >= math.pi * 2 then
		self.angle = self.angle - math.pi * 2
	end
	if self.angle < 0 then
		self.angle = self.angle + math.pi * 2
	end

	self.flash = self.flash - dt * 2
	if self.flash < 0 then
		self.flash = 0
	end

	self.length = self.startLength + 40 * ball.speedPerc / 100
end


function Racket:draw()
	love.graphics.setColor(
		self.color[1] + self.flash * 2,
		self.color[2] + self.flash * 2,
		self.color[3] + self.flash * 2
	)
	love.graphics.setLineWidth(self.width)
	love.graphics.arc(
		"line", "open",
		self.center.x, self.center.y,
		RADIUS,
		self.angle - math.rad(self.length / 2), 
		self.angle + math.rad(self.length / 2),
		20
	)
	if self.flashColor[1] + self.flashColor[2] + self.flashColor[3] ~= 0 then
		love.graphics.setColor(
			self.flashColor[1],
			self.flashColor[2],
			self.flashColor[3],
			self.flash
		)
		local flashWidth = 1000
		love.graphics.setLineWidth(flashWidth)
		love.graphics.arc(
			"line", "open",
			self.center.x, self.center.y,
			RADIUS + flashWidth / 2 + self.width / 2,
			self.angle - math.rad(self.length / 2), 
			self.angle + math.rad(self.length / 2),
			500
		)
	end
end


function Racket:resize(x, y)
	self.size = {x = x, y = y}
	self.center = {x = x / 2, y = y / 2}
end


return Racket
