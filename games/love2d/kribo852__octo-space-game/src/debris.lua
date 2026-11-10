debris = {}

function debris.set_player_function(player_function)
	debris.player_function = player_function
end

function debris.update()

	local p_f = debris.player_function --this is to retrieve the player position

	if #debris < 50 then

		local angle = love.math.random() * 2 * math.pi
		local new_dist = love.math.random(600, 1000)

		table.insert(debris, { 
		x = p_f().x + new_dist * math.cos(angle),
		y = p_f().y + new_dist * math.sin(angle) 
		})
	end

	for i=1,#debris do
		local dist = math.sqrt((p_f().x - debris[i].x)^2 + (p_f().y - debris[i].y)^2)

		if dist > 1000 then 
			local angle = love.math.random() * 2 * math.pi
			local new_dist = love.math.random(600, 1000)
			debris[i] = {
						x = p_f().x + new_dist * math.cos(angle),
						y = p_f().y + new_dist * math.sin(angle) 
						}
		end
	end
end

function clear()
  table.clear(debris)
end

return debris
