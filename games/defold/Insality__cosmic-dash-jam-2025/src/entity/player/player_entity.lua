---@diagnostic disable: missing-fields
---@type entity
return {
	transform = { size_x = 128, size_y = 128 },
	game_object = { factory_url = "/entities#player" },
	field = { solid = true },
	player = true,
	panthera = { animation_path = require("entity.player.player_panthera"), default_animation = "idle", is_loop = true, play_on_start = "idle" },
	player_visual = true,
	field_movable = true,
	user_controlled = true,
}
