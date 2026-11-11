extends Node
## Presentation frame limits never change simulation ticks or race results.
var preferences := {}
var focused := true

static func limit_for(values: Dictionary, foreground: bool) -> int:
	var selected: String = values.get("frame_limit","60")
	var foreground_limit := 0 if selected == "Unlimited" else int(selected)
	if foreground: return foreground_limit
	var background_limit := int(values.get("background_fps",15))
	return background_limit if foreground_limit == 0 else mini(background_limit,foreground_limit)

func _ready() -> void:
	focused = DisplayServer.window_is_focused()

func configure(values: Dictionary) -> void:
	preferences = values
	apply()

func apply() -> void:
	OS.low_processor_usage_mode = true
	Engine.max_fps = limit_for(preferences,focused)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if preferences.get("vsync",true) else DisplayServer.VSYNC_DISABLED)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		apply()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		apply()
