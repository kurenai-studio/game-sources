color_themes = require "color_themes"

local deep_sky = {

}

function deep_sky.init_stars()
	local star_array = {}
	for i=1,100 do
		star_array[i] = {x=love.math.random(love.graphics.getWidth()), y=love.math.random(love.graphics.getHeight())}
	end
	return star_array
end

function deep_sky.draw() 
	love.graphics.setBackgroundColor(color_themes.background.red, color_themes.background.green, color_themes.background.blue)
	local r, g, b = love.graphics.getColor()
	for i=1,#deep_sky.star_array do
		love.graphics.setColor(color_themes.white_theme.red, color_themes.white_theme.green, color_themes.white_theme.blue, 0.25)
		love.graphics.rectangle("fill", deep_sky.star_array[i].x, deep_sky.star_array[i].y, 3, 3)
	end
	love.graphics.setColor(r, g, b)
end

deep_sky.star_array = deep_sky.init_stars()

return deep_sky