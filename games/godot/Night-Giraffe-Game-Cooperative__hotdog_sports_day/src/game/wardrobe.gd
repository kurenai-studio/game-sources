class_name Wardrobe
extends RefCounted
## The silly things in the dressing room (data/wardrobe.json): hats, outfits,
## specs, hair, sausages, buns, colours and trails, and what playing unlocks
## each. Unlocks are for everyone on the tablet, kept in the profile.
##
## A slot's choices are Looks.CHOICES' (the ones there from the start) then
## the wardrobe's, in its order.

const SLOTS := ["hat", "outfit", "specs", "hair", "tache", "sausage", "bun", "band", "trail"]
## What each count is, for the hints on a locked thing: [one, many].
const NEEDS := {
	"play": ["PLAY AN EVENT", "PLAY %d EVENTS"],
	"medals": ["WIN A MEDAL", "WIN %d MEDALS"],
	"golds": ["WIN A GOLD MEDAL", "WIN %d GOLD MEDALS"],
	"perfects": ["BOUNCE A PERFECT", "BOUNCE %d PERFECTS"],
	"sizzles": ["RUN SO FAST YOU SIZZLE", "SIZZLE %d TIMES"],
	"games": ["FINISH THE GAMES", "FINISH THE GAMES %d TIMES"],
	"records": ["BREAK A WORLD RECORD", "BREAK %d WORLD RECORDS"],
	"together": ["PLAY WITH A FRIEND", "PLAY %d EVENTS WITH FRIENDS"],
	"tutorial": ["FINISH LEARN TO PLAY", "FINISH LEARN TO PLAY"],
}

static var _items: Array = []
static var _by_key: Dictionary = {}
static var _art: Dictionary = {}


## The profile (an autoload; named at run time so the tests can load this).
static func _p() -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node("Profile")


static func items() -> Array:
	if _items.is_empty():
		var f := FileAccess.open("res://data/wardrobe.json", FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
		_items = d.get("items", []) if d is Dictionary else []
		for it in _items:
			_by_key["%s:%s" % [it.slot, it.id]] = it
	return _items


## The drawings' facts (tools/gen_art.py writes them): the cell, which
## outfits have a part behind, which hats let the hair show.
static func art() -> Dictionary:
	if _art.is_empty():
		var f := FileAccess.open("res://assets/art/wardrobe/wardrobe.json", FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
		_art = d if d is Dictionary else {"cell": [88, 104], "offset": [18, 32], "cols": 8}
	return _art


static func item(slot: String, id: String) -> Dictionary:
	items()
	return _by_key.get("%s:%s" % [slot, id], {})


## Everything there is for a slot, in order: from the start, then to unlock.
static func choices(slot: String) -> Array:
	var out: Array = []
	match slot:
		"hat", "outfit", "trail":
			out = ["none"]
		_:
			out = Looks.CHOICES.get(slot, []).duplicate()
	for it in items():
		if String(it.slot) == slot and not String(it.id) in out:
			out.append(String(it.id))
	return out


## Whether a thing can be worn (the stripe shares the band's colours).
static func is_open(slot: String, id: String) -> bool:
	if slot == "stripe":
		slot = "band"
	var it := item(slot, id)
	if it.is_empty() or not it.has("need") or (it.need as Dictionary).is_empty():
		return true
	return "%s:%s" % [slot, id] in _p().unlocked


static func name_of(slot: String, id: String) -> String:
	if slot == "stripe":
		slot = "band"
	var it := item(slot, id)
	if not it.is_empty():
		return String(it.name)
	if slot == "band":
		return id.capitalize()
	if id == "none":
		return "None"
	return String(Looks.NAMES.get(id, id.capitalize()))


## What unlocks a thing, and how far along: "WIN 3 GOLD MEDALS  1/3".
static func hint(slot: String, id: String) -> String:
	if slot == "stripe":
		slot = "band"
	var it := item(slot, id)
	var need: Dictionary = it.get("need", {})
	for k in need:
		var want := int(need[k])
		var words: Array = NEEDS.get(k, [String(k).to_upper(), String(k).to_upper() + " %d"])
		var text := String(words[0]) if want <= 1 else String(words[1]) % want
		if want > 1 and k != "tutorial":
			text += "  %d/%d" % [mini(int(_p().stats.get(k, 0)), want), want]
		return text
	return ""


## Unlock whatever the counts now reach. Returns the newly unlocked items
## ({slot, id, name}), newest last; they wait in the profile's fresh list to be seen.
static func check() -> Array:
	var got: Array = []
	for it in items():
		var need: Dictionary = it.get("need", {})
		if need.is_empty():
			continue
		var key := "%s:%s" % [it.slot, it.id]
		if key in _p().unlocked:
			continue
		var ok := true
		for k in need:
			if int(_p().stats.get(k, 0)) < int(need[k]):
				ok = false
		if ok:
			_p().unlocked.append(key)
			_p().fresh.append(key)
			got.append({"slot": String(it.slot), "id": String(it.id), "name": String(it.name)})
	return got


## Count something that happened (and save later).
static func count(stat: String, n := 1) -> void:
	_p().stats[stat] = int(_p().stats.get(stat, 0)) + n


## After an event: count it, the medals and records, and playing with friends.
## Returns what it unlocked.
static func after_event(meet: Meet, records := 0) -> Array:
	var humans := meet.humans()
	if humans.is_empty():
		return []
	count("play")
	if humans.size() > 1:
		count("together")
	var st := meet.standings()
	for h in humans:
		var p := st.find(h)
		var marked := meet.best(h) > 0.0 and not (meet.kind == "race" and not meet.times.has(h))
		if marked and p >= 0 and p < 3:
			count("medals")
			if p == 0:
				count("golds")
	if records > 0:
		count("records", records)
	var got := check()
	_p().save()
	return got


## A look's choices that aren't unlocked go back to the first choice (a hot
## dog made on another tablet, or before something was locked).
static func tidy(look: Dictionary) -> Dictionary:
	for slot in SLOTS:
		if slot == "band":
			var band: Array = look.get("band", ["red", "white"])
			for i in band.size():
				if not is_open("band", String(band[i])):
					band[i] = "red" if i == 0 else "white"
			continue
		var id := String(look.get(slot, "none"))
		if id != "none" and not is_open(slot, id):
			look[slot] = "none" if slot in ["hat", "outfit", "trail", "specs", "hair", "tache"] else choices(slot)[0]
	return look


## Words for the unlocks, short enough for one line: "VIKING HELMET AND 2 MORE".
static func news(got: Array) -> String:
	if got.is_empty():
		return ""
	var first := String(got[0].name).to_upper()
	if got.size() == 1:
		return first
	if got.size() == 2:
		return "%s AND %s" % [first, String(got[1].name).to_upper()]
	return "%s AND %d MORE" % [first, got.size() - 1]
