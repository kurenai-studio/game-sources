extends SceneTree
var failures:=0
func check(ok: bool, caption: String) -> void:
	if not ok:
		failures+=1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	var library=load("res://ui/announcer_phrases.gd").new()
	check(library.has_method("validate_catalog"),"replaceable phrase catalog validates context")
	if library.has_method("validate_catalog"):
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/announcer_phrases.json"))
		check(library.validate_catalog(data).is_empty(),"shipped catalog passes")
		var bad=data.duplicate(true)
		bad.lines[0].text="Horse {winner} is certain to win"
		check(not library.validate_catalog(bad).is_empty(),"unknown/context-wrong placeholder rejected")
		bad=data.duplicate(true)
		bad.lines[0].traits.energy=2.0
		check(not library.validate_catalog(bad).is_empty(),"out-of-range trait rejected")
		bad=data.duplicate(true)
		bad.lines[1].id=bad.lines[0].id
		check(not library.validate_catalog(bad).is_empty(),"duplicate line IDs rejected")
	print("CONTENT 14: ",failures," failures")
	quit(1 if failures else 0)
