local event = require("event.event")

---@return entity
return {
	transform = {},
	game_object = { is_factory = true, factory_url = "/entities#window_settings", remove_delay = 0.2 },
	druid_widget = { widget_id = "window_settings", widget_class = require("entity.window_settings.window_settings") },
	window_settings = { on_menu = event.create() },
}
