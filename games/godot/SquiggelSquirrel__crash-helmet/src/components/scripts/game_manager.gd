extends Node

signal state_changed
signal inputs_remapped
signal level_changed


enum State {
		PLAYING,
		DEAD,
		WON,
		END_GAME
	}
enum Menu {
		NONE,
		START,
		PAUSED,
		CONTROLS,
		SETTINGS,
		ABOUT
	}
var state :State = State.PLAYING
var menu :Menu = Menu.START
var level_index := -1
var candy_stats := [
	[0,0], [0,0], [0,0]]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_states(new_state: State, new_menu: Menu) -> void:
	state = new_state
	menu = new_menu
	state_changed.emit()


func count_candies() -> void:
	candy_stats[level_index][1] = get_tree().get_node_count_in_group(&"candies")


func count_candies_collected() -> void:
	candy_stats[level_index][0] = (
			candy_stats[level_index][1]
			- get_tree().get_node_count_in_group(&"candies"))


func set_level_index(new_index :int) -> void:
	level_index = new_index
	level_changed.emit()
