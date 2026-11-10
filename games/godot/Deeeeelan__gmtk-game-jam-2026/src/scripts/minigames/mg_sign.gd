extends Control

@onready var game_manager: Node = GameManager
@onready var canvas: GridContainer = $Canvas
@onready var doc_list: VBoxContainer = $Left/Page/DocList
@onready var texture_rect: TextureRect = $TextureRect

const DOC_INFO: Dictionary = {
	1: [{
			"loc": Vector2(450, 390), "size": Vector2(45, 13)}],
	2: [{
			"loc": Vector2(450, 248), "size": Vector2(45, 13)},
		{
			"loc": Vector2(450, 390), "size": Vector2(45, 13)}],
	3: [{
			"loc": Vector2(450, 249), "size": Vector2(45, 11)},
		{
			"loc": Vector2(450, 375), "size": Vector2(45, 11)},
		{
			"loc": Vector2(578, 375), "size": Vector2(45, 11)}]}
const DOCS = {
	1: preload("res://assets/images/minigames/mg_draw_1.png"),
	2: preload("res://assets/images/minigames/mg_draw_2.png"),
	3: preload("res://assets/images/minigames/mg_draw_3.png")}
const DOC_BUTTON = preload("res://assets/minigames/doc_button.tscn")

var filled: Dictionary = {
	1: true,
	2: true,
	3: true}
var clearedDocs: Dictionary = {
	1: false,
	2: false,
	3: false}
var editedDocs: Array = []

var can_draw:bool = true
var is_drawing: bool = false
var canvas_size = Vector2(2, 2)
var canvases = []
var current_doc
var doc_count: int = 3

func _ready() -> void:
	can_draw = true
	play()
	createButtons()
	switchDoc(1)

func play() -> void:
	pass

func switchDoc(doc_num) -> void:
	current_doc = doc_num
	for node in canvases:
		node.queue_free()
	editedDocs.clear()
	canvases.clear()
	texture_rect.texture = DOCS[doc_num]
	for i in range(1, 1 + doc_num):
		filled[i] = false
	for area in DOC_INFO[doc_num]:
		createDrawableArea(area["loc"], area["size"])

func createButtons():
	for i in range(doc_count):
		var butt = DOC_BUTTON.instantiate()
		butt.modulate = Color()
		butt.text = "Document " + String.num_int64(i + 1)
		butt.doc_number = i + 1
		doc_list.add_child(butt)

func createDrawableArea(location: Vector2i, dimentions: Vector2i) -> void:
	var canv = canvas.duplicate()
	add_child(canv)
	canvases.append(canv)
	canv.global_position = location
	canv.columns = dimentions.x
	for i in range(dimentions.x * dimentions.y):
		var cell = TextureButton.new()
		cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cell.custom_minimum_size = canvas_size
		cell.stretch_mode = TextureButton.STRETCH_SCALE
		cell.ignore_texture_size = true
		cell.texture_normal = load("res://assets/images/misc/white1x1pixel.png")
		canv.add_child(cell)

func _input(event: InputEvent) -> void:
	if can_draw:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				is_drawing = true
			var cell_at_mouse = getCellAtMouse(event.position)
			if cell_at_mouse:
				cell_at_mouse.modulate = Color(0, 0, 0)
				editedDocs.append(getCanvasAtMouse(event.position))
			if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
				is_drawing = false
				markSigned(editedDocs)
				editedDocs.clear()
		if event is InputEventMouseMotion and is_drawing:
			var cell_at_mouse = getCellAtMouse(event.position)
			if cell_at_mouse:
				cell_at_mouse.modulate = Color(0, 0, 0)
				editedDocs.append(getCanvasAtMouse(event.position))

func getCellAtMouse(mouse_pos: Vector2) -> TextureButton:
	if not canvases:
		return null
	for canv in canvases:
		var canvas_buttons = canv.get_children()
		for i in canvas_buttons:
			var button_pos = i.global_position
			var button_size = i.custom_minimum_size
			if button_pos.x <= mouse_pos.x and button_pos.x + button_size.x >= mouse_pos.x and button_pos.y <= mouse_pos.y and button_pos.y + button_size.y >= mouse_pos.y:
				return i
	return null

func markSigned(canvs: Array) -> void:
	for canv in canvs:
		filled[canvases.find(canv) + 1] = true
		if filled[1] and filled[2] and filled[3] == true:
			clearedDocs[current_doc] = true
			getButtonWithDoc(current_doc).modulate = Color(0.0, 0.4, 0.0, 1.0)
	if clearedDocs[1] and clearedDocs[2] and clearedDocs[3] == true:
		can_draw = false
		game_manager.gameWin()

func getButtonWithDoc(doc_num) -> Button:
	for i in doc_list.get_children():
		if i.doc_number == doc_num:
			return i
	return null

func getCanvasAtMouse(mouse_pos: Vector2) -> GridContainer:
	if not canvases:
		return null
	for canv in canvases:
		var canvas_buttons = canv.get_children()
		for i in canvas_buttons:
			var button_pos = i.global_position
			var button_size = i.custom_minimum_size
			if button_pos.x <= mouse_pos.x and button_pos.x + button_size.x >= mouse_pos.x and button_pos.y <= mouse_pos.y and button_pos.y + button_size.y >= mouse_pos.y:
				return canv
	return null
