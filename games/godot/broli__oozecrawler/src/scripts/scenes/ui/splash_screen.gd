extends Control

@onready var brand_container: CenterContainer = $BrandContainer

var has_transitioned: bool = false
var tween: Tween

func _ready() -> void:
	# Start invisible
	brand_container.modulate.a = 0.0
	
	# Build the animation timeline
	tween = create_tween()
	tween.tween_property(brand_container, "modulate:a", 1.0, 0.8)
	tween.tween_interval(1.5)
	tween.tween_property(brand_container, "modulate:a", 0.0, 0.8)
	tween.tween_callback(_go_to_next_scene)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			_go_to_next_scene()

func _go_to_next_scene() -> void:
	if has_transitioned:
		return
	has_transitioned = true
	
	if tween:
		tween.kill()
		
	# For now, we can route to main_menu.tscn once we build it,
	# or test by loading res://scenes/Core/main.tscn directly
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
