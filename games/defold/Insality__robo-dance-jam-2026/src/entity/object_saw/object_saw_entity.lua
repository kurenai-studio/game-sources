local abilities = require("game.abilities")

---@diagnostic disable: missing-fields
---@class entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#object_saw" },
	field_actor = {
		movable = true,
		solid = false,
		pushable = true,
		z = 1.25,
		health = 8,
		height = 0.5,
	},
	panthera = { animation_path = require("entity.object_saw.object_saw_panthera") },
	object_saw = true,
	turn_list = {
		scheduled = {},
		pattern_index = 1,
		pattern_on_damage = "inert",
	},
	patterns = {
		list = {
			["patrol"] = {
				{ "saw_1", "+left" },
				{ "saw_1" },
			},
			["patrol_slow"] = {
				{ "saw_1", "+left" },
				{ "saw_1" },
				{ "saw_1", "none" },
			},
			["patrol_2"] = {
				{ "saw_1" },
				{ "saw_1", "+left" },
			},
			["patrol_line"] = {
				{ "saw_1", "+down" },
				{ "saw_1", },
				{ "saw_1", "+down" },
				{ "saw_1" },
			},
			["inert"] = {
				{ "saw_1" },
			},
		}
	},
	field_appear = true
}
