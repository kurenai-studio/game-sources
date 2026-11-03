---@diagnostic disable: missing-fields
---@class entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#gui_game" },
	druid_widget = { widget_class = require("entity.gui_game.gui_game"), widget_id = "gui_game" },
	gui_game = {}
}
