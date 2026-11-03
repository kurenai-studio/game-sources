extends Node2D

@onready var root = $".."

@onready var redbanner = load("res://Assets/Sewing/red_banner.png")
@onready var bluebanner = load("res://Assets/Sewing/blue_banner.png")
@onready var greenbanner = load("res://Assets/Sewing/green_banner.png")

@onready var bannerlist = [redbanner, bluebanner, greenbanner]
@onready var bannerTexture;

var velo: float
var acc: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	velo = 0.0
	acc = 0.0
	newTexture()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("scroll_banner_up") and root.position.y > -300:
		acc = -2
	if Input.is_action_pressed("scroll_banner_down") and root.position.y < 100:
		acc = 2
		
	velo += acc
	root.position.y += velo
	
	acc = 0
	velo /= 1.25
	
func newTexture() -> void:
	bannerTexture = bannerlist.pick_random()
	self.texture = bannerTexture
	self.modulate.a = 0.2
	
func checkCellForCorrectColor(cell: ColorRect) -> void:
	var status = cell.get_meta("is_painted")
	if not status:
		if bannerTexture == redbanner and cell.color.is_equal_approx(Color(0.75, 0, 0)):
			root.totalCellsPainted += 1
			cell.set_meta("is_painted", true)
		if bannerTexture == bluebanner and cell.color.is_equal_approx(Color(0, 0, 0.75)):
			root.totalCellsPainted += 1
			cell.set_meta("is_painted", true)
		if bannerTexture == greenbanner and cell.color.is_equal_approx(Color(0, 0.75, 0)):
			root.totalCellsPainted += 1
			cell.set_meta("is_painted", true)
		
