class_name LocalSave
extends RefCounted
## הכל על המכשיר: שיאים, mute, שם תצוגה.
## השם לא חובה, ואפשר אותו שם כמה פעמים — זה לא חשבון.

const PATH := "user://bloomgrid.cfg"
const TOP_N := 8
const NAME_MAX := 16


static func _open() -> ConfigFile:
	var cf := ConfigFile.new()
	cf.load(PATH)
	return cf


static func sanitize_name(raw: String) -> String:
	# זורקים תווי בקרה וקישורים. זה שם על המסך, לא לוגין.
	var cleaned := ""
	for i in range(raw.length()):
		var ch := raw.unicode_at(i)
		if ch < 32 or ch == 127:
			cleaned += " "
		else:
			cleaned += char(ch)
	var t := cleaned.strip_edges().replace("|", " ")
	while t.find("  ") >= 0:
		t = t.replace("  ", " ")
	var low := t.to_lower()
	if low.contains("@") or low.contains("://") or low.contains("www."):
		return ""
	if t.length() > NAME_MAX:
		t = t.substr(0, NAME_MAX)
	return t.strip_edges()


static func player_name() -> String:
	return sanitize_name(str(_open().get_value("run", "player_name", "")))


static func set_player_name(raw: String) -> String:
	var cf := _open()
	var clean := sanitize_name(raw)
	cf.set_value("run", "player_name", clean)
	cf.save(PATH)
	return clean


static func best() -> int:
	return Rules.clamp_score(int(_open().get_value("run", "best", 0)))


static func last() -> int:
	return Rules.clamp_score(int(_open().get_value("run", "last", 0)))


static func is_muted() -> bool:
	return bool(_open().get_value("run", "muted", false))


static func set_muted(v: bool) -> void:
	var cf := _open()
	cf.set_value("run", "muted", v)
	cf.save(PATH)


static func top_entries() -> Array:
	var cf := _open()
	var raw_json := str(cf.get_value("run", "top_json", ""))
	if raw_json.strip_edges() != "":
		var parsed: Variant = JSON.parse_string(raw_json)
		if parsed is Array:
			return _normalize_entries(parsed)
	return _legacy_top(str(cf.get_value("run", "top", "")))


static func top_scores() -> Array:
	var out: Array = []
	for e in top_entries():
		out.append(int(e.get("score", 0)))
	return out


static func _legacy_top(raw: String) -> Array:
	var out: Array = []
	if raw.strip_edges() == "":
		return out
	for part in raw.split(",", false):
		var n := Rules.clamp_score(int(part))
		if n > 0:
			out.append({"score": n, "name": ""})
	out.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	while out.size() > TOP_N:
		out.pop_back()
	return out


static func _normalize_entries(raw: Array) -> Array:
	var out: Array = []
	for item in raw:
		if item is Dictionary:
			var n := Rules.clamp_score(int(item.get("score", item.get("s", 0))))
			if n > 0:
				out.append({
					"score": n,
					"name": sanitize_name(str(item.get("name", item.get("n", "")))),
				})
		elif Rules.clamp_score(int(item)) > 0:
			out.append({"score": Rules.clamp_score(int(item)), "name": ""})
	out.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
	while out.size() > TOP_N:
		out.pop_back()
	return out


static func write_run(score: int, raw_name: String = "") -> Dictionary:
	var cf := _open()
	var muted := bool(cf.get_value("run", "muted", false))
	var prev_best := Rules.clamp_score(int(cf.get_value("run", "best", 0)))
	score = Rules.clamp_score(score)
	var nxt_best := maxi(prev_best, score)
	var name := sanitize_name(raw_name)
	if name == "":
		name = sanitize_name(str(cf.get_value("run", "player_name", "")))
	var top: Array = top_entries()
	if score > 0:
		top.append({"score": score, "name": name})
		top.sort_custom(func(a, b): return int(a.get("score", 0)) > int(b.get("score", 0)))
		while top.size() > TOP_N:
			top.pop_back()
	var rank := 0
	for i in range(top.size()):
		if int(top[i].get("score", 0)) == score and str(top[i].get("name", "")) == name:
			rank = i + 1
			break
	if rank == 0:
		for i in range(top.size()):
			if int(top[i].get("score", 0)) == score:
				rank = i + 1
				break
	cf.set_value("run", "best", nxt_best)
	cf.set_value("run", "last", score)
	cf.set_value("run", "player_name", name)
	cf.set_value("run", "muted", muted)
	cf.set_value("run", "top_json", JSON.stringify(top))
	cf.save(PATH)
	return {
		"best": nxt_best,
		"last": score,
		"top": top,
		"rank": rank,
		"name": name,
		"is_record": score > 0 and score > prev_best,
		"on_board": rank > 0,
	}


static func set_name_on_score(score: int, raw_name: String) -> Array:
	var name := sanitize_name(raw_name)
	var top: Array = top_entries()
	for e in top:
		if int(e.get("score", 0)) == score:
			e["name"] = name
			break
	var cf := _open()
	cf.set_value("run", "player_name", name)
	cf.set_value("run", "top_json", JSON.stringify(top))
	cf.save(PATH)
	return top


static func write_best(score: int) -> int:
	var cf := _open()
	var nxt := maxi(Rules.clamp_score(int(cf.get_value("run", "best", 0))), Rules.clamp_score(score))
	cf.set_value("run", "best", nxt)
	cf.save(PATH)
	return nxt
