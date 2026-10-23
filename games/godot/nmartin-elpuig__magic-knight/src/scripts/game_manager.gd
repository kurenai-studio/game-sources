extends Node

var puntuacion = 0

@onready var etiqueta_puntuacion: Label = $"Etiqueta puntuacion"

signal puntuacion_actualizada(puntuacion_actual:int)

func incrementa_un_punto():
	puntuacion += 1
	puntuacion_actualizada.emit(puntuacion)
	etiqueta_puntuacion.text = "Has obtenido\n"+str(puntuacion)+" monedas."
