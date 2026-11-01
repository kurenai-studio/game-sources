extends Node
## Lays the interface out for the screen's shape: a 1280×720 canvas on a
## wide screen, 720×1280 on a tall one, so a phone held upright gets
## full-size buttons rather than a shrunken landscape layout.
## Autoloaded as `WindowFit`.


func _ready() -> void:
	get_tree().root.size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var win := get_window()
	var tall := win.size.y > win.size.x
	var want := Vector2i(720, 1280) if tall else Vector2i(1280, 720)
	if win.content_scale_size != want:
		win.content_scale_size = want
