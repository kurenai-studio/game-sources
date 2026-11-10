wormhole_animation = {}

function wormhole_animation.draw(position_x, position_y, angle, completion) 
	local color_themes = require "color_themes"
	love.graphics.setColor(color_themes.white_theme.red, color_themes.white_theme.green, color_themes.white_theme.blue, completion)

	for n_of_circles=1,10 do

		local size = 1/(1+n_of_circles)

		for circle_angle=1,10 do
			local px_fragment = 25 * n_of_circles + 30 * size * math.cos(circle_angle*math.pi*2/10 + math.pi*2*completion/3)
			local py_fragment = 50 * size * math.sin(circle_angle*math.pi*2/10 + math.pi*2*completion/3)

			local px_rotated = px_fragment * math.cos(angle) - py_fragment * math.sin(angle)
			local py_rotated = px_fragment * math.sin(angle) + py_fragment * math.cos(angle)

			love.graphics.rectangle("fill", position_x + px_rotated, position_y + py_rotated, 2, 2)
		end
	end

end

return wormhole_animation