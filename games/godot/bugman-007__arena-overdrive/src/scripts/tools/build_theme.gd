extends SceneTree
## Bakes UiTheme.build() into res://ui/theme.tres.
## Usage: godot --headless --path . -s scripts/tools/build_theme.gd


func _init() -> void:
	var theme: Theme = load("res://scripts/ui/ui_theme.gd").build()
	var err := ResourceSaver.save(theme, "res://ui/theme.tres")
	print("theme.tres saved: ", error_string(err))
	quit(0 if err == OK else 1)
