---@diagnostic disable: missing-fields
---@type entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#debug_panel" },
	druid_widget = { widget_class = require("entity.debug_panel.debug_panel"), widget_id = "debug_panel" },
}
