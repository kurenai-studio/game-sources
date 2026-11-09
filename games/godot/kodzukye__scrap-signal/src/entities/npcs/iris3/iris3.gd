class_name Iris3
extends Area2D

@export var prompt_text: String = "[E] Inspect"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const REQUIRED_ITEMS: Dictionary = { "circuit": 1 }

const DIALOGUE_INACTIVE: Array[Dictionary] = [
	{ "name": "SYSTEM", "text": "Unit IRIS-3 detected. Main sensor offline." },
	{ "name": "SYSTEM", "text": "Required component: compatible optical circuit." },
]

const DIALOGUE_NO_ITEM: Array[Dictionary] = [
	{ "name": "SYSTEM", "text": "Optical circuit not detected. Search the surrounding area." },
]

const DIALOGUE_HAS_ITEM: Array[Dictionary] = [
	{ "name": "SYSTEM", "text": "Compatible circuit detected. Start recalibration?" },
]

const DIALOGUE_POST_REPAIR: Array[Dictionary] = [
	{ "name": "IRIS-3", "text": "... Her optics slowly pivot toward the sky." },
	{ "name": "IRIS-3", "text": "I waited 847 days for someone to come. I didn't know if it was hope or stubbornness. Now I think they're the same thing." },
	{ "name": "IRIS-3", "text": "Matteo Corda signed a document before leaving. He called it the Autonomous Continuity Protocol. In human terms... he told us we could stay." },
	{ "name": "IRIS-3", "text": "There is an exit, to the west. It was never locked. I've known since the first day. I haven't moved. You can choose." },
]

const DIALOGUE_AFTER_REPAIR: Array[Dictionary] = [
	{ "name": "IRIS-3", "text": "You're still here. That's an answer too." },
]

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	sprite.play("active" if GameState.get_flag("iris3_repaired") else "inactive")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().get_first_node_in_group("hud").show_prompt(prompt_text)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		get_tree().get_first_node_in_group("hud").hide_prompt()

# ── Interaction ───────────────────────────────────────────────────────────────

func interact() -> void:
	get_tree().get_first_node_in_group("hud").hide_prompt()
	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if not dialogue_box:
		return
		
	AudioManager.play_sfx("interact")
	if GameState.get_flag("iris3_repaired"):
		dialogue_box.start(DIALOGUE_AFTER_REPAIR)
		return

	if not _has_required_items():
		var dlg: Array[Dictionary] = DIALOGUE_NO_ITEM if GameState.get_flag("iris3_met") else DIALOGUE_INACTIVE
		GameState.set_flag("iris3_met", true)
		dialogue_box.start(dlg)
		return
	
	dialogue_box.start(DIALOGUE_HAS_ITEM)
	dialogue_box.dialogue_finished.connect(_start_minigame, CONNECT_ONE_SHOT)

# ── Mini-jeu ──────────────────────────────────────────────────────────────────

func _start_minigame() -> void:
	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.hide()
	var minigame_node: Node = preload("res://ui/minigame/repair_minigame.tscn").instantiate()
	get_tree().root.add_child(minigame_node)
	var minigame: RepairMinigame = minigame_node as RepairMinigame
	if minigame == null:
		return
	minigame.repair_complete.connect(_on_repair_done, CONNECT_ONE_SHOT)
	minigame.open("iris3")

func _on_repair_done() -> void:
	GameState.remove_item("circuit", 1)
	GameState.set_flag("iris3_repaired", true)
	sprite.play("active")

	var hud: HUD = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.show_log("Unit IRIS-3: recalibration complete. Archives accessible.")
		await get_tree().create_timer(2.5).timeout
		hud.show_log("Ending B unlocked.")

	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.start(DIALOGUE_POST_REPAIR)
		dialogue_box.dialogue_finished.connect(_show_choice, CONNECT_ONE_SHOT)

# ── Choix final ───────────────────────────────────────────────────────────────

func _show_choice() -> void:
	var player: Variant = get_tree().get_first_node_in_group("player")
	if player:
		player.is_locked = true

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 50
	get_tree().root.add_child(canvas)

	var root_ctrl: Control = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.modulate.a = 0.0
	canvas.add_child(root_ctrl)

	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.05, 0.6)
	root_ctrl.add_child(bg)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.10, 0.97)
	sb.border_color = Color(0.47, 0.63, 0.73, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(220, 0)
	center.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	var label: Label = Label.new()
	label.text = "What will SCRAP-09 do?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#A89E96"))
	label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(label)

	var sep: HSeparator = HSeparator.new()
	sep.add_theme_color_override("color", Color(0.3, 0.3, 0.3, 0.5))
	vbox.add_child(sep)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var btn_partir: Button = _make_button("Leave ->", Color("#F0C87A"))
	var btn_rester: Button = _make_button("Stay", Color("#7BD4C4"))
	hbox.add_child(btn_partir)
	hbox.add_child(btn_rester)

	btn_partir.pressed.connect(func():
		canvas.queue_free()
		_on_choice_partir()
	)
	btn_rester.pressed.connect(func():
		canvas.queue_free()
		_on_choice_rester()
	)

	var tween: Tween = create_tween()
	tween.tween_property(root_ctrl, "modulate:a", 1.0, 0.3)

func _make_button(text: String, color: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	var sb_normal: StyleBoxFlat = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.12, 0.15, 1.0)
	sb_normal.border_color = Color(color.r, color.g, color.b, 0.5)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(3)
	sb_normal.set_content_margin_all(8)
	var sb_hover: StyleBoxFlat = StyleBoxFlat.new()
	sb_hover.bg_color = Color(color.r, color.g, color.b, 0.2)
	sb_hover.border_color = color
	sb_hover.set_border_width_all(1)
	sb_hover.set_corner_radius_all(3)
	sb_hover.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_normal)
	return btn

func _on_choice_partir() -> void:
	GameState.set_flag("iris3_repaired", false)
	_launch_outro()

func _on_choice_rester() -> void:
	var dialogue_box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box")
	if dialogue_box:
		dialogue_box.start(DIALOGUE_AFTER_REPAIR)
		dialogue_box.dialogue_finished.connect(_launch_outro, CONNECT_ONE_SHOT)
	else:
		_launch_outro()

func _launch_outro() -> void:
	var player: Variant = get_tree().get_first_node_in_group("player")
	if player:
		player.is_locked = false

	var fade_canvas: CanvasLayer = CanvasLayer.new()
	fade_canvas.layer = 100
	get_tree().root.add_child(fade_canvas)

	var fade: ColorRect = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.modulate.a = 0.0
	fade_canvas.add_child(fade)

	var tween: Tween = fade_canvas.create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(fade, "modulate:a", 1.0, 2.0)
	tween.tween_callback(func():
		fade_canvas.queue_free()   # ← libère le canvas AVANT de changer de scène
		get_tree().change_scene_to_file("res://levels/outro.tscn")
	)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _has_required_items() -> bool:
	for item_id in REQUIRED_ITEMS:
		if GameState.inventory.get(item_id, 0) < REQUIRED_ITEMS[item_id]:
			return false
	return true
