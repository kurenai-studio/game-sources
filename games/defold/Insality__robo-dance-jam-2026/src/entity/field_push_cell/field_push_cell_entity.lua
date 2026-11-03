local abilities = require("game.abilities")

---@diagnostic disable: missing-fields
---@class entity
return {
	transform = { size_x = 125, size_y = 115 },
	game_object = { collectionfactory_url = "/entities#field_push_cell" },
	panthera = { animation_path = require("entity.field_push_cell.field_push_cell_panthera"), play_on_start = "default" },
	field_actor = {
		z = -1,
		height = 0,
		solid = false,
		movable = false,
		health = 0,
		remove_on_death = true,
	},
	turn_list = {
		intro_sequence_list = {
			{ abilities.push_1.id },
		},
	},
}
