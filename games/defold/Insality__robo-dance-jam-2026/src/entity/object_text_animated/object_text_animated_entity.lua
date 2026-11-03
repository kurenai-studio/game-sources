---@diagnostic disable: missing-fields
---@class entity
return {
	transform = {},
	game_object = { collectionfactory_url = "/entities#object_text_animated" },
	druid_widget = { widget_class = require("entity.object_text_animated.object_text_animated_widget"), widget_id = "object_text_animated_widget" },
	object_text_animated_visual = {
		text = "ui_thanks_for_playing",
		color = "#F6E383"
	},
}
