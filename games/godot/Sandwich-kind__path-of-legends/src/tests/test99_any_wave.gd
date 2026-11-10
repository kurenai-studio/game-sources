extends SceneTree
# Временный выбор стартовой волны на экране Арены.
var main
var f := 0
var scr
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main.show_arena_setup()
		for n in main.world.get_children():
			if n is ArenaSetup: scr = n
	if f == 30:
		scr._step_any(10)
		scr._step_any(10)
		scr._step_any(10)
		scr._step_any(10)
		scr._step_any(1)
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/any_wave.png")
		print("any wave=", scr._any_wave, " label=", scr._any_lbl.text.replace("\n", " / "))
		scr._go_any()
	if f == 140:
		print("picker go text=", scr._picker.go_text if scr._picker else "none", " _wave=", scr._wave)
		return true
	return false
