extends CanvasLayer

@onready var contador_monedas: Label = $ContadorMonedas

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true 
	var game_manager = get_node("%gameManager")
	game_manager.puntuacion_actualizada.connect(_on_puntuacion_actualizada)
	
func _on_puntuacion_actualizada(puntuacion_actual:int) -> void:
	contador_monedas.text = str(puntuacion_actual)
