extends Node

var sound_list:={}

const JUMP = preload("uid://dusx5sdbxvtf0")
const LASER = preload("uid://d3u82m25c6sl1")
const PICKUP = preload("uid://dqbgkuf5e07cu")
const TOM_PAIN = preload("uid://ci5mrxqskl2k7")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sound_list["pain"]=TOM_PAIN
	sound_list["pickup"]=PICKUP
	sound_list["laser"]=LASER

func play_sound(name:String,entity:String) -> void:
	if entity=="player":
		$Player.stream=sound_list.get(name)
		$Player.play()
		await get_tree().process_frame
	if entity=="enemy":
		$Enemy.stream=sound_list.get(name)
		$Enemy.play()
		await get_tree().process_frame
	if entity=="item":
		$Item.stream=sound_list.get(name)
		$Item.play()
		await get_tree().process_frame

func set_bus(name:String):
	$Player.bus=name
