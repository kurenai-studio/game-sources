extends Control
## Startmenü: Titel und eine Kachel pro Spielfeld mit Vorschau und Beschreibung. Ein Klick startet das Spiel.
## Quer stehen die Kacheln nebeneinander, im Hochformat zwei mal zwei. Passt das nicht auf den Bildschirm,
## wird alles verkleinert: das Menü scrollt nie.

const MAIN_SCENE := "res://scenes/main.tscn"
const CARD := 290.0
const MARGIN := 16.0

var _cards: Array[PanelContainer] = []
var _column := VBoxContainer.new()
var _grid := GridContainer.new()


func _ready() -> void:
	Engine.time_scale = 1.0
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Hud.make_theme()
	var background := ColorRect.new()
	background.color = Color("#1d2a24")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# Kein Container darüber: Container setzen den Maßstab ihrer Kinder zurück, _fit platziert selbst.
	var column := _column
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var title := Label.new()
	title.text = "Hold the Keep"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Hud.GOLD)
	title.add_theme_color_override("font_outline_color", Hud.INK)
	title.add_theme_constant_override("outline_size", 12)
	column.add_child(title)
	var tagline := Label.new()
	tagline.text = "Die Toten ziehen vom Friedhof zur Burg. Baue Türme, lege Labyrinthe, halte die Burg."
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.custom_minimum_size.x = 420
	column.add_child(tagline)
	var grid := _grid
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	column.add_child(grid)
	for id: StringName in MapData.ORDER:
		_cards.append(_card(id))
		grid.add_child(_cards[-1])
	UiScale.changed.connect(_layout)
	_column.minimum_size_changed.connect(_fit)
	get_viewport().size_changed.connect(_fit)
	_layout()


func _layout() -> void:
	_grid.columns = 2 if UiScale.narrow else _cards.size()
	_fit.call_deferred()


## Verkleinern, bis alles auf den Bildschirm passt (Größer wird es nie).
func _fit() -> void:
	var need := _column.get_combined_minimum_size()
	var room := get_viewport_rect().size - Vector2.ONE * MARGIN * 2.0
	if need.x <= 0.0 or need.y <= 0.0:
		return
	var fit := minf(1.0, minf(room.x / need.x, room.y / need.y))
	_column.size = need
	_column.scale = Vector2(fit, fit)
	_column.position = (get_viewport_rect().size - need * fit) / 2.0


func _card(id: StringName) -> PanelContainer:
	var def: Dictionary = MapData.MAPS[id]
	var map := MapData.load_map(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = CARD
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var name := Label.new()
	name.text = def["name"]
	name.add_theme_font_size_override("font_size", 30)
	name.add_theme_color_override("font_color", Hud.GOLD)
	box.add_child(name)
	var preview := MapPreview.new(map)
	preview.set_width(CARD - 20)  # abzüglich Innenabstand der Kachel
	box.add_child(preview)
	var info := Label.new()
	info.text = def["info"]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.custom_minimum_size.x = CARD - 20
	box.add_child(info)
	var facts := Label.new()
	var checkpoints := map.waypoints.size() - 1
	facts.text = "%d x %d Felder · %s" % [map.size.x, map.size.y,
			"%d Kontrollpunkte" % checkpoints if checkpoints > 0 else "ohne Kontrollpunkte"]
	facts.add_theme_font_size_override("font_size", 16)
	facts.add_theme_color_override("font_color", Color("#c9b994"))
	box.add_child(facts)
	var play := Button.new()
	play.text = "Spielen"
	play.custom_minimum_size.y = 48
	play.pressed.connect(func() -> void:
		Sfx.play(&"click")
		Main.map_id = id
		get_tree().change_scene_to_file(MAIN_SCENE))
	box.add_child(play)
	return panel
