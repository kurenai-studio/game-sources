extends Node2D

@onready var isTweening = false
@onready var isPlayingBannerGame: bool
@onready var player = get_node("/root/root/gameboy/Player")
@onready var scissors = $SewBox/Scissors

@onready var bannerGame = $Banner
@onready var isPainting = true

@onready var sewBox = $SewBox
@onready var targetPos;
@onready var currentPos;

enum tools {SCISSORS, NEEDLE, PAINTBRUSH, NONE, HANDOPEN, HANDCLOSE}
enum paintBrushColors {RED, GREEN, BLUE}
enum threadColors {RED, GREEN, BLUE, GOLD, WHITE}

@onready var currentTool = tools.NONE
@onready var currentPaintColor = paintBrushColors.RED
@onready var currentThreadColor = threadColors.RED

@onready var gameboyCursor = load("res://Assets/Cursors/gameboy_mouse_cursor.png")
@onready var scissorsCursor = load("res://Assets/Cursors/gameboy_scissors_cursor.png")
@onready var needleCursor = load("res://Assets/Cursors/gameboy_needle.png")
@onready var paintbrushCursor = load("res://Assets/Cursors/gameboy_paintbrush.png")
@onready var handOpenCursor = load("res://Assets/Cursors/grab_open_cursor.png")
@onready var handCloseCursor = load("res://Assets/Cursors/grab_close_cursor.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	currentPos = self.position
	targetPos = Vector2(self.position.x - 200, self.position.y)
	sewBox.visible = false
	playOpeningAnim(isPainting)
	
func _process(delta: float) -> void:
	isPainting = bannerGame.totalCellsPainted < 5760
	checkMouse(targetPos)
	determineCursor()
	determineColor()
		
func determineCursor() -> void:
	if Global.currentScene == "room": return
	if not isPlayingBannerGame: return
	
	match currentTool:
		tools.NONE:
			Input.set_custom_mouse_cursor(gameboyCursor, Input.CURSOR_ARROW, Vector2(16, 16))
		tools.NEEDLE:
			Input.set_custom_mouse_cursor(needleCursor, Input.CURSOR_ARROW, Vector2(31, 31))
		tools.SCISSORS:
			Input.set_custom_mouse_cursor(scissorsCursor, Input.CURSOR_ARROW, Vector2(16, 16))
		tools.PAINTBRUSH:
			Input.set_custom_mouse_cursor(paintbrushCursor, Input.CURSOR_ARROW, Vector2(16, 16))
		tools.HANDOPEN:
			Input.set_custom_mouse_cursor(handOpenCursor, Input.CURSOR_ARROW, Vector2(16, 16))
		tools.HANDCLOSE:
			Input.set_custom_mouse_cursor(handCloseCursor, Input.CURSOR_ARROW, Vector2(16, 16))
	
func determineColor() -> void:
	if currentTool == tools.PAINTBRUSH:
		match currentPaintColor:
			paintBrushColors.RED:
				bannerGame.activeColor = Color(0.75, 0, 0)
			paintBrushColors.BLUE:
				bannerGame.activeColor = Color(0, 0, 0.75)
			paintBrushColors.GREEN:
				bannerGame.activeColor = Color(0, 0.75, 0)
	if currentTool == tools.NEEDLE:
		match currentThreadColor:
			threadColors.RED:
				bannerGame.activeColor = Color(0.75, 0, 0)
			threadColors.BLUE:
				bannerGame.activeColor = Color(0, 0, 0.75)
			threadColors.GREEN:
				bannerGame.activeColor = Color(0, 0.75, 0)
			threadColors.GOLD:
				bannerGame.activeColor = Color(255, 215, 0)
			threadColors.WHITE:
				bannerGame.activeColor = Color(1, 1, 1)
	
func playOpeningAnim(isPainting: bool) -> void:
	if isTweening:
		return
	
	isPlayingBannerGame = true
	$SewBox.visible = false if isPainting else true
	$Table.visible = true
	$Banner.visible = true
	$TrashBin.visible = true
	$BannerRack.visible = true
	$PaintBuckets.visible = true if isPainting else false
	isTweening = true
	
	$Table.position.y = 1200
	var tabletween = create_tween()
	tabletween.tween_property($Table, "position:y", 400, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	$SewBox.position.y = 800
	var sewtween = create_tween()
	sewtween.tween_property($SewBox, "position:y", -50, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	$Banner.position.y = 1000
	var bannertween = create_tween()
	bannertween.tween_property($Banner, "position:y", -50, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	$PaintBuckets.position.y = -500
	var painttween = create_tween()
	painttween.tween_property($PaintBuckets, "position:y", 250, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	await sewtween.finished
	isTweening = false
		
		
func playClosingAnim() -> void:
	if isTweening:
		return
		
	$TrashBin.visible = false
	$BannerRack.visible = false
	
	isPlayingBannerGame = false
	isTweening = true
	var tabletween = create_tween()
	tabletween.tween_property($Table, "position:y", 1200, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	var sewtween = create_tween()
	sewtween.tween_property($SewBox, "position:y", 800, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	var bannertween = create_tween()
	bannertween.tween_property($Banner, "position:y", 1000, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	var painttween = create_tween()
	painttween.tween_property($PaintBuckets, "position:y", -500, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	await sewtween.finished
	$Banner.visible = false
	$Table.visible = false
	$SewBox.visible = false
	$PaintBuckets.visible = false
	isTweening = false


func onPaintingFinished() -> void:
	currentTool = tools.NONE
	
	$SewBox.visible = true
	$SewBox.position.y = 800
	var sewtween = create_tween()
	sewtween.tween_property($SewBox, "position:y", -150, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	var painttween = create_tween()
	painttween.tween_property($PaintBuckets, "position:y", -500, 1.25)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
func checkMouse(targetPos: Vector2) -> void:
	var mousePos = get_viewport().get_mouse_position()
	var delta = get_process_delta_time()

	if mousePos.x > 1025:
		self.position = self.position.lerp(targetPos, delta * 10.0)
	else:
		self.position = self.position.lerp(currentPos, delta * 10.0)
