extends CanvasLayer
	
@onready var flammable = $"../Lantern"
@onready var label = $Label

@onready var level = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	level.won.connect(lit)

func lit():
	label.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
