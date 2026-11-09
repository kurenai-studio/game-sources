function love.load()
	love.physics.setMeter( 64 )
	world = love.physics.newWorld( 0, 0, true ) -- 9.81*64
	world:setCallbacks( beginContact, endContact, nil, nil )
	
	-- ... --
	
	objects = {}
	
	-- ... --
	
	objects.playerRacket = {}
	objects.playerRacket.body = love.physics.newBody( world, 885, 250 )
	objects.playerRacket.shape = love.physics.newRectangleShape( 10, 60 )
	objects.playerRacket.fixture = love.physics.newFixture( objects.playerRacket.body, objects.playerRacket.shape )
	objects.playerRacket.fixture:setUserData( "Player's Racket" )
	
	-- ... --
	
	objects.cpuRacket = {}
	objects.cpuRacket.body = love.physics.newBody( world, 15, 250, "kinematic" )
	objects.cpuRacket.shape = love.physics.newRectangleShape( 10, 60 )
	objects.cpuRacket.fixture = love.physics.newFixture( objects.cpuRacket.body, objects.cpuRacket.shape )
	objects.cpuRacket.fixture:setUserData( "CPU's Racket" )
	
	-- ... --
	
	objects.ball = {}
	objects.ball.body = love.physics.newBody( world, 900/2, 500/2, "dynamic" )
	objects.ball.shape = love.physics.newCircleShape( 10 )
	objects.ball.fixture = love.physics.newFixture( objects.ball.body, objects.ball.shape, 1 )
	objects.ball.fixture:setRestitution( 0.9 ) -- from 1.3 to 2
	objects.ball.fixture:setUserData( "The Ball" )
	
	-- ... --
	
	objects.topWall = {}
	objects.topWall.body = love.physics.newBody( world, 0, -5 )
	objects.topWall.shape = love.physics.newRectangleShape( 1900, 10 )
	objects.topWall.fixture = love.physics.newFixture( objects.topWall.body, objects.topWall.shape )
	objects.topWall.fixture:setUserData( "Top Wall" )
	
	objects.bottomWall = {}
	objects.bottomWall.body = love.physics.newBody( world, 0, 505 )
	objects.bottomWall.shape = love.physics.newRectangleShape( 1900, 10 )
	objects.bottomWall.fixture = love.physics.newFixture( objects.bottomWall.body, objects.bottomWall.shape )
	objects.bottomWall.fixture:setUserData( "Bottom Wall" )
	
	objects.rightWall = {}
	objects.rightWall.body = love.physics.newBody( world, 920, 0 )
	objects.rightWall.shape = love.physics.newRectangleShape( 10, 1000 )
	objects.rightWall.fixture = love.physics.newFixture( objects.rightWall.body, objects.rightWall.shape )
	objects.rightWall.fixture:setUserData( "Right Wall" )
	
	objects.leftWall = {}
	objects.leftWall.body = love.physics.newBody( world, -5, 0 )
	objects.leftWall.shape = love.physics.newRectangleShape( 10, 1000 )
	objects.leftWall.fixture = love.physics.newFixture( objects.leftWall.body, objects.leftWall.shape )
	objects.leftWall.fixture:setUserData( "Left Wall" )
	
	-- ... --
	
	love.graphics.setBackgroundColor( 72, 160, 14 )
	love.window.setMode( 900, 500 )
	
	gameState = "initial"
	ballVelocity = 0
	ballAngle = -86
	playerScores = 0
	cpuScores = 0
	lastPlayer = "player"
end

function love.update( dt )
	world:update( dt )
	
	if gameState == "initial" then
		objects.ball.body:applyForce( 4500, 0 )
		gameState = "started"
	end
	
	if love.keyboard.isDown( "up" ) then
		objects.playerRacket.body:setY( objects.playerRacket.body:getY() - 5 )
	elseif love.keyboard.isDown( "down" ) then
		objects.playerRacket.body:setY( objects.playerRacket.body:getY() + 5 )
	end
end

function love.draw()
	if gameState == "Out" or gameState == "Score" then
		objects.ball.body:setX( 900 / 2 )
		objects.ball.body:setY( 500 / 2 )
		objects.ball.body:setActive( false )
		
		objects.cpuRacket.body:setX( 15 )
		objects.cpuRacket.body:setY( 250 )
		objects.cpuRacket.body:setLinearVelocity( 0, 0 )
		
		objects.playerRacket.body:setX( 885 )
		objects.playerRacket.body:setY( 250 )
	elseif gameState == "Activate Ball Request" then
		objects.ball.body:setActive( true )
		objects.ball.body:setLinearVelocity( 200, 0 )
		gameState = "playing"
	end
	
	
	love.graphics.setColor( 255, 255, 255 )
	love.graphics.print( "CPU's Scores " .. cpuScores, 0, 0 )
	love.graphics.print( "Player's Scores " .. playerScores, 780, 0 )
	
	-- ... --
	
	love.graphics.setColor( 255, 255, 255 )
	love.graphics.polygon( "fill", objects.playerRacket.body:getWorldPoints( objects.playerRacket.shape:getPoints() ) ) 
	
	love.graphics.setColor( 255, 255, 255 )
	love.graphics.polygon( "fill", objects.cpuRacket.body:getWorldPoints( objects.cpuRacket.shape:getPoints() ) )
	
	love.graphics.setColor( 193, 47, 14 ) --set the drawing color to red for the ball
	love.graphics.circle( "fill", objects.ball.body:getX(), objects.ball.body:getY(), objects.ball.shape:getRadius() )
	
	-- ... --
	
	love.graphics.setColor( 55, 25, 0 )
	love.graphics.polygon( "fill", objects.topWall.body:getWorldPoints( objects.topWall.shape:getPoints() ) )
	
	love.graphics.setColor( 77, 55, 5 )
	love.graphics.polygon( "fill", objects.bottomWall.body:getWorldPoints( objects.bottomWall.shape:getPoints() ) )
	
	love.graphics.setColor( 22, 99, 55 )
	love.graphics.polygon( "fill", objects.rightWall.body:getWorldPoints( objects.rightWall.shape:getPoints() ) )
	
	love.graphics.setColor( 223, 19, 198 )
	love.graphics.polygon( "fill", objects.leftWall.body:getWorldPoints( objects.leftWall.shape:getPoints() ) )
	
	if gameState == "Out" or gameState == "Score" then
		love.timer.sleep( 0.1 )
		gameState = "Activate Ball Request"
	end
end

function beginContact( firstObj, secondObj, coll )
	if firstObj:getUserData() == "Player's Racket" and secondObj:getUserData() == "The Ball" then
		math.randomseed( os.time() )
		--ballAngle = math.random( -85, 85 )
		ballAngle = math.random( -65, 65 )
		ballVelocity = math.random( 815, 1200 )
		
		secondObj:getBody():setLinearVelocity( ballVelocity, 0 ) -- from 815 to 1200
		secondObj:getBody():setAngularVelocity( ballAngle ) -- from -85 to 85
		
		lastPlayer = "player"
	elseif firstObj:getUserData() == "CPU's Racket" and secondObj:getUserData() == "The Ball" then
		objects.cpuRacket.body:setLinearVelocity( 0, 0 ) -- Stop CPU's racket when the ball collides it
		
		lastPlayer = "cpu"
	elseif ( firstObj:getUserData() == "Top Wall" or firstObj:getUserData() == "Bottom Wall" ) and secondObj:getUserData() == "The Ball" then
		gameState = "Out"
		
		if lastPlayer == "cpu" then
			playerScores = playerScores + 1
		else
			cpuScores = cpuScores + 1
		end
	elseif ( firstObj:getUserData() == "Right Wall" or firstObj:getUserData() == "Left Wall" ) and secondObj:getUserData() == "The Ball" then
		gameState = "Score"
		
		if firstObj:getUserData() == "Right Wall" then
			cpuScores = cpuScores + 5
		else
			playerScores = playerScores + 5
		end
	end
end

function endContact( firstObj, secondObj, coll )
	-- That's my first A.I. code! :-)
	if firstObj:getUserData() == "Player's Racket" and secondObj:getUserData() == "The Ball" then	
		local racketVelocity = 0
		local speedFactor = 1
		
		local absAngle = math.abs( ballAngle )
		
		if ballVelocity >= 800 or absAngle >= 61 then
			speedFactor = 2
		end
		
		if absAngle >= 0 and absAngle <= 10 then
			racketVelocity = 15 * speedFactor
		elseif absAngle >= 11 and absAngle <= 20 then
			racketVelocity = 40 * speedFactor
		elseif absAngle >= 21 and absAngle <= 30 then
			racketVelocity = 45 * speedFactor
		elseif absAngle >= 31 and absAngle <= 40 then
			racketVelocity = 60 * speedFactor
		elseif absAngle >= 41 and absAngle <= 50 then
			racketVelocity = 70 * speedFactor
		elseif absAngle >= 51 and absAngle <= 60 then
			racketVelocity = 80 * speedFactor
		end
		
		if ballAngle > 0 then
			objects.cpuRacket.body:setLinearVelocity( 0, -racketVelocity )
		elseif ballAngle < 0 then
			objects.cpuRacket.body:setLinearVelocity( 0, racketVelocity ) 
		end
	end
end
