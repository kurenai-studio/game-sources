local AppleGame = Object.extend(Object)

function AppleGame:new()
	love.mouse.setVisible(false)

	self.apples = {}
	self.appleImg = love.graphics.newImage("assets/apple.png")
	self.basketImg = love.graphics.newImage("assets/basket.png")
	self.treeImg = love.graphics.newImage("assets/tree.png")
	self.appleRadius = self.appleImg:getWidth() / 2
	self.basketSize = self.basketImg:getWidth()
	self.droppingInterval = 2
	self.droppingTimer = 0
	self.finish = false

	for i=1,5 do
		self.apples[i] = {x = math.random(50, GameSize - 100), y = math.random(80, 250), caught = false, dropping = false}
	end
end

function AppleGame:update(dt)
	if self.finish then
		local allCaught = true
		for i=1,#self.apples do
			if not self.apples[i].caught then
				allCaught = false
				break
			end
		end
		if allCaught then
			print("You win apples!")
		else
			print("You lose apples!")
		end

		NextScene(allCaught)
		return
	end

	self.droppingTimer = self.droppingTimer + dt
	if self.droppingTimer >= self.droppingInterval then
		self.droppingTimer = 0
		for i=1,#self.apples do
			if not self.apples[i].dropping then
				self.apples[i].dropping = true
				break
			end
		end
	end

	for i=1,#self.apples do
		if self.apples[i].dropping and not self.apples[i].caught then
			self.apples[i].y = self.apples[i].y + 200 * dt
			local appleY = self.apples[i].y

			local appleX = self.apples[i].x
			local mouseX = love.mouse.getX()

			if appleY + self.appleRadius * 2 >= GameSize - 100 and
				appleX + self.appleRadius * 2 >= mouseX - self.basketSize / 2 and
				appleX <= mouseX + self.basketSize / 2 then
				self.apples[i].caught = true
				print("Caught an apple!")

				if i == #self.apples then
					self.finish = true
				end
			end

			if appleY > GameSize and not self.apples[i].caught then
				self.finish = true
				print("Missed an apple!")
			end
		end
	end
end

function AppleGame:draw()
	love.graphics.setBackgroundColor(0.1, 0.7, 0.9)
	love.graphics.setColor(0.1, 0.9, 0.1)
	love.graphics.rectangle("fill", 0, GameSize - 100, GameSize, 100)
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.treeImg, GameSize / 2 - self.treeImg:getWidth() / 2, GameSize - 100 - self.treeImg:getHeight())

	for i=1,#self.apples do
		if not self.apples[i].caught then
			love.graphics.draw(self.appleImg, self.apples[i].x, self.apples[i].y)
		end
	end

	love.graphics.setFont(love.graphics.newFont(24))
	love.graphics.print("Catch the apples!", 10, 10)

	love.graphics.draw(self.basketImg, love.mouse.getX() - self.basketSize / 2, GameSize - 100)
end

return AppleGame
