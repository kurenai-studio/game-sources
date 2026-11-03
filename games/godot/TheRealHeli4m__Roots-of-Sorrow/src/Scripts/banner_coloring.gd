extends Control

const gridSize = 48
var activeColor = Color(1, 0, 0)
var isPainting = false

signal paintingFinished

@onready var grid = $GridContainer
@onready var modelSprite = $ModelBannerSprite

@onready var totalCellsPainted = 0
@onready var usingPaint = totalCellsPainted < 5760

@onready var root = $".."

@onready var redBanner = load("res://Assets/Sewing/red_banner.png")
@onready var blueBanner = load("res://Assets/Sewing/blue_banner.png")
@onready var greenBanner = load("res://Assets/Sewing/green_banner.png")

@onready var redBlueprint = load("res://Assets/Sewing/red_banner_blueprint.png")
@onready var blueBlueprint = load("res://Assets/Sewing/blue_banner_blueprint.png")
@onready var greenBlueprint = load("res://Assets/Sewing/green_banner_blueprint.png")

@onready var bannerToBlueprintDict: Dictionary = {redBanner: redBlueprint, blueBanner: blueBlueprint, greenBanner: greenBlueprint}
@onready var currentBanner;
@onready var currentBlueprint;

@onready var lastTool = root.tools.NONE
@onready var lastPos = Vector2(0, 0)
@onready var isDragging = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateGrid()
	currentBanner = modelSprite.bannerTexture
	currentBlueprint = bannerToBlueprintDict.get(currentBanner)
	
func _process(delta: float) -> void:
	if totalCellsPainted == 5760:
		paintingFinished.emit()
		totalCellsPainted += 1
	
	if isDragging:
		moveTowardsPosition(get_viewport().get_mouse_position() + Vector2(-192, 20))
		
func generateGrid() -> void:
	grid.columns = gridSize
	
	for i in range(gridSize * 120):
		var cell = ColorRect.new()
		
		cell.color = Color(0.5, 0.5, 0.5)
		cell.custom_minimum_size = Vector2(8, 8)
		cell.set_meta("is_painted", false)
		cell.set_meta("is_correct_color", false)
		
		grid.add_child(cell)
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			isPainting = true
		if event.button_index == MOUSE_BUTTON_LEFT and !event.is_pressed():
			isPainting = false
			
	if isPainting:
		var cells = grid.get_children()
		if root.currentTool == root.tools.PAINTBRUSH:
			var cellsUnderArea = getCellsUnderArea(32)
		
			for i in range(cellsUnderArea.size()):
				var currentcell = cells[cellsUnderArea[i]]
				currentcell.color = activeColor
				modelSprite.checkCellForCorrectColor(currentcell)
				
		if root.currentTool == root.tools.NEEDLE:
			var cellsUnderArea = getCellsUnderArea(8)
			for i in range(cellsUnderArea.size()):
				var currentcell = cells[cellsUnderArea[i]]
				currentcell.modulate.a = 1
				currentcell.color = activeColor
		if root.currentTool == root.tools.SCISSORS:
			var cellIndex = getCellUnderMouse()
			var cellsList = grid.get_children()
			var cellUnderMouse = cells[cellIndex]
			if cellUnderMouse:
				cellUnderMouse.modulate.a = 0
			
func getCellUnderMouse() -> int:
	var cells = grid.get_children()
	for i in range(cells.size()):
		var cell = cells[i]
		var cellSize = cell.size
		var cellPos = cell.position
		var mousePos = get_local_mouse_position()
		
		if cellPos.x <= mousePos.x and mousePos.x <= cellPos.x + cellSize.x and cellPos.y <= mousePos.y and mousePos.y <= cellPos.y + cellSize.y:
			return i
		
	return 0
		
func getCellsUnderArea(size: int) -> Array: # problem here is that area2d requires a collision shape to detect
	var cells = grid.get_children()
	var cellsList = []
	for i in range(cells.size()):
		var cell = cells[i]
		var isIn = checkCellInArea(cell, size)
		if isIn:
			cellsList.append(i)
			
	return cellsList

func checkCellInArea(cell: ColorRect, size: int) -> bool:
	var mousePos = get_local_mouse_position()
	var mpLeft = mousePos.x - size
	var mpRight = mousePos.x + size
	var mpUp = mousePos.y - size
	var mpDown = mousePos.y + size
	var cellPos = cell.position
	
	if mpLeft < cellPos.x and cellPos.x < mpRight:
		if mpUp < cellPos.y and cellPos.y < mpDown:
			return true

	return false

func checkAllCells() -> void:
	var cells = grid.get_children()
	var image = currentBlueprint.get_image()
	for i in range(cells.size()):
		var y: int = int(i / 48)
		var x = i % 48
		var color = image.get_pixel(x, y)
		
		if customIsEqualApprox(color, cells[i].color, 0.30):
			cells[i].set_meta("is_correct_color", true)
			
func customIsEqualApprox(color1: Color, color2: Color, threshold: float) -> bool:
	var col1Vec = Vector3(color1.r, color1.g, color1.b)
	var col2Vec = Vector3(color2.r, color2.g, color2.b)
	
	return col1Vec.distance_to(col2Vec) < threshold

func onDragDown() -> void:
	lastPos = self.position
	root.currentTool = root.tools.HANDCLOSE
	isDragging = true

func onDragUp() -> void:
	var mouse = get_viewport().get_mouse_position()
	if mouse.x > 1000 and mouse.y < 300:
		checkAllCells()
		refreshBanner(true)
		return
	elif mouse.x > 1000	 and mouse.y > 500:
		refreshBanner(false)
		return
		
	isDragging = false
	root.currentTool = root.tools.HANDOPEN
	self.position = lastPos

func onDragEnter() -> void:
	lastTool = root.currentTool
	root.currentTool = root.tools.HANDOPEN

func onDragExit() -> void:
	if isDragging: return
	root.currentTool = lastTool
	
func moveTowardsPosition(targetPos: Vector2) -> void:
	var delta = get_process_delta_time()
	self.position = self.position.lerp(targetPos, 10.0 * delta)
	
func refreshBanner(isSubmit: bool) -> void:
	var total = 0
	var cells = grid.get_children()
	if isSubmit:
		for i in range(cells.size()):
			if cells[i].get_meta("is_correct_color") == true:
				total += 1
				cells[i].set_meta("is_correct_color", false)
			
			cells[i].queue_free()
		
		print(total)
	
	isDragging = false
	root.currentTool = root.tools.HANDOPEN
	generateGrid()
	totalCellsPainted = 0
	modelSprite.newTexture()
	currentBanner = modelSprite.bannerTexture
	currentBlueprint = bannerToBlueprintDict.get(currentBanner)
	
	self.position = lastPos + Vector2(0, 1000)
	var bannertween = create_tween()
	bannertween.tween_property(self, "position", lastPos, 2.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
