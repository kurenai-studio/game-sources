---@diagnostic disable: missing-fields
---@class entity
return {
	object_box_visual = true,
	transform = {
		size_x = 125,
		size_y = 125,
	},
	game_object = { collectionfactory_url = "/entities#object_box" },
	panthera = { animation_path = require("entity.object_box.object_box_panthera") },
	field_actor = {
		solid = true,
		movable = true,
		pushable = true,
		health = 12,
	},
	field_appear = true
}
