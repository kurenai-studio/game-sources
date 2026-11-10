extends SceneTree
# Снимки: настройки, кнопки на экране (стик / крестовина / полоса), значки перезарядки
# без экранных кнопок, рюкзак и сундук с подсказками геймпада, Арена и Дуэль.
var main
var f := 0
var out := "/tmp/claude-0/st/"
var sm: StoryMode

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func snap(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(out + n + ".png")

func story() -> void:
	var d := StorySave.new_game("Тест", StoryLook.default_look())
	d["learned"] = ["fireball", "dash", "heal", "rage"]
	d["slots"] = ["fireball", "dash", "heal"]
	d["ult"] = "rage"
	main.start_story(2, d)

func find(cls) -> Node:
	for n in main.world.get_children():
		if is_instance_of(n, cls): return n
	return null

func _process(_d: float) -> bool:
	f += 1
	match f:
		3:
			main._on_mode_chosen("settings")
		8:
			snap("u_settings")
			Config.SHOW_TOUCH_ON_PC = true
			StorySettings.set_value("touch_move", "stick")
			StorySettings.set_value("touch_panel", false)
			story()
		14:
			sm = find(StoryMode)
			sm.hero._cd[0] = 2.4
			sm.hero._cd[1] = 0.6
		20:
			snap("u_story_stick")
			StorySettings.set_value("touch_move", "dpad")
			StorySettings.set_value("touch_panel", true)
			story()
		28:
			snap("u_story_dpad_panel")
			Config.SHOW_TOUCH_ON_PC = false
			StorySettings.set_value("touch_panel", false)
			StorySettings.set_value("touch_move", "stick")
			PadGlyph.force = true
			story()
		34:
			sm = find(StoryMode)
			sm.hero._cd[0] = 2.4
			sm.hero._cd[2] = 5.2
		40:
			snap("u_story_pad")
			for it in StoryMode.CHEST_ITEMS:
				sm.add_item(String(it[0]), int(it[1]))
			sm.open_inventory()
		46:
			snap("u_inv_pad")
		48:
			find(StoryInventory).queue_free()
		50:
			sm._interact(sm.props[1])
		56:
			snap("u_chest")
			find(StoryChest).queue_free()
		60:
			PadGlyph.force = false
			Config.SHOW_TOUCH_ON_PC = true
			main.sel = [0, 1]
			main.start_arena(false, 1)
		90:
			snap("u_arena_stick")
			main._on_duel_ready("test_field", 3, 5, [0, 1], {})
		110:
			snap("u_duel_stick")
			StorySave.delete_slot(2)
			StorySettings.set_value("touch_move", "stick")
			return true
	return false
