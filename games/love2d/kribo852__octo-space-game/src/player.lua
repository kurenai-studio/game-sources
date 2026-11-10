
player = {}

function player.init()
	player.angle = 0
	player.speed_x = 0
	player.speed_y = 0
	player.angular_velocity = 0
	player.x = 0
	player.y = 0
	player.animation = 0 
end

function player.accelerate()
	player.speed_x = player.speed_x + 0.025 * math.cos(player.angle)
	player.speed_y = player.speed_y + 0.025 * math.sin(player.angle) 
end

function player.turn(direction)
	player.angular_velocity = player.angular_velocity + direction * 0.005 * math.abs(0.25 - player.angular_velocity)
end

function player.move()
	player.angle = player.angle + player.angular_velocity
	player.x = player.x + player.speed_x
	player.y = player.y + player.speed_y

	player.angular_velocity = player.angular_velocity - 0.015 * player.angular_velocity 
end

function player.jump_wormhole()
	local distance = 450

	player.x = player.x + distance * math.cos(player.angle)
	player.y = player.y + distance * math.sin(player.angle)
end


return player