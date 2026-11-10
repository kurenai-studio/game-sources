extends CenterContainer


var _ambience = 100
var _music = 100
var _sounds = 100


func _ready():
	grab_focus()
	_set_volume("ambience", _ambience)
	_set_volume("music", _music)
	_set_volume("sounds", _sounds)


func grab_focus():
	get_node("container/music").grab_focus()


func _increment_volume(bus, volume) -> int:
	volume += 10
	if volume > 100:
		volume = 0
	_set_volume(bus, volume)
	return volume


func _set_volume(bus, volume):
	var volumedb = linear2db(float(volume) / 100)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), volumedb)


func _on_ambience_pressed():
	_ambience = _increment_volume("ambience", _ambience)
	get_node("container/ambience").text = "Ambience %4d%%" % _ambience


func _on_music_pressed():
	_music = _increment_volume("music", _music)
	get_node("container/music").text = "Music %7d%%" % _music


func _on_sounds_pressed():
	_sounds = _increment_volume("sounds", _sounds)
	get_node("container/sounds").text = "Sounds %6d%%" % _sounds


func _on_back_pressed():
	visible = false
	get_node("../menu").visible = true
	get_node("../menu").grab_focus()
