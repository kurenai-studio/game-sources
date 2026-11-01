local WheatGame = Object.extend(Object)

local wheatSize = 64
local startPos = (GameSize - wheatSize * 5) / 2

function WheatGame:new()
	love.mouse.setVisible(false)

	self.wheats = {}
	self.wheatImg = love.graphics.newImage("assets/wheat.png")
	self.scytheImg = love.graphics.newImage("assets/scythe.png")
	self.remainingWheats = 25
	self.totalTiming = 8
	self.timing = self.totalTiming

	for i=1,25 do
		self.wheats[i] = true
	end
end

function WheatGame:update(dt)
	self.timing = self.timing - dt
	if self.timing <= 0 then
		print("You lose Wheat!")
		NextScene(false)
		return
	end

	if self.remainingWheats == 0 then
		print("You win Wheat!")
		NextScene(true)
	else
		for i=1,#self.wheats do
			if self.wheats[i] then
				local row = math.floor((i-1)/5)
				local col = (i-1)%5
				local wheatX = col * wheatSize + startPos
				local wheatY = row * wheatSize + startPos
				local mouseX = love.mouse.getX()
				local mouseY = love.mouse.getY()
				if mouseX > wheatX and mouseX < wheatX + 64 and mouseY > wheatY and mouseY < wheatY + 64 then
					self.wheats[i] = false
					self.remainingWheats = self.remainingWheats - 1
				end
			end
		end
	end
end

function WheatGame:draw()
	love.graphics.setBackgroundColor(0.2, 0.7, 0.1)

	for i=1,#self.wheats do
		if self.wheats[i] then
			local row = math.floor((i-1)/5)
			local col = (i-1)%5
			love.graphics.draw(self.wheatImg, col * wheatSize + startPos, row * wheatSize + startPos)
		end
	end

	love.graphics.setColor(0.8, 0.8, 0.8)
	love.graphics.rectangle("fill", 0, 0, GameSize, 20)
	love.graphics.setColor(0.1, 0.7, 0.1)
	love.graphics.rectangle("fill", 0, 0, GameSize * (self.timing / self.totalTiming), 20)
	love.graphics.setColor(1, 1, 1)

	love.graphics.setFont(love.graphics.newFont(24))
	love.graphics.print("Cut all the wheat!", 10, 10)

	love.graphics.draw(self.scytheImg, love.mouse.getX(), love.mouse.getY())
end

return WheatGame
