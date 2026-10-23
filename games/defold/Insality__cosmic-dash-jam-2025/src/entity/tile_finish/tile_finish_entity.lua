---@diagnostic disable: missing-fields
---@type entity
return {
	transform = { size_x = 128, size_y = 128 },
	game_object = { factory_url = "/entities#tile_finish", remove_delay = 0.5 },
	field = { glue = true },
	field_finish = true,
	field_appear = { delay = 0 },
}
