--@class entity
return {
	transform = {},
	game_object = { is_factory = true, factory_url = "/entities#debug_panel", remove_delay = 0.2 },
	druid_widget = { widget_id = "debug_panel", widget_class = require("entity.debug_panel.debug_panel") },
}
