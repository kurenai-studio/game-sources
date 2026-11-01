local TitleScreen = Object.extend(Object)

function TitleScreen:new()
	love.mouse.setVisible(true)

	self.treeImg = love.graphics.newImage("assets/tree.png")
	self.basketImg = love.graphics.newImage("assets/basket.png")
	self.fenceImg = love.graphics.newImage("assets/fence.png")
	self.chickenImg = love.graphics.newImage("assets/chicken.png")
	self.appleImg = love.graphics.newImage("assets/apple.png")
	self.wheatImg = love.graphics.newImage("assets/wheat.png")
	self.flowerImg = love.graphics.newImage("assets/on.png")
end

function TitleScreen:update(dt)
	if love.mouse.isDown(1) then
		NextScene(true)
	end
end

function TitleScreen:draw()
	love.graphics.setBackgroundColor(1, 1, 1)

	love.graphics.draw(self.treeImg, -100, GameSize - self.treeImg:getHeight())
	love.graphics.draw(self.appleImg, 20, 230)
	love.graphics.draw(self.appleImg, 130, 320)
	love.graphics.draw(self.basketImg, 100, GameSize - self.basketImg:getHeight())
	love.graphics.draw(self.fenceImg, 350, GameSize - self.fenceImg:getHeight())
	love.graphics.draw(self.chickenImg, 220, GameSize - self.chickenImg:getHeight())
	love.graphics.draw(self.chickenImg, 350, GameSize - self.chickenImg:getHeight())
	love.graphics.draw(self.chickenImg, 500, GameSize - self.chickenImg:getHeight())
	love.graphics.draw(self.wheatImg, 20, GameSize - self.wheatImg:getHeight())
	love.graphics.draw(self.wheatImg, 440, GameSize - self.wheatImg:getHeight())
	love.graphics.draw(self.flowerImg, 0, 40)
	love.graphics.draw(self.flowerImg, 450, 60)

	love.graphics.setColor(0, 0, 0)
	love.graphics.setFont(love.graphics.newFont(50))
	love.graphics.print("Welcome to", 150, 50)
	love.graphics.print("FarmWare!", 160, 120)
	love.graphics.setFont(love.graphics.newFont(24))
	love.graphics.print("Click to start!", 220, 200)
	love.graphics.setColor(1, 1, 1)
end

return TitleScreen
