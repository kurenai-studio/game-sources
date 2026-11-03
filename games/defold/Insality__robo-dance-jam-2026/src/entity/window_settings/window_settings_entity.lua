local event = require("event.event")

---@diagnostic disable: missing-fields
---@type entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#window_settings", remove_delay = 0.2 },
	druid_widget = { widget_id = "window_settings", widget_class = require("entity.window_settings.window_settings") },
	window_settings = {},
}
