extends Area2D

@onready var overlay = $"../HighlightOverlay"
@onready var tween: Tween
@onready var isPlayerIn = false
@onready var UI = $"../CanvasLayer"
@onready var rect = $"../CanvasLayer/ColorRect"
@onready var cMod = $"../CanvasModulate"

@onready var libraryGame: Node

signal open
signal close

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	libraryGame = preload("res://Scenes/library_game.tscn").instantiate()
	overlay.modulate.a = 0
	rect.modulate.a = 0
	self.open.connect(libraryGame.tweenIn)
	self.close.connect(libraryGame.tweenOut)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not libraryGame.visible: return
	if Input.is_action_just_pressed("escape"):
		libraryGame.hide()
		Global.player.canMove = true
		close.emit()
		cMod.show()
		rect.modulate.a = 1
		libraryGame.hide()
		var tween = create_tween()
		tween.tween_property(rect, "modulate:a", 0.0, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	
	if Input.is_action_just_pressed("interact") and isPlayerIn:
		cMod.hide()
		Global.player.canMove = false
		var tween = create_tween()
		tween.tween_property(rect, "modulate:a", 1.0, 0.3)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
			
		await tween.finished
		if UI.get_child_count() <= 1:
			UI.add_child(libraryGame)
		libraryGame.show()
		open.emit()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		isPlayerIn = true
		overlay.move_to_front()
		tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 1.0, 0.25)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		isPlayerIn = false
		overlay.move_to_front()
		tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 0.0, 0.25)
