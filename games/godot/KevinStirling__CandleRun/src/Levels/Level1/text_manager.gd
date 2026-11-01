extends CanvasLayer
	
@onready var flammable = $"../Lantern"
@onready var label = $Label
@onready var label_2 = $Label2
@onready var jump_cntrl = $"../JumpCntrl"
@onready var movement_cntrl = $"../MovementCntrl"

@export var level : Level


# Called when the node enters the scene tree for the first time.
func _ready():
	level.won.connect(lit)

func lit():
	jump_cntrl.visible = false
	movement_cntrl.visible = false
	label.visible = true
	label_2.visible = false
