extends Area2D

@onready var overlay = $"../SelectOverlay"
@onready var UIcanvaslayer = $"../../UI"
@onready var isPlayerIn = false
@onready var isSewing = false 
var bannergame: Node2D
const sewing = preload("res://Scenes/banner_game.tscn")

var tween: Tween

signal onBannerTaskClose(isPainting: bool)
signal onBannerTaskOpen

func _ready() -> void:
	overlay.modulate.a = 0
	bannergame = sewing.instantiate()
	self.onBannerTaskClose.connect(bannergame.playClosingAnim)
	self.onBannerTaskOpen.connect(bannergame.playOpeningAnim)

func _process(delta: float) -> void:
	# for some reason sometimes isSewing just flickers true or false
	# would like for this to be fixed, but the game sorta works, so im not gnna fix this rn
	if Input.is_action_just_pressed("escape") and not bannergame.isTweening:		
		self.onBannerTaskClose.emit()
		isSewing = false
		Global.player.canMove = true
	
	if Input.is_action_just_pressed("interact") and isPlayerIn and not bannergame.isTweening:
		if isSewing: return 
		if tween and tween.is_running():
			tween.kill()
			
		self.onBannerTaskOpen.emit(bannergame.isPainting if bannergame else true)
		Global.player.canMove = false
		isSewing = true
		
		if UIcanvaslayer.get_child_count() <= 0:
			UIcanvaslayer.add_child(bannergame)
	

func _on_body_entered(body: Node2D) -> void:
	isPlayerIn = true
	overlay.move_to_front()
	tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.25)

func _on_body_exited(body: Node2D) -> void:
	isPlayerIn = false
	overlay.move_to_front()
	tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.25)
	
