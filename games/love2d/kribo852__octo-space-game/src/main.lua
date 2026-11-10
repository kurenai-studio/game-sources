keyboard = require "keyboard"
deep_sky = require "deep_sky"
drawer = require "drawer"
planets = require "planets"
color_themes = require "color_themes"
action_runner = require "action_runner"
player = require "player"
opponents = require "opponents"
debris = require "debris"
wormhole_animation = require "wormhole_animation"

function love.load()
	love.window.setTitle( "Escape space pirates" )
	current_game_state = "menu"

	keyboard.hello()
	keyboard.register_key_binding("run_game", "up", function ()
		player.accelerate()
	end)

	keyboard.register_key_binding("run_game", "right", function ()
		player.turn(1)
	end)

	keyboard.register_key_binding("run_game", "left", function ()
		player.turn(-1)
	end)

	keyboard.register_key_binding("menu", "n", function ()
		current_game_state = "run_game"
		reset_game()
		action_runner.add_action(update_during_active_game)
	end)

	keyboard.register_key_binding("run_game", "escape", function ()
		current_game_state = "menu"
	end)

	keyboard.register_key_binding("menu", "1", function ()
		love.event.quit()
	end)

	keyboard.register_key_binding("game_over", "n", function ()
		current_game_state = "run_game"
		reset_game()
		action_runner.add_action(update_during_active_game)
	end)

	keyboard.register_key_binding("game_over", "1", function ()
		love.event.quit()
	end)

	drawer.register_draw_action("run_game", function() deep_sky.draw() draw_debris() draw_player() draw_opponents() draw_planets() draw_score() draw_minimap(700, 550) draw_lifeometer(650, 450) end)
	drawer.register_draw_action("menu", function() deep_sky.draw() color_themes.apply_color(color_themes.white_theme, love.graphics.setColor) love.graphics.print("Press n for a new game, \n! to quit \nControl the spaceship with the arrow keys, and open a wormhole with the space key", 100, 100) end)
	drawer.register_draw_action("game_over", game_over_draw)

	beep()
end

function reset_game()
	player.init()
	planets.initialize_planets()
	opponents.clear()
	opponents.set_player_info(function() return player end)
	debris.set_player_function(function() return player end)
	score = 0
	life = 8
end

function update_during_active_game() 
	apply_gravitation() 
	player.move() 
	opponents.update() 
	update_score() 
	hit_by_lasers()
	crash_opponents_into_planets()
	debris.update()
	set_game_over() 
	return not (current_game_state == "game_over" or current_game_state == "menu") -- continue running this action next update, has to account for menu 
end

function love.draw()
	drawer.draw(current_game_state)
end

function draw_player()
	local middle_w,middle_h = screen_center()

	color_themes.apply_color(color_themes.prothagonist_green, love.graphics.setColor, 1-player.animation)
	draw_caret(middle_w, middle_h, player.angle)

	if player.animation > 0.0001 then
		wormhole_animation.draw(middle_w, middle_h, player.angle, player.animation)
	end

	-- speedometer
	color_themes.apply_color(color_themes.white_theme, love.graphics.setColor)
	love.graphics.line(700, 200, 700 + 20 * player.speed_x, 200 + 20 * player.speed_y)
end


function draw_planets()
	return draw_planets_with_camera(player.x, player.y)
end

function draw_planets_with_camera(camera_x, camera_y)
	local center_screen_w,center_screen_h = screen_center()
	for i = 1,#planets do
		love.graphics.setColor(planets[i].red, planets[i].green, planets[i].blue, planets[i].aura_intensity)
		love.graphics.circle("fill", center_screen_w + (planets[i].x-camera_x), center_screen_h + (planets[i].y-camera_y), planets[i].radius*1.60)

		color_themes.apply_color(planets[i], love.graphics.setColor)
		love.graphics.arc("fill", center_screen_w + (planets[i].x-camera_x), center_screen_h + (planets[i].y-camera_y), planets[i].radius, -math.pi/2+math.pi/12, math.pi/2+math.pi/12, 16)
		
		color_themes.apply_color({red=planets[i].red*0.075, green=planets[i].green*0.075, blue=planets[i].blue*0.075}, love.graphics.setColor)
		love.graphics.arc("fill", center_screen_w + (planets[i].x-camera_x), center_screen_h + (planets[i].y-camera_y), planets[i].radius, math.pi/2+math.pi/12, 3*math.pi/2+math.pi/12, 16)
	end
end

function draw_debris()
	return draw_debris_with_camera(player.x, player.y)
end

function draw_debris_with_camera(camera_x, camera_y)
	local center_screen_w,center_screen_h = screen_center()
	for i = 1,#debris do
		color_themes.apply_color(color_themes.debris_theme, love.graphics.setColor)
		love.graphics.circle("fill", center_screen_w + (debris[i].x-camera_x), center_screen_h + (debris[i].y-camera_y), 3)
	end
end

function draw_minimap(screen_x, screen_y)
	local minimap_scale = 100

	color_themes.apply_color(color_themes.prothagonist_green, love.graphics.setColor)
	love.graphics.circle("fill", screen_x, screen_y, 2)
	
	for i = 1,#planets do
		color_themes.apply_color(planets[i], love.graphics.setColor)
		local minimap_diff_x = (planets[i].x - player.x)/minimap_scale
		local minimap_diff_y = (planets[i].y - player.y)/minimap_scale
		love.graphics.circle("fill", screen_x + minimap_diff_x , screen_y + minimap_diff_y, 2)
	end
end

function game_over_draw()
	deep_sky.draw()
	draw_score()
	color_themes.apply_color(color_themes.white_theme, love.graphics.setColor)
	love.graphics.print("Game over\nPress n for a new game,\n! to quit", 100, 100)
end

function draw_opponents()
	local middle_w,middle_h = screen_center()
	for i=1,#opponents do
		color_themes.apply_color(color_themes.red_theme, love.graphics.setColor)
		draw_caret(middle_w + opponents[i].x - player.x, middle_h + opponents[i].y - player.y, opponents[i].angle)		
	end

	color_themes.apply_color(color_themes.red_theme, love.graphics.setColor, 0.85)
	for i,laser in ipairs(opponents.laser_beams) do
		love.graphics.circle("fill", middle_w + laser.x - player.x, middle_h + laser.y - player.y, 3)
	end

end

function draw_caret(xpos, ypos, angle)
	love.graphics.line(xpos + 10*math.cos(angle), ypos + 10*math.sin(angle), 
		xpos + 10*math.cos(angle + math.pi*0.9), ypos + 10*math.sin(angle + math.pi*0.9))
	love.graphics.line(xpos + 10*math.cos(angle), ypos + 10*math.sin(angle), 
		xpos + 10*math.cos(angle - math.pi*0.9), ypos + 10*math.sin(angle - math.pi*0.9))
end

function draw_score()
	color_themes.apply_color(color_themes.prothagonist_green, love.graphics.setColor)
	love.graphics.print("Score "..score)
	love.graphics.print(string.format("mem.use KB %d", collectgarbage("count")), 550)
end

function draw_lifeometer(xpos, ypos)
	color_themes.apply_color(color_themes.prothagonist_green, love.graphics.setColor)
	love.graphics.rectangle("fill", xpos, ypos, 12.5*life+1, 5)
end

function love.update()
	action_runner.run_actions()
	keyboard.run_key_actions(current_game_state)
end

function love.keypressed(key, scancode, isrepeat)
   if key == "space" then
      action_runner.add_action(wormhole())
   end
end

function apply_gravitation()
	local scale = 150.0
	local min_gravitation_radius = 50.0
	for i=1,#planets do
		distance = math.sqrt( (planets[i].x - player.x)^2 + (planets[i].y - player.y)^2)
		if(distance < 2000) then
			--print('distance '..distance)

			local strength = scale/(math.pow(math.max(distance, min_gravitation_radius), 2))
		
			player.speed_x = player.speed_x + strength*((planets[i].x - player.x)/distance)
			player.speed_y = player.speed_y + strength*((planets[i].y - player.y)/distance)
		end
	end
end

function set_game_over()
	for i=1,#planets do
		distance = math.sqrt( (planets[i].x - player.x)^2 + (planets[i].y - player.y)^2)
		if( distance < planets[i].radius ) then
			current_game_state = "game_over"
			break
		end
	end

	if life <= 0 then
		current_game_state = "game_over"
	end
end

function crash_opponents_into_planets()

	local crash = function(opponent)
		for i,planet in ipairs(planets) do
			local diff_x = opponent.x - planet.x
			local diff_y = opponent.y - planet.y

			if math.sqrt(diff_x^2 + diff_y^2) < planet.radius  then 
				return true
			end 
		end
		return false
	end

	opponents.remove_item(opponents, crash)
end

function update_score()
	score = score + 1
end

function hit_by_lasers()
	for index,laser in ipairs(opponents.laser_beams) do
		if(math.sqrt((player.x - laser.x)^2 + (player.y - laser.y)^2 ) < 6) then
			life = life - 1
		end
	end
end

function wormhole()
	if player.animation < 0.001 then --only start if there is no current wormhole
		local timer = 0
		print("worm hole")
		return function()
			if timer == 0 then
				wormhole_beep()
			end
			timer = timer + 1
			player.animation = timer/100

			if player.animation >= 1 then
				player.animation = 0
				player.jump_wormhole()
				return false
			end
			return true
		end
	end
	return function() return false end -- empty function
end

function screen_center()
	return love.graphics.getWidth()/2,love.graphics.getHeight()/2
end

function beep() 
	local rate      = 10000 -- samples per second
	local length    = 10  -- seconds
	local tone      = 300.0 -- Hz
	local soundData = love.sound.newSoundData(math.floor(length*rate), rate, 16, 1)
	for i=0, soundData:getSampleCount() - 1 do
		local tone_number = tone*math.pow(math.sqrt(2^0.5), 1 + math.floor((2*i) / rate)%10)   
		soundData:setSample(i, math.sin(tone_number*2*math.pi*i/rate))
	end
	local source = love.audio.newSource(soundData)
	source:setVolume(0.1)
	source:play()
end

function wormhole_beep()
	local rate      = 10000 -- samples per second
	local length    = 2  -- seconds
	local tone      = 300.0 -- Hz
	local soundData = love.sound.newSoundData(math.floor(length*rate), rate, 16, 1)
	for i=0, soundData:getSampleCount() - 1 do   

		if i <  0.3 * rate then
			soundData:setSample(i, -1 + 2 * love.math.random())
		else
			local distorted_frequency = 0.8 + 0.2 * math.sin(5*math.pi*i/rate)
			soundData:setSample(i, math.sin(tone*2*math.pi*i*distorted_frequency/rate))
		end
	end
	local source = love.audio.newSource(soundData)
	source:setVolume(0.1)
	source:play()
end


