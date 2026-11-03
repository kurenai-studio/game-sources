---@diagnostic disable: missing-fields
---@class entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#background" },
	druid_widget = { widget_class = require("entity.background.background"), widget_id = "background" },
	background = true,
}
