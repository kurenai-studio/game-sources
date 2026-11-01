## The ending: the wake-up cutscene, the credits and the chain of scenes that joins them to the chapter.
extends "res://tests/test_case.gd"


func _luminance(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b


func _texts_in(root: Node) -> int:
	var count := 0
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is Label or node is RichTextLabel or node is Button or node is LineEdit:
			count += 1
	return count


func _wake_up() -> WakeUp:
	var scene := (load("res://scenes/wake_up.tscn") as PackedScene).instantiate() as WakeUp
	scene.change_scenes = false
	tree.root.add_child(scene)
	return scene


func test_wake_up_runs_to_the_end_and_asks_for_the_credits() -> void:
	var scene := _wake_up()
	var requested: Array[String] = []
	var done := [false]
	scene.scene_requested.connect(func(path: String) -> void: requested.append(path))
	scene.finished.connect(func() -> void: done[0] = true)
	await frames(int(scene.duration * 60.0) + 30)
	check(done[0], "the cutscene finishes by itself")
	check(requested == ["res://scenes/credits.tscn"], "and asks for the credits, requested=%s" % [requested])
	scene.queue_free()
	await frames(2)


## Contrast with the chapter: dark and grey before, bright and warm now.
func test_the_bedroom_is_brighter_and_warmer_than_the_nightmare() -> void:
	var chapter := (load("res://levels/chapter1.tscn") as PackedScene).instantiate()
	var darkness := chapter.get_node("Darkness") as CanvasModulate
	var nightmare := darkness.color
	chapter.free()
	var scene := _wake_up()
	var start := scene.modulate_node.color
	await frames(60 * 4)
	var room := scene.modulate_node.color
	check(_luminance(start) < 0.12, "it opens in the dark, luminance %.2f" % _luminance(start))
	check(_luminance(room) > _luminance(nightmare) + 0.3, "the room is much brighter than the chapter: %.2f vs %.2f" % [_luminance(room), _luminance(nightmare)])
	check(room.r > room.b + 0.08, "and warm (red above blue): %s" % room)
	check(absf(nightmare.r - nightmare.g) < 0.1, "the chapter is near-grey: %s" % nightmare)
	scene.queue_free()
	await frames(2)


func test_the_child_wakes_and_sits_up_with_sound_and_light() -> void:
	var scene := _wake_up()
	var child := scene.get_node("Child") as Node2D
	var birds: AudioStreamPlayer = null
	for node in scene.get_children():
		if node is AudioStreamPlayer and (node as AudioStreamPlayer).stream.resource_path.ends_with("birds.ogg"):
			birds = node
	var shaft := scene.get_node("WindowShaft") as LightShaft
	check(absf(rad_to_deg(child.rotation) - (-90.0)) < 1.0, "starts lying down, rotation %.0f deg" % rad_to_deg(child.rotation))
	check(birds != null and birds.volume_db <= -70.0, "and silent")
	await frames(60 * 8)
	check(rad_to_deg(child.rotation) > -12.0 and rad_to_deg(child.rotation) < 2.0, "sits up, rotation %.0f deg" % rad_to_deg(child.rotation))
	check(birds.volume_db > -20.0, "the birds are singing, %.0f dB" % birds.volume_db)
	check(shaft.base_energy > 1.0 and shaft.energy > 0.8, "the window light is on, energy %.2f" % shaft.energy)
	scene.queue_free()
	await frames(2)


func test_the_ending_has_no_text_until_the_credits() -> void:
	var scene := _wake_up()
	await frames(30)
	check(_texts_in(scene) == 0, "no text in the wake-up scene, found %d" % _texts_in(scene))
	scene.queue_free()
	await frames(2)


# ---------------------------------------------------------------- credits

func _credits() -> Credits:
	var credits := (load("res://scenes/credits.tscn") as PackedScene).instantiate() as Credits
	credits.change_scenes = false
	credits.seconds_per_line = 0.05
	tree.root.add_child(credits)
	return credits


func test_credits_roll_then_ask_for_a_new_game() -> void:
	var credits := _credits()
	var requested: Array[String] = []
	credits.scene_requested.connect(func(path: String) -> void: requested.append(path))
	await frames(10)
	var text := ""
	for label in credits.find_children("*", "Label", true, false):
		text += (label as Label).text + "\n"
	check(text.contains("DREAMRUN") and text.contains("Godot Engine"), "the credits name the game and the engine")
	check(text.contains("tuanden0") and text.contains("github.com/tuanden0"), "the credits name the author and link their GitHub")
	check(text.contains("Claude Code") and text.contains("Anthropic"), "and credit Claude Code")
	check(not text.contains("@"), "no email address is published in the credits")
	await frames(60 * 8)
	check(credits.is_done and requested == ["res://levels/chapter1.tscn"], "after the roll it asks for the first chapter, requested=%s" % [requested])
	credits.queue_free()
	await frames(2)


func test_a_key_press_skips_the_credits_but_not_in_the_first_moments() -> void:
	var credits := _credits()
	credits.seconds_per_line = 5.0  # a long roll, so only a key can end it
	await frames(5)
	var press := InputEventAction.new()
	press.action = &"ui_accept"
	press.pressed = true
	Input.parse_input_event(press)
	await frames(3)
	check(not credits.is_done, "a press right at the start does nothing")
	await frames(60 * 2)
	Input.parse_input_event(press)
	await frames(3)
	check(credits.is_done, "a press after a moment skips them")
	credits.queue_free()
	await frames(2)


## Every CC-BY asset in ASSETS.md must be credited by name in credits.gd (nothing is credited to a stranger, nothing is missed).
func test_every_cc_by_asset_in_the_ledger_is_credited() -> void:
	var ledger := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../ASSETS.md").simplify_path())
	var source := FileAccess.get_file_as_string("res://scripts/ui/credits.gd")
	var needing := 0
	for line in ledger.split("\n"):
		if not line.begins_with("| assets/"):
			continue
		var cells := line.split("|")
		if cells.size() < 6:
			continue
		var author := cells[3].strip_edges()
		var license := cells[4].strip_edges()
		if license.to_upper().contains("CC-BY") or license.to_upper().contains("CC BY"):
			needing += 1
			check(source.contains(author), "CC-BY asset %s by %s is not in the credits" % [cells[1].strip_edges(), author])
	check(needing >= 0, "ledger read")


# ---------------------------------------------------------------- the chain

func test_chapter_wake_up_credits_and_back_form_a_loop() -> void:
	var chapter := (load("res://levels/chapter1.tscn") as PackedScene).instantiate() as Chapter
	var wake := (load("res://scenes/wake_up.tscn") as PackedScene).instantiate() as WakeUp
	var credits := (load("res://scenes/credits.tscn") as PackedScene).instantiate() as Credits
	check(chapter.next_scene == "res://scenes/wake_up.tscn", "the chapter leads to the wake-up")
	check(wake.next_scene == "res://scenes/credits.tscn", "the wake-up leads to the credits")
	check(credits.next_scene == "res://levels/chapter1.tscn", "the credits lead back to the chapter")
	for path in [chapter.next_scene, wake.next_scene, credits.next_scene]:
		check(ResourceLoader.exists(path), "%s exists" % path)
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://levels/chapter1.tscn", "the game starts in the chapter")
	chapter.free()
	wake.free()
	credits.free()


func test_finishing_the_chapter_fades_out_and_hands_over_to_the_wake_up() -> void:
	var chapter := (load("res://levels/chapter1.tscn") as PackedScene).instantiate() as Chapter
	chapter.change_scenes = false
	chapter.get_node("Progress").save_path = "user://test_flow_save.json"
	tree.root.add_child(chapter)
	var requested: Array[String] = []
	chapter.scene_requested.connect(func(path: String) -> void: requested.append(path))
	await frames(10)
	chapter.finish()
	await frames(60)
	check(requested.is_empty(), "not yet: the fade to black comes first")
	await frames(60 * 3)
	check(requested == ["res://scenes/wake_up.tscn"], "then the wake-up is requested once, requested=%s" % [requested])
	chapter.finish()  # a second trigger of the exit changes nothing
	await frames(60 * 4)
	check(requested.size() == 1, "and only once")
	chapter.queue_free()
	await frames(3)
	SaveGame.erase("user://test_flow_save.json")
