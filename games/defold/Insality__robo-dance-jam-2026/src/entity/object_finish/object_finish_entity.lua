---@diagnostic disable: missing-fields
---@class entity
return {
	object_finish_visual = true,
	field_appear = true,
	field_actor = {
		movable = false,
		solid = false,
	},
	transform = {},
	game_object = { collectionfactory_url = "/entities#object_finish" },
	panthera = { animation_path = require("entity.object_finish.object_finish_panthera") },
}
