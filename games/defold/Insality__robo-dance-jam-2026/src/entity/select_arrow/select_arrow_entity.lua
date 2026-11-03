---@diagnostic disable: missing-fields
---@class entity
return {
	transform = { size_x = 125, size_y = 125 },
	game_object = { collectionfactory_url = "/entities#select_arrow" },
	select_arrow_visual = {
		side = "up",
	},
	panthera = {
		animation_path = require("entity.select_arrow.select_arrow_panthera"),
		default_animation = "idle",
		is_loop = true,
		play_on_start = true,
	}
}
