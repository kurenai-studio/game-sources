--Bootleg PONG

function love.load()
    win_width, win_height = love.window.getMode()	--Get the size of the game window
    player_speed = 8
	rand = 0
	score_1 = 0
	score_2 = 0
	launch = true
	love.graphics.setNewFont(30)	--Increase the font size

	player_1 = {	--A table containg data about player 1
		x = 50,
		y = (win_height/2) - 25
	}
	player_2 = {	--A table containg data about player 1
		x = win_width - 50,
		y = (win_height/2) - 25
	}
	ball = {	--A table containg data about the ball
		x = win_width/2,
		y = win_height/2,
		vx = 0,
		vy = 0
	}

	math.randomseed(os.time())	--This will set the random number generator algorithm A.K.A its SEED to the system time in seconds. Without this, the random number generator will most likely output the same sequence of numbers every time.
	function rand_num(a, b)	--This function returns a random integer in the range of two other integers. It is used for making the ball bounce because I couldn't figure out how to make it bounce "realistically".
		rand = math.random(a, b)
		return rand
	end
	function inrange(var, a, b)	--This function checks if a number is in the range of two other numbers
		return var >= a and var <=b
	end
	function reset()	--Triggered whenever someone scores
		ball.vx = 0
		ball.vy = 0
		ball.x = win_width/2
		ball.y = win_height/2
		launch = true
	end
end

function love.update(dt)
	--Makes the ball move
    ball.x = ball.x + ball.vx
	ball.y = ball.y + ball.vy
	
	--Collision Checks
    if inrange(ball.x, player_1.x, player_1.x + 25) and inrange(ball.y, player_1.y, player_1.y + 50) then	--Checks if the ball is colliding with player 1
        ball.vx = rand_num(4, 5)
        ball.x = ball.x +  rand
    elseif inrange(ball.x + 10, player_2.x, player_2.x + 25) and inrange(ball.y, player_2.y, player_2.y + 50) then	--Checks if the ball is colliding with player 2
        ball.vx = -(rand_num(4, 5))
        ball.x = ball.x - rand
	elseif ball.y <= 0 then	--Checks if the ball is colliding with the top wall
		ball.vy = rand_num(4, 5)
		ball.y = ball.y + rand
	elseif ball.y >= win_height then	--Checks if the ball is colliding with the bottom wall
		ball.vy = -(rand_num(4, 5))
		ball.y = ball.y - rand
    end

	--Score checking
	if ball.x >= win_width then
		score_1 = score_1 + 1	--Increase player 1's score by one
		reset()
	end
	if ball.x <= 0 then
		score_2 = score_2 + 1	--Increase player 2's score by two
		reset()
	end
	
	--Player Movement
	if love.keyboard.isDown("w") then
		player_1.y = player_1.y - player_speed
	elseif love.keyboard.isDown("s") then
		player_1.y = player_1.y + player_speed
	end
	if love.keyboard.isDown("up") then
		player_2.y = player_2.y - player_speed
	elseif love.keyboard.isDown("down") then
		player_2.y = player_2.y + player_speed
	end
	--Start Game
	if launch == true then
		if love.keyboard.isDown("space") then
			ball.vx = -4
			ball.vy = rand_num(-5, 5)
			launch = false
		end
	end
	
	--Stopping the players form moving outside the screen 
	if player_1.y <= 0 then
		player_1.y = 0
	elseif player_1.y >= win_height - 50 then
		player_1.y = win_height - 50
	end
	if player_2.y <= 0 then
		player_2.y = 0
	elseif player_2.y >= win_height - 50 then
		player_2.y = win_height - 50
	end
end

function love.draw()
	love.graphics.print(score_1, win_width/4, 20)	--Display player 1's score
	love.graphics.print(score_2, win_width - win_width/4, 20)	--Display player 2's score
    love.graphics.circle("fill", ball.x, ball.y, 10)	--Draw ball
	love.graphics.rectangle("line", player_1.x, player_1.y, 15, 50)	--Draw player 1
	love.graphics.rectangle("line", player_2.x, player_2.y, 15, 50)	--Draw player 2
	love.graphics.rectangle("fill", (win_width/2) - 2.5, 0, 5, win_height)	--Draw center line
	love.graphics.rectangle("line", 0, 0, win_width, win_height)		--Draw outline
end