---@diagnostic disable: missing-fields
---@type entity
return {
	transform = { size_x = 128, size_y = 128 },
	game_object = { factory_url = "/entities#tile_floor_bg", remove_delay = 0.5 },
	field = { floor = true },
	field_appear = { delay = 0 },
}
