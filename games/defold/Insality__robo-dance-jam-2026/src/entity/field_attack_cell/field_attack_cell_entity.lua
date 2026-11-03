local abilities = require("game.abilities")

---@diagnostic disable: missing-fields
---@class entity
return {
	transform = { size_x = 125, size_y = 115 },
	game_object = { collectionfactory_url = "/entities#field_attack_cell" },
	panthera = { animation_path = require("entity.field_attack_cell.field_attack_cell_panthera"), play_on_start = "default" },
	field_actor = {
		z = 1.1,
		height = 1,
		solid = false,
		movable = false,
		health = 0,
		remove_on_death = true,
	},
	turn_list = {
		intro_sequence_list = {
			{ abilities.damage_1.id },
		},
	},
}
