extends Control
## Base for the composed Phase 1 screens. Each direction's
## tools/directions/<id>/screens/screen.gd extends this, and each of its four
## .tscn files sets `screen`. The board and targeting screens are composed
## here the same way for every direction, only through the artists'
## interfaces; game over and settings are composed per direction.
##
## Every artist component is added to the scene tree before its setup() call,
## because some of them size their parts on resize, which only fires in the tree.
##
## The layout fills whatever viewport it gets: the HUD sits at the top of the
## safe area, the booster bar at the bottom, and the board takes the largest
## size that fits between them. That is also how the small screen check works.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")

## Which screen this scene shows: board, targeting, gameover or settings.
@export var screen: String = "board"

var tokens: DirectionTokens = null
var canvas: Vector2 = Vector2.ZERO
var backdrop: Control = null
var hud: Control = null
var bar: Control = null
var board: Control = null
## Controls that hold text. Their rects are kept clear of backdrop decoration.
var text_holders: Array[Control] = []


## The direction this screen belongs to. Each direction's script overrides it.
func direction_id() -> String:
	return ""


func _ready() -> void:
	canvas = get_viewport_rect().size
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tokens = Directions.load_tokens(direction_id())
	if tokens == null:
		return
	theme = ui_script("theme_factory").call("build", tokens) as Theme
	backdrop = make_ui("backdrop")
	backdrop.position = Vector2.ZERO
	backdrop.size = canvas
	match screen:
		"board":
			compose_play(true, false)
		"targeting":
			compose_play(false, true)
		"gameover":
			compose_gameover()
		"settings":
			compose_settings()
		_:
			push_error("unknown screen '%s'" % screen)
	# Containers lay out on the next frame; then the text rects are final.
	await get_tree().process_frame
	await get_tree().process_frame
	if backdrop.has_method("set_clear_rects"):
		var rects: Array[Rect2] = []
		for holder: Control in text_holders:
			rects.append(holder.get_global_rect())
		backdrop.call("set_clear_rects", rects)


## Game over, composed by each direction.
func compose_gameover() -> void:
	push_error("%s has no game over composition" % direction_id())


## Settings, composed by each direction.
func compose_settings() -> void:
	push_error("%s has no settings composition" % direction_id())


## The play screen: HUD, board and booster bar. with_chain shows the mock
## chain being dragged with its preview; targeting shows Hammer targeting.
func compose_play(with_chain: bool, targeting: bool) -> void:
	place_hud()
	var active: String = MockState.TARGETING_BOOSTER if targeting else ""
	place_bar(MockState.BOOSTER_COSTS, MockState.board_usable(), active)
	if targeting:
		bar.call("set_hint", MockState.TARGET_HINT)
	place_board(hud.position.y + hud.size.y, bar.position.y, MockState.board_values())
	if targeting:
		board.call("set_targeting", true)
		board.call("set_target", MockState.TARGET_CELL)
		hud.call("set_context", "%s: %s" % [MockState.booster_name(MockState.TARGETING_BOOSTER), MockState.TARGET_HINT], true)
	elif with_chain:
		var chain: Array[Vector2i] = MockState.chain_cells()
		board.call("set_chain", chain, MockState.drag_point())
		board.call("set_preview", MockState.CHAIN_PREVIEW)
		hud.call("set_context", "%s %d" % [MockState.CHAIN_LABEL, chain.size()], false)
		var slot: Control = hud.call("preview_slot") as Control
		if slot != null:
			var tile: Control = make_tile(slot, tokens, MockState.CHAIN_PREVIEW)
			tile.position = Vector2.ZERO
			tile.size = slot.size


## The HUD at the top of the safe area.
func place_hud() -> void:
	hud = make_ui("hud")
	hud.position = Vector2(0.0, float(MockState.safe_top))
	hud.size = Vector2(canvas.x, float(hud.call("preferred_height")))
	hud.call("set_scores", MockState.SCORE, MockState.BEST_SCORE)
	text_holders.append(hud)


## The booster bar on the bottom of the safe area.
func place_bar(costs: PackedInt32Array, usable: Array[bool], active_id: String) -> void:
	bar = make_ui("booster_bar")
	bar.call("show_boosters", MockState.BOOSTER_IDS, costs, usable, active_id)
	var height: float = float(bar.call("preferred_height"))
	bar.position = Vector2(0.0, canvas.y - float(MockState.safe_bottom) - height)
	bar.size = Vector2(canvas.x, height)
	text_holders.append(bar)


## Top of the bar's always visible part. With use_hint_space, the board may
## use the space the bar keeps for its hint (when no hint shows), if the bar
## reports where its content starts.
func bar_top(use_hint_space: bool) -> float:
	if use_hint_space and bar.has_method("content_top"):
		return bar.position.y + float(bar.call("content_top"))
	return bar.position.y


## The board, as large as fits between top and bottom (at most the full
## width less the board margins), centered, drawn under the HUD and bar.
func place_board(top: float, bottom: float, values: Array[PackedInt32Array]) -> void:
	board = board_script("board_view").new() as Control
	add_child(board)
	move_child(board, backdrop.get_index() + 1)
	board.call("setup", tokens)
	var gap: float = tokens.num("space_s")
	var available: float = bottom - top - gap * 2.0
	var width: float = canvas.x - tokens.num("board_margin") * 2.0
	var height: float = float(board.call("preferred_height", width))
	if height > available:
		width *= available / height
		height = available
	board.position = Vector2((canvas.x - width) * 0.5, top + gap + (available - height) * 0.5)
	board.size = Vector2(width, height)
	board.call("set_board", values)


## Tile side on the composed board, px.
func board_tile_side() -> float:
	if board == null:
		return 0.0
	return (board.call("cell_rect", Vector2i(0, 0)) as Rect2).size.x


## A full screen scrim in the direction's scrim color, over everything so far.
func add_scrim() -> void:
	var scrim: ColorRect = ColorRect.new()
	scrim.color = tokens.color("scrim")
	scrim.position = Vector2.ZERO
	scrim.size = canvas
	add_child(scrim)


# Builders

## The direction's ui script with this file name.
func ui_script(file_name: String) -> GDScript:
	return load("%s/%s/ui/%s.gd" % [Directions.ROOT, direction_id(), file_name]) as GDScript


## The direction's board script with this file name.
func board_script(file_name: String) -> GDScript:
	return load("%s/%s/board/%s.gd" % [Directions.ROOT, direction_id(), file_name]) as GDScript


## A new control from the direction's ui script, added and set up.
func make_ui(file_name: String) -> Control:
	var control: Control = ui_script(file_name).new() as Control
	add_child(control)
	control.call("setup", tokens)
	return control


## A tile of any direction (by its tokens), showing value, added to parent.
func make_tile(parent: Node, tile_tokens: DirectionTokens, value: int) -> Control:
	var script: GDScript = load("%s/%s/board/tile_view.gd" % [Directions.ROOT, tile_tokens.id]) as GDScript
	var tile: Control = script.new() as Control
	parent.add_child(tile)
	tile.call("setup", tile_tokens)
	tile.call("set_value", value)
	return tile


## A label in a theme variation, with the role's case rule applied.
func label(variation: String, role: String, text: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var result: Label = Label.new()
	result.theme_type_variation = variation
	result.text = tokens.cased(role, text)
	result.horizontal_alignment = align
	return result


## A themed button. The theme cannot set text alignment or case, so they are set here.
func button(variation: String, text: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Button:
	var result: Button = Button.new()
	result.theme_type_variation = variation
	result.text = tokens.cased("body", text)
	result.alignment = align
	result.focus_mode = Control.FOCUS_NONE
	return result


## The direction's icon button, added to parent.
func icon_button(parent: Node, icon_name: String, face_side: float, icon_side: float) -> Control:
	var result: Control = ui_script("icon_button").new() as Control
	parent.add_child(result)
	result.call("setup", tokens, icon_name, face_side, icon_side)
	return result


## The direction's sound toggle, added to parent.
func toggle(parent: Node, on: bool) -> Control:
	var result: Control = ui_script("toggle_switch").new() as Control
	parent.add_child(result)
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.call("setup", tokens)
	result.call("set_on", on, false)
	return result


## One skin choice, added to parent: a small preview in that skin's own
## background with its first three tile values, and a chip with its name.
## Selected when it is this direction.
func skin_choice(parent: Node, skin_index: int, tile_side: float, radius: float) -> VBoxContainer:
	var skin_tokens: DirectionTokens = Directions.load_tokens(MockState.SKIN_IDS[skin_index])
	var choice: VBoxContainer = VBoxContainer.new()
	parent.add_child(choice)
	choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.add_theme_constant_override("separation", int(tokens.num("space_xs")))
	var swatch: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = skin_tokens.color("bg")
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = true
	# A swatch in the same color as its surroundings gets a hairline edge.
	if skin_tokens.color("bg") == tokens.color("bg"):
		for edge_token: String in ["rule", "ring", "divider"]:
			if tokens.palette.has(edge_token):
				style.border_color = tokens.color(edge_token)
				style.set_border_width_all(2)
				break
	var pad: float = tile_side * 0.22
	style.content_margin_left = pad
	style.content_margin_right = pad
	style.content_margin_top = pad
	style.content_margin_bottom = pad
	swatch.add_theme_stylebox_override("panel", style)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(tile_side * 0.12))
	swatch.add_child(row)
	choice.add_child(swatch)
	for value: int in MockState.SKIN_PREVIEW_VALUES:
		var tile: Control = make_tile(row, skin_tokens, value)
		tile.custom_minimum_size = Vector2(tile_side, tile_side)
	var chip: Button = button("ChipButton", MockState.SKIN_NAMES[skin_index])
	chip.toggle_mode = true
	chip.button_pressed = MockState.SKIN_IDS[skin_index] == direction_id()
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice.add_child(chip)
	return choice


## A row added to parent with text on the left. Add the control on the right
## to the returned row.
func setting_row(parent: Node, text: String, min_height: float) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)
	row.custom_minimum_size = Vector2(0.0, min_height)
	var name_label: Label = label("BodyLabel", "body", text)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_vertical = Control.SIZE_FILL
	row.add_child(name_label)
	return row


## A box container with the given separation.
func vbox(separation: float) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", int(separation))
	return box


func hbox(separation: float) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", int(separation))
	return box


## Places a container (adding it if it has no parent yet) at a position and
## width, and returns its height.
func place_container(container: Control, at: Vector2, width: float) -> float:
	if container.get_parent() == null:
		add_child(container)
	container.position = at
	var height: float = container.get_combined_minimum_size().y
	container.size = Vector2(width, height)
	return height
