class_name CardVisual
extends Node2D

const TEXTURE_DIFFUSE_PATH = "res://assets/%d-%d.png"
const TEXTURE_NORMAL_PATH = "res://assets/cardback_n_0.png"
const HIGHLIGHT_SHADER_PATH = "res://shaders/card_highlight_shader.gdshader"
const DEFAULT_SCALE = Vector2(0.5, 0.5)

var _card_data: Card
var _game_state: GameState

var card_data: Card:
	get: return _card_data
	set(value):
		_card_data = value
		update_visual()

var is_selected: bool = false

signal player_card_clicked(card_visual: CardVisual)
signal field_card_clicked(card_visual: CardVisual)

func _on_area_2d_mouse_exited():
	if _card_data.is_player_card and is_player_turn() and not is_selected:
		var shrink = unembiggen()
		await shrink.finished


func _on_area_2d_mouse_entered():
	if _card_data.is_player_card and is_player_turn():
		var grow = embiggen()
		await grow.finished


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _card_data.is_player_card and is_player_turn():
			player_card_clicked.emit(self)
		if _card_data.is_field_card and is_player_turn():
			field_card_clicked.emit(self)
		# Emit signal or handle card click logic here


func connect_events():
	$Area2D/CollisionShape2D.disabled = false
	$Area2D.mouse_entered.connect(_on_area_2d_mouse_entered)
	$Area2D.mouse_exited.connect(_on_area_2d_mouse_exited)
	$Area2D.input_event.connect(_on_area_2d_input_event)


func disconnect_events():
	$Area2D/CollisionShape2D.disabled = true
	$Area2D.mouse_entered.disconnect(_on_area_2d_mouse_entered)
	$Area2D.mouse_exited.disconnect(_on_area_2d_mouse_exited)
	$Area2D.input_event.disconnect(_on_area_2d_input_event)


func update_visual() -> void:
	var canvas_texture = CanvasTexture.new()
	var texture_diffuse_path = TEXTURE_DIFFUSE_PATH % [_card_data.month, _card_data.number]
	canvas_texture.diffuse_texture = load(texture_diffuse_path)
	canvas_texture.normal_texture = load(TEXTURE_NORMAL_PATH)
	$CardImage.texture = canvas_texture


func set_game_state(state: GameState) -> void:
	_game_state = state


func embiggen() -> Tween:
	var tween = create_tween()
	tween.tween_property(self, "scale", DEFAULT_SCALE * 1.2, 0.2)
	return tween


func unembiggen(quick: bool = false) -> Tween:
	if quick:
		self.scale = DEFAULT_SCALE
		return null

	var tween = create_tween()
	tween.tween_property(self, "scale", DEFAULT_SCALE, 0.2)
	return tween


func flip_card() -> void:
	$AnimationPlayer.play("card_flip")


func apply_highlight() -> void:
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload(HIGHLIGHT_SHADER_PATH)
	shader_material.set_shader_parameter("color", Color.YELLOW)
	shader_material.set_shader_parameter("inner_stroke_thickness", 12.0)
	shader_material.set_shader_parameter("frequency", 9.0)
	shader_material.set_shader_parameter("phase_speed", 8.0)
	$CardImage.material = shader_material


func remove_highlight() -> void:
	$CardImage.material = null


func is_player_turn() -> bool:
	return _game_state.current_phase == GameState.Phase.PLAY and _game_state.current_turn == GameState.Turn.PLAYER


func set_selected(s: bool) -> void:
	is_selected = s
	if is_selected:
		apply_highlight()
	else:
		remove_highlight()
		var shrink = unembiggen()
		await shrink.finished


func set_face_up() -> void:
	$CardBackImage.visible = false
	$CardImage.visible = true