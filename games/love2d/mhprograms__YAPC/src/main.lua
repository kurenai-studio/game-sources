function love.load()
	window = {
		width = 800,
		height = 600,
	}
	paddle = {
		width = 20,
		height = 100,
		speed = 500,		
	}
	player1 = {
		x = 20,
		y = 240,
		score = 0,
	}
	player2 = {
		x = 760,
		y = 240,
		score = 0,
		aiEasySpeedMultiplier = 0.5,
		aiMediumSpeedMultiplier = 0.8,
		aiHardSpeedMultiplier = 0.9,
	}
	ball = {
		x = window.width / 2,
		y = window.height / 2,
		radius = 10,
		easySpeed = 500,
		mediumSpeed = 600,
		hardSpeed = 700,
		velx = 250 * math.cos(math.rad(0)),
		vely = 250 * math.sin(math.rad(0)),
	}
	buttonSet1 = {
		x = 225,
		y1 = 250,
		y2 = 340,
		width = 350,
		height = 60,
	}
	buttonSet2 = {
		x = 225,
		y1 = 195,
		y2 = 285,
		y3 = 375,
		width = 350,
		height = 60,
	}
	love.window.setMode(window.width, window.height)
	gameState = "menu"
	soundState = "on"
	love.graphics.setFont(love.graphics.newFont("assets/PressStart2P-Regular.ttf"))
	scoreyPosition = 50
	wyPosition = 100
	iyPosition = 300
	nyPosition = 500
	pong = require("funcs")
	sound1 = love.audio.newSource("assets/paddlebounce.wav", "static")
	sound2 = love.audio.newSource("assets/wallbounce.wav", "static")
	sound3 = love.audio.newSource("assets/pointscore.wav", "static")
end
function love.update(dt)
	pong.detectCrash()
	if gameState == "2player" or gameState == "cpu" then
		pong.detectCollisionBetweenBallandPlayer1()
		pong.detectCollisionBetweenBallandPlayer2()
		pong.moveThePaddles(dt)
		pong.moveTheBall(dt)
		pong.bounceBallWhentheTopOrBottomWallisHit()
		pong.dealWithTheBallWhenItHitsTheLeftOrRightWall()
		pong.checkIfGameWon()
	end
end
function love.keypressed(key)
	pong.listenToKeyboard(key)
end
function love.draw()
	if gameState == "2player" or gameState == "cpu" or gameState == "won" then
		love.graphics.setColor(0.22, 1.0, 0.08)
		for i = 0, 600, 30 do
			love.graphics.rectangle("fill", 392.5, i, 15, 15)
		end
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("fill", player1.x, player1.y, paddle.width, paddle.height)
		love.graphics.rectangle("fill", player2.x, player2.y, paddle.width, paddle.height)
		love.graphics.circle("fill", ball.x, ball.y, ball.radius)
		love.graphics.setColor(0.22, 1.0, 0.08)
		love.graphics.printf(player1.score, 0, scoreyPosition, 400, "center")
		love.graphics.printf(player2.score, 400, scoreyPosition, 400, "center")
		love.graphics.setColor(1, 1, 1)
	end
	if gameState == "won" then
		if player1.score == 11 then
			love.graphics.printf("W", 0, wyPosition, 400, "center")
			love.graphics.printf("I", 0, iyPosition, 400, "center")
			love.graphics.printf("N", 0, nyPosition, 400, "center")
		elseif player2.score == 11 then
			love.graphics.printf("W", 400, wyPosition, 400, "center")
			love.graphics.printf("I", 400, iyPosition, 400, "center")
			love.graphics.printf("N", 400, nyPosition, 400, "center")
		end
	end
	if gameState == "menu" then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", buttonSet1.x, buttonSet1.y1, buttonSet1.width, buttonSet1.height)
		love.graphics.rectangle("line", buttonSet1.x, buttonSet1.y2, buttonSet1.width, buttonSet1.height)
		love.graphics.printf("PLAY(p)", buttonSet1.x, buttonSet1.y1 + buttonSet1.height / 2 - 6, buttonSet1.width, "center")
		love.graphics.printf("CONTROLS(c)", buttonSet1.x, buttonSet1.y2 + buttonSet1.height / 2 - 6, buttonSet1.width, "center")
	end
	if gameState == "controlMenu" then
		love.graphics.print("W/S to move the left paddle or to play when you're playing with", 5, 5)
		love.graphics.print("the CPU.", 5, 22)
		love.graphics.print("UP/DOWN arrows to move the right paddle.", 5, 39)
		love.graphics.print("ESCAPE to go back to the menu.", 5, 56)
		love.graphics.print("D to toggle sound on/off.", 5, 73)
	end
	if gameState == "optionsMenu" then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", buttonSet1.x, buttonSet1.y1, buttonSet1.width, buttonSet1.height)
		love.graphics.rectangle("line", buttonSet1.x, buttonSet1.y2, buttonSet1.width, buttonSet1.height)
		love.graphics.printf("2 PLAYER(p)", buttonSet1.x, buttonSet1.y1 + buttonSet1.height / 2 - 6, buttonSet1.width, "center")
		love.graphics.printf("CPU(c)", buttonSet1.x, buttonSet1.y2 + buttonSet1.height / 2 - 6, buttonSet1.width, "center")	
	end
	if gameState == "2playerDifficultyMenu" then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", buttonSet2.x, buttonSet2.y1, buttonSet2.width, buttonSet2.height)
		love.graphics.rectangle("line", buttonSet2.x, buttonSet2.y2, buttonSet2.width, buttonSet2.height)
		love.graphics.rectangle("line", buttonSet2.x, buttonSet2.y3, buttonSet2.width, buttonSet2.height)
		love.graphics.printf("EASY(e)", buttonSet2.x, buttonSet2.y1 + buttonSet2.height / 2 - 6, buttonSet2.width, "center")
		love.graphics.printf("MEDIUM(m)", buttonSet2.x, buttonSet2.y2 + buttonSet2.height / 2 - 6, buttonSet2.width, "center")
		love.graphics.printf("HARD(h)", buttonSet2.x, buttonSet2.y3 + buttonSet2.height / 2 - 6, buttonSet2.width, "center")	
	end
	if gameState == "cpuDifficultyMenu" then
		love.graphics.setColor(1, 1, 1)
		love.graphics.rectangle("line", buttonSet2.x, buttonSet2.y1, buttonSet2.width, buttonSet2.height)
		love.graphics.rectangle("line", buttonSet2.x, buttonSet2.y2, buttonSet2.width, buttonSet2.height)
		love.graphics.rectangle("line", buttonSet2.x, buttonSet2.y3, buttonSet2.width, buttonSet2.height)
		love.graphics.printf("EASY(e)", buttonSet2.x, buttonSet2.y1 + buttonSet2.height / 2 - 6, buttonSet2.width, "center")
		love.graphics.printf("MEDIUM(m)", buttonSet2.x, buttonSet2.y2 + buttonSet2.height / 2 - 6, buttonSet2.width, "center")
		love.graphics.printf("HARD(h)", buttonSet2.x, buttonSet2.y3 + buttonSet2.height / 2 - 6, buttonSet2.width, "center")	
	end
end