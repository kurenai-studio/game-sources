extends CanvasLayer
	
@onready var lantern = $"../Lantern"
@onready var label = $Label
@onready var label_2 = $Label2


# Called when the node enters the scene tree for the first time.
func _ready():
	lantern.fire_lit.connect(lit)

func lit():
	label.visible = true
	label_2.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
