-- lpong 0.1 (a pong clone w/ love2d)
-- by Ricky Thomson
-- license: GNU GPLv3

-- controls
	-- player one 
	-- w, s

	--player two
	-- up arrow, down arrow

math.randomseed(os.time())

function love.load()
	--love.window.setFullscreen(1)
	love.window.setTitle("Pong")
	love.graphics.setBackgroundColor(10,10,10,255)

	largefont = love.graphics.newFont(24)
	font = love.graphics.newFont(16)
	love.graphics.setFont(font)

	-- 0 = titlescreen
	-- 1 = single
	-- 2 = multiplayer
	-- 3 = paused
	mode = 0
	oldmode = 0

	initGame()
end

-- initialise the game
function initGame()
	pitch = {}
	player1 = {}
	player2 = {}
	ball = {}

	pitch.w = love.graphics.getWidth() - 80
	pitch.h = love.graphics.getHeight() - 80
	pitch.x = 40
	pitch.y = 40

	player1.w = 15
	player1.h = 70
	player1.score = 0

	player2.w = 15
	player2.h = 70
	player2.score = 0

	ball.w = 10
	ball.h = 10

	resetPaddles()
	resetBall()

end

-- place ball at center of pitch
function resetBall()
	ball.x = (love.graphics.getWidth() / 2) - (ball.w / 2)
	ball.y = (love.graphics.getHeight() / 2) - (ball.h / 2)
	ball.angle = 0
	ball.xvel = randvelocity()
	ball.yvel = randvelocity()

end

-- reset state of paddles
function resetPaddles()
        player1.y = (love.graphics.getHeight() / 2) - (player1.h / 2)
        player1.x = pitch.x - 1
        player2.y = (love.graphics.getHeight() / 2) - (player2.h / 2)
        player2.x = pitch.w + 25
end

-- set a random speed for the ball
function randvelocity()
	val = math.random(-400,400)
	if val < 250 and val > -250 then
		randvelocity()
	end
		return val

end

-- bounding boxes
function checkCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end


function love.draw()
	--pitch
	love.graphics.setColor(30,30,30,255)
	love.graphics.rectangle("fill", pitch.x, pitch.y, pitch.w, pitch.h)

	--pitch boundaries
	love.graphics.setColor(100,150,180,255)
	love.graphics.line(pitch.x, pitch.y, love.graphics.getWidth() - pitch.x, pitch.y)
	love.graphics.line(pitch.x, pitch.h + pitch.y, love.graphics.getWidth() - pitch.x, pitch.h + pitch.y)
	

	--paddles
	love.graphics.setColor(80,150,180,255)
	love.graphics.rectangle("fill", player1.x, player1.y, player1.w, player1.h)
	love.graphics.rectangle("fill", player2.x, player2.y, player2.w, player2.h)
	love.graphics.setColor(0,0,0,255)
	love.graphics.rectangle("line", player1.x, player1.y, player1.w, player1.h)
	love.graphics.rectangle("line", player2.x, player2.y, player2.w, player2.h)

	--ball
	love.graphics.setColor(10,130,200,255)
	love.graphics.circle("fill", ball.x, ball.y, ball.w, ball.h)
	love.graphics.setColor(0,0,0,255)
	love.graphics.circle("line", ball.x, ball.y, ball.w, ball.h)


	--titlesscreen overlay
	if mode == 0 or mode == 3 then
		love.graphics.setColor(0,0,0,200)
		love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	end

	--titlescreen
	if mode == 0 then
		love.graphics.setFont(largefont)
		love.graphics.setColor(100,200,255,255)
		fontStr = "PONG"
		love.graphics.print(fontStr, love.graphics.getWidth()/2 - largefont:getWidth(fontStr)/2, love.graphics.getHeight()/2 - 50)
		

		love.graphics.setFont(font)
		love.graphics.setColor(200,225,255,255)
		fontStr = "[F1] Singleplayer"
		love.graphics.print(fontStr, love.graphics.getWidth()/2 - font:getWidth(fontStr)/2, love.graphics.getHeight()/2)
		love.graphics.setColor(200,225,255,255)
		fontStr = "[F2] Multiplayer"
		love.graphics.print(fontStr, love.graphics.getWidth()/2 - font:getWidth(fontStr)/2, love.graphics.getHeight()/2 + 20)
	end

	-- singleplayer scoreboard
	if mode == 1 then
		love.graphics.setFont(font)
		love.graphics.setColor(200,225,255,255)
		scoreStr = "Player [".. player1.score .. " - " .. player2.score .. "] CPU"
		love.graphics.print(scoreStr, love.graphics.getWidth()/2 - font:getWidth(scoreStr)/2, pitch.x/2)
	end
	-- multi scoreboard
	if mode == 2 then
		love.graphics.setFont(font)
		love.graphics.setColor(255,225,255,255)
		scoreStr = "Player one [".. player1.score .. " - " .. player2.score .. "] Player two"
		love.graphics.print(scoreStr, love.graphics.getWidth()/2 - font:getWidth(scoreStr)/2, pitch.x/2)
	end

	if mode == 3 then
		love.graphics.setFont(largefont)
		love.graphics.setColor(100,200,255,255)
		fontStr = "PAUSED"
		love.graphics.print(fontStr, love.graphics.getWidth()/2 - largefont:getWidth(fontStr)/2, love.graphics.getHeight()/2 - 50)
	end

end

function love.keypressed(key)
	if not (mode == 0) then
		-- pause
		if key == "p" then
			if mode == 3 then
				mode = oldmode
			else 
				oldmode = mode
				mode = 3
			end
		end
		-- exit to title
		if key == "escape" then
			mode = 0
			initGame()
		end
	else
		-- exit game
		if key == "escape" then
			love.event.quit()
		end

		-- mode select
		if key == "f1" then
			mode = 1
			initGame()
		end
		if key == "f2" then
			mode = 2
			initGame()
		end

	end
end

function love.update(dt)

	-- cap fps at 60
	if dt < 1/60 then
		love.timer.sleep(1/60 - dt)
	end

	main(dt)
end




function main(dt)
	-- is paused?
	if not (mode == 3) then

	-- player 1 controls
	if mode == 1 or mode == 2 then 
		if love.keyboard.isDown("w") and not (player1.y < pitch.y) then
			player1.y = player1.y -300 * dt
		end

		if love.keyboard.isDown("s") and not (player1.y >= (pitch.h - player1.h) + pitch.y - (pitch.y/4)) then
			player1.y = player1.y +300 * dt
		end
	end
	--player2 controls
	if mode == 2 then
		if love.keyboard.isDown("up") and not (player2.y < pitch.y) then
			player2.y = player2.y -300 * dt
		end

		if love.keyboard.isDown("down") and not (player2.y >= (pitch.h - player2.h) + pitch.y - (pitch.y/4)) then
			player2.y = player2.y +300 * dt
		end
	end


	-- ai (player 1)
	if mode == 0 then
		if ball.xvel > 0 then
			if ball.x < pitch.w -(pitch.w/3) and not (ball.x > pitch.w-(pitch.w/4)) then
				if ball.y < player1.y + (player1.h/2) and not (player1.y <= pitch.y) then
					player1.y = player1.y -300 * dt
				end

				if ball.y > player1.y + (player1.h/2) then
					player1.y = player1.y +300 * dt
				end
			end
		end
	end
	-- ai (player 2)
	if mode == 0 or mode == 1 then
		if ball.xvel < 0 then
			if ball.x > (pitch.w/3) and not (ball.x < pitch.w/4) then
				if ball.y < player2.y + (player2.h/2) and not (player2.y <= pitch.y) then
					player2.y = player2.y -300 * dt
				end

				if ball.y > player2.y + (player2.h/2) then
					player2.y = player2.y +300 * dt
				end
			end
		end
	end



	-- move the ball
	ball.x = ball.x - ball.xvel * dt
	ball.y = ball.y - ball.yvel * dt

	-- gradually increase ball speed
	if ball.xvel < 0 then
		ball.xvel = ball.xvel - 0.1
	else 
		ball.xvel = ball.xvel + 0.1
	end

	-- check left left paddle
	--if ball.x < (player1.x + player1.w) then
	if checkCollision(player1.x, player1.y, player1.w, player1.h,
			 ball.x, ball.y, ball.w, ball.h) then
		ball.xvel = -ball.xvel
	end
	--end

	-- check right paddle
	if checkCollision(player2.x, player2.y, player2.w, player2.h,
			ball.x, ball.y, ball.w, ball.h) then
		ball.xvel = -ball.xvel
	end

	-- bounce ball from top
	if ball.y < (pitch.y + ball.h) then
		ball.yvel = -ball.yvel
	end

	-- bounce ball from bottom
	if ball.y > (pitch.h + ball.h) then
		ball.yvel = -ball.yvel
	end

	-- check if ball scored 
	if ball.x < (pitch.x - 300) and ball.x < player1.x then
		player2.score = player2.score + 1
		resetPaddles()
		resetBall()
	end

	if ball.x > (pitch.w + 300) and ball.x > player2.x then
		player1.score = player1.score + 1
		resetPaddles()
		resetBall()
	end

	end

end
