extends PanelContainer

@export var candy_count_label :Label


func _ready() -> void:
	GameManager.state_changed.connect(_on_game_state_changed)


func _on_game_state_changed() -> void:
	if ! (
			GameManager.state == GameManager.State.WON
			and
			GameManager.menu == GameManager.Menu.NONE
		):
		visible = false
		return
	visible = true
	if GameManager.level_index < 2:
		%Title.text = "Level Complete!"
		candy_count_label.text = candy_stats_text(GameManager.level_index)
		%Continue.visible = true
		%Continue.grab_focus()
	else:
		%Title.text = "Game Complete!"
		var lines :PackedStringArray = []
		for index in 3:
			lines.append(candy_stats_text(index))
		candy_count_label.text = "\n".join(lines)
		%Continue.visible = false


func candy_stats_text(level_index :int) -> String:
	return (
			"(Collected %s/%s Candies)"
			% GameManager.candy_stats[level_index])
