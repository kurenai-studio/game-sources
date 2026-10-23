---@type entity
return {
	["tile_portal"] = {
		transform = { size_x = 128, size_y = 128 },
		game_object = { factory_url = "/entities#tile_portal", remove_delay = 0.5 },
		field = { glue = true },
		field_portal = true,
		field_appear = { delay = 0 },
	},
	["tile_portal_2"] = {
		transform = { size_x = 128, size_y = 128 },
		game_object = { factory_url = "/entities#tile_portal_2", remove_delay = 0.5 },
		field = { glue = true },
		field_portal = true,
		field_appear = { delay = 0 },
	},
}
