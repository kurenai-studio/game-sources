extends RefCounted
const Store=preload("res://core/session_store.gd")
var directory: String="user://games"
var error: String=""

func valid_id(id: String) -> bool:
	return id.length()==32 and id.is_valid_hex_number(false) and id==id.to_lower()

func path_for(id: String) -> String:
	return directory.path_join(id+".sdgame") if valid_id(id) else ""

func title_for(id: String) -> String:
	var path:=directory.path_join(id+".info.json")
	if valid_id(id) and FileAccess.file_exists(path):
		var file:=FileAccess.open(path,FileAccess.READ)
		if file!=null and file.get_length()<8192:
			var info=JSON.parse_string(file.get_as_text())
			if info is Dictionary and info.get("title") is String and valid_title(info.title): return info.title
	return "Game "+id.left(8)

func valid_title(title: String) -> bool:
	return not title.strip_edges().is_empty() and title.length()<=48 and not "\n" in title and not "\r" in title

func save_game(session: RefCounted, settings: RefCounted, title: String="") -> bool:
	error=""
	if session.phase in ["RACING","RESULTS"]:
		error="Finish the current race before saving or switching games."; return false
	if not valid_id(session.game_id) or (not title.is_empty() and not valid_title(title)):
		error="Use a game name of 1 to 48 characters."; return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK:
		error="The saved-games folder could not be created."; return false
	var store:=Store.new()
	if not store.save(session,settings,path_for(session.game_id)):
		error=store.error; return false
	var saved_title:=title.strip_edges() if not title.is_empty() else title_for(session.game_id)
	var info:=FileAccess.open(directory.path_join(session.game_id+".info.json"),FileAccess.WRITE)
	if info==null:
		error="Game saved, but its display name could not be written."; return false
	info.store_string(JSON.stringify({"title":saved_title,"round":session.round_number}))
	info.flush()
	if info.get_error()!=OK: error="Game saved, but its display name could not be written."
	info.close()
	return error.is_empty()

func games() -> Array:
	var rows: Array=[]
	if not DirAccess.dir_exists_absolute(directory): return rows
	for file in DirAccess.get_files_at(directory):
		if not file.ends_with(".sdgame"): continue
		var id:=file.trim_suffix(".sdgame")
		if not valid_id(id): continue
		rows.append({"id":id,"title":title_for(id),"path":path_for(id),"modified":FileAccess.get_modified_time(path_for(id))})
	rows.sort_custom(func(a,b): return a.modified>b.modified if a.modified!=b.modified else a.title.naturalnocasecmp_to(b.title)<0)
	return rows

func remove_game(id: String, current_id: String) -> bool:
	error=""
	if not valid_id(id) or id==current_id:
		error="Open another game before deleting the current game."; return false
	var path:=path_for(id)
	if not FileAccess.file_exists(path): error="This saved game no longer exists."; return false
	# Keep an internal recovery copy; only direct .sdgame files appear in the list.
	var removed:=directory.path_join("removed").path_join(id+"-"+str(Time.get_ticks_usec()))
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(removed))!=OK:
		error="Could not create the recovery folder. The game was kept."; return false
	if DirAccess.rename_absolute(path,removed.path_join(id+".sdgame"))!=OK:
		error="Could not remove this saved game."; return false
	for extra in [path+".bak",directory.path_join(id+".info.json")]:
		if FileAccess.file_exists(extra): DirAccess.rename_absolute(extra,removed.path_join(extra.get_file()))
	return true

static func keep_profile_library(destination: RefCounted, current: RefCounted) -> void:
	# The latest autosaved library is authoritative across games. Restoring an
	# old game must not resurrect a deleted profile or rename a current one.
	destination.profiles=current.profiles.duplicate(true)
