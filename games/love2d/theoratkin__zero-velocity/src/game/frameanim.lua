Object = require "classic"
Event  = require "event"
local FrameAnim = Object:extend()


function FrameAnim:new(sprite, size, cols, rows, frames)
	self.playState = false
	self.sprite = sprite
	self.size = size
	self.frame = 1
	self.frames = frames
	self.animSpeed = 10
	self.onAnimEnd = Event()

	local count = 1
	for x = 0, cols do
		for y = 0, rows do
			sprite:addQuad(count, size * y, size * x, size, size)
			count = count + 1
		end
	end
end


function FrameAnim:play()
	self.playState = true
end


function FrameAnim:setOnAnimEndCallback(func)
	self.onAnimEndCallback = func
end


function FrameAnim:update(dt)
	if not self.playState then
		return
	end
	self.frame = self.frame + dt * self.animSpeed
	if self.frame > self.frames then
		self.playState = false
		self.frame = 1
		self.onAnimEnd:invoke()
	end
end


function FrameAnim:draw()
	if not self.playState then
		return
	end
	love.graphics.setColor(1, 1, 1, 1)
	x = 960
	y = 540
	love.graphics.draw(
		self.sprite:getImage(),
		self.sprite:getQuad(math.floor(self.frame)).quad,
		x, y,
		0,
		5, 5,
		self.size / 2, self.size / 2
	)
end


return FrameAnim
