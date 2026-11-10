local color_themes = {
	red_theme = {red=0.75, green=0.1, blue=0.125},
	white_theme = {red=0.75, green=0.7, blue=0.95},
	background = {red=0.01, green=0.03, blue=0.06},
	prothagonist_green = {red=0.05, green=0.5, blue=0.3},
	debris_theme = {red = 0.3, green = 0.15, blue=0.2}
}

function color_themes.apply_color(rgb_obj, func, alpha)
	func(rgb_obj.red, rgb_obj.green, rgb_obj.blue, 
		(function() 
			if alpha then 
				return alpha 
			end
				return 1 end)()
		)
end


return color_themes