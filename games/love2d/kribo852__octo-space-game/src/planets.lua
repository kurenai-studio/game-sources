planets = {}

function planets.initialize_planets()

	local color_themes = require "color_themes"

	for i=1,25 do
		local colortypes = {color_themes.red_theme, color_themes.white_theme}
		local select = love.math.random(#colortypes)

		::redo_generation::
		
		local radius = math.sqrt(love.math.random(3000*3000))
		local angle = 2.0*math.pi*love.math.random()

		for j=1,#planets do
			if math.sqrt((planets[j].x - radius * math.cos(angle))^2 + (planets[j].y - radius * math.sin(angle))^2) < 350 then
				goto redo_generation
			end
		end

		local set_aura_intensity = function () 
									if colortypes[select] == color_themes.red_theme then 
										return 0.05 
									end 
									return 0.005 
								end

		planets[i] = {
					x=radius * math.cos(angle), 
					y=radius * math.sin(angle), 
					red=colortypes[select].red, 
					green=colortypes[select].green, 
					blue=colortypes[select].blue,
					radius = 35 + love.math.random(25),
					aura_intensity = set_aura_intensity(select)
				}
	end

end

return planets