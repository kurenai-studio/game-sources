# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name InfoScreen
extends PageFrame
## Info (playbook 6.2): one full guide, opened only when tapped, always at the
## top. Short sections in the order a player meets things, each with a small
## real example drawn by src/theme/ code.
##
## Fixed text here never names a tower, creature, region, level or card
## (docs/ARCHITECTURE.md 2.1). Numbers come from `rules` (the rules.json keys)
## when the App has them and are left out of the sentence when it does not.
## Names under the pictures come from `names` (id to name, from data/stats/)
## and are left out when it is empty. The towers, creatures, bosses and map features it
## draws come from `content` (InfoContent, read from the catalog and the levels), never from
## a fixed list, so what the data holds is what the guide shows. With no content, those
## pictures and the Map features section are left out.

const PANEL_PADDING: float = 64.0

## What each map feature does, in fixed words (contract 14.1). A section line shows only for
## the features that `content` holds.
const FEATURE_TEXT: Dictionary[StringName, String] = {
	&"tunnel": "Tunnel: a road under a grassy mound. A walker inside is out of reach, so no tower can hit it until it comes out.",
	&"bridge": "Bridge: two roads cross on a plank deck and do not join. Walkers go straight across.",
	&"slide": "Ice slide: a one-way road. A walker leaves it only the way its chevrons point.",
	&"stumps": "Hollow stumps: twins with the same carved symbol. A walker can step from one to the other, and is out of reach on the way.",
}

var _arts: Array[InfoArt] = []
var _content: InfoContent


func _init(rules: Dictionary = {}, names: Dictionary = {}, content: InfoContent = null) -> void:
	super("Info")
	_content = content if content != null else InfoContent.new()
	for section: Dictionary in _sections(rules):
		_add_section(section, names)


func _relayout() -> void:
	super()
	var width: float = Layout.content_width(window_size.x, safe) - PANEL_PADDING
	for art: InfoArt in _arts:
		art.fit_width(width)


func _add_section(section: Dictionary, names: Dictionary) -> void:
	var box: VBoxContainer = UiKit.section()
	box.add_child(UiKit.heading(section["title"]))
	for paragraph: String in section["text"]:
		box.add_child(UiKit.label(paragraph))
	var art_kind: StringName = section.get("art", &"")
	if art_kind != &"":
		var ids: Array[StringName] = _ids(art_kind)
		var listed: bool = art_kind == &"towers" or art_kind == &"creatures" or art_kind == &"features"
		if not listed or not ids.is_empty():
			var art: InfoArt = InfoArt.new(art_kind, _captions(art_kind, names, ids), ids)
			_arts.append(art)
			box.add_child(art)
	column.add_child(box.get_parent())


## The ids an art kind draws: from the content for the lists, none for the rest.
func _ids(art_kind: StringName) -> Array[StringName]:
	match art_kind:
		&"towers":
			return _content.towers
		&"creatures":
			return _content.pictures()
		&"features":
			return _content.features
	return [] as Array[StringName]


## Names to draw under the pictures: the data's names for towers and creatures (none when
## `names` lacks them all), the fixed names for the map features.
func _captions(art_kind: StringName, names: Dictionary, ids: Array[StringName]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if art_kind == &"features":
		for id: StringName in ids:
			out.append(InfoArt.FEATURE_NAMES[id])
		return out
	var found: bool = false
	for id: StringName in ids:
		var name_text: String = str(names.get(id, ""))
		found = found or not name_text.is_empty()
		out.append(name_text)
	return out if found else PackedStringArray()


## The guide, in the order a player meets things.
func _sections(rules: Dictionary) -> Array[Dictionary]:
	var refund: String = _percent(rules, "refund_pct", "part of")
	var star2: String = _star2_sentence(rules)
	var waves_at_once: String = _waves_sentence(rules)
	var run_stars: String = _count(rules, "run_stars", "enough")
	var runs_built: bool = bool(rules.get("runs_built", true))
	var sections: Array[Dictionary] = [
		{"title": "The goal", "art": &"walk", "text": [
			"Night creatures walk down the roads toward your village. Every creature that gets through costs lives.",
			"Lose all your lives and the level is lost. Beat every wave and you win."]},
		{"title": "Build, then fight", "art": &"hud", "text": [
			"Each level starts with a build phase. Nothing moves and there is no timer. When you are ready, start the wave.",
			"Creatures then come in real time. You can run at 1x, 2x or 3x speed. You can pause at any moment and still build, upgrade, sell and look at things."]},
		{"title": "Gold", "text": [
			"You earn gold for each creature you defeat and for each wave you clear. Spend it on towers and upgrades.",
			"Sell a tower in the same build phase you bought it and you get all of it back. After that you get %s what you spent." % refund]},
		{"title": "Building towers", "art": &"spots", "text": [
			"Towers stand on the round build spots. Tap a spot, pick a tower, and look at its range ring before you confirm.",
			"Every tower has one job, and none is best everywhere. Mix them."]},
		{"title": "Telling towers apart", "art": &"towers", "text": [
			"Each tower looks different, so you can tell them apart by shape alone. Some shoot, some only hit flyers, some slow creatures down, and some make the towers around them better.",
			"Tap any tower to see its real numbers."]},
		{"title": "Upgrades", "art": &"tiers", "text": [
			"Every tower has three tiers. At tier 3 you pick one of two paths. The choice is permanent for that tower. Selling it is the only way to choose again.",
			"An upgrade shows its cost and the numbers before and after, so you can decide first."]},
		{"title": "Targeting", "text": [
			"Every tower that attacks has a targeting mode: First, Last or Strong. It starts on First. You can change it at any time, even in the middle of a wave, and it stays through upgrades.",
			"First picks the creature nearest the village. Last picks the one farthest from it. Strong picks the one with the highest maximum health. Only creatures in range, and of a kind the tower can hit, count. A tower picks again every time it fires."]},
		{"title": "Creatures", "art": &"creatures", "text": [
			"Creatures differ in speed, health and armor. Some fly, some wear a bubble that stops one hit, some burst into smaller ones, some heal the others, and some break gates.",
			"The last pictures are the bosses. Each region ends with one.",
			"The first time a new one is in the next wave, a card tells you about it. Tap any creature to see its real numbers."]},
		{"title": "Gates", "art": &"gates", "text": [
			"Some road tiles have a socket. Each level gives you a set number of gates, and a gate closes its socket.",
			"Creatures on foot always take the shortest open road to the village. A gate sends them away from one branch and past your towers.",
			"During a build phase, a line shows where they will go. You cannot close every road: that is refused. Gates are locked while a wave is running."]},
		{"title": "Flyers and gate breakers", "art": &"signals", "text": [
			"Flyers ignore roads and gates, so a gate is never the whole answer. A dotted line shows where they fly.",
			"Gate breakers go through a closed gate after a delay. Their route is a dashed line with a crack on each gate they will break."]},
		{"title": "Before each wave", "text": [
			"The wave preview lists what is coming, how many, and from which entrance, A to D. Tap a row for its numbers.",
			"You can call the next wave early to earn a bonus. The button shows the bonus. %s" % waves_at_once]},
		{"title": "Stars", "art": &"stars", "text": [
			"Win a level for one star. %s Each level has its own challenge for the third, shown on its card before you play." % star2,
			"Stars are kept for good. They open new regions."]},
		{"title": "Relaxed", "text": [
			"Relaxed gives you more lives and more gold to start. Nothing else changes.",
			"A Relaxed win earns one star, which is enough to keep going. The other stars need Normal. Normal is always the default."]},
		{"title": "Twists", "text": [
			"Once you have 3 stars on a level, its Twist opens. A Twist is the same map and the same waves with one rule changed.",
			"A Twist has no stars of its own. A win on Normal or Relaxed clears it. The level card and Pause show its name and its rule."]},
		{"title": "More ways to play", "text": [
			"Roguelite is one run of many waves. After each wave you pick a card. Daily is one run a day, the same for everyone, and always Normal.",
			_runs_sentence(runs_built, run_stars)]},
	]
	var features: Dictionary = _features_section()
	if not features.is_empty():
		sections.insert(_index_of(sections, "Before each wave"), features)
	if runs_built:
		sections.append_array(_run_sections())
	return sections


## The Map features section, for the features the content holds. Empty when it holds none.
func _features_section() -> Dictionary:
	if _content.features.is_empty():
		return {}
	var text: Array[String] = ["Later regions add map features to the roads. Each one shows on the map by its shape."]
	for id: StringName in _content.features:
		text.append(FEATURE_TEXT[id])
	text.append("The route line always shows where walkers will go.")
	return {"title": "Map features", "art": &"features", "text": text}


func _index_of(sections: Array[Dictionary], title: String) -> int:
	for i: int in sections.size():
		if sections[i]["title"] == title:
			return i
	return sections.size()


## How a run and the daily go (RULES 14, 15). Shown once the run mode is built.
func _run_sections() -> Array[Dictionary]:
	return [
		{"title": "How a run goes", "text": [
			"A run has 18 waves. The last one is a boss wave. You start with one kind of tower and 1 gate. Other towers and more gates come from cards.",
			"After each of waves 1 to 17 you pick 1 card from 3. The draft opens in the next build phase. You cannot skip it, and the next wave cannot start until you pick. If you call waves early, the drafts wait and come one after another.",
			"A run is won when the last wave has started, no wave is still on the map, and you have lives left. It is lost when your lives reach 0. A boss that gets through costs 20 lives.",
			"You can leave a run at any time and come back to the exact moment you left. Abandoning it counts as a loss at its current wave. A run carries nothing over except progress toward new cards."]},
		{"title": "Cards", "text": [
			"Cards come in five kinds. Tower cards add a tower to your run. Tower perks change a tower you already have. Extra gate cards give you a gate, up to 3. Economy cards help with gold and lives. Risk cards change the next wave and pay a reward.",
			"A risk card changes only the next wave that starts. Its gold is paid with that wave's clear bonus, and nothing is paid if the run ends before then. A draft has at most one risk card, and none while another waits. None come once wave 17 has started, so the boss wave is never changed.",
			"Playing unlocks new cards for later runs. Each one is a sidegrade: it changes how something works and carries a cost. A tower perk you unlocked is offered only once every tower in your run has its basic perk."]},
		{"title": "The daily", "text": [
			"The daily is built like a run, but it comes from the phone's date. Everyone with the same version of the game gets the same run on the same date, with no network. It is always Normal and uses every card.",
			"You can try as often as you like. Each finished try is compared with the day's best. A win beats a loss. Between wins, more lives left is better. Between losses, more waves cleared is better. A tie keeps the earlier result.",
			"Your streak counts days in a row on which you finished a daily. It shows while the last day counted is today or yesterday. A daily belongs to the date it started, even if it ends after midnight. The best result and the streak stay on your phone."]},
	]


## While the run mode is not built, Info says so. Once it is, it names the stars it needs.
func _runs_sentence(runs_built: bool, run_stars: String) -> String:
	if not runs_built:
		return "Both are coming in a later update. Everything in Forkline is earned by playing."
	return "Both open when you have earned %s stars. Everything in Forkline is earned by playing." % run_stars


func _count(rules: Dictionary, key: String, fallback: String) -> String:
	if _has_number(rules, key):
		return str(int(rules[key]))
	return fallback


func _percent(rules: Dictionary, key: String, fallback: String) -> String:
	if _has_number(rules, key):
		return "%d%% of" % int(rules[key])
	return fallback


func _star2_sentence(rules: Dictionary) -> String:
	if _has_number(rules, "star2_lives"):
		return "Win with %d or more lives left for the second." % int(rules["star2_lives"])
	return "Win with most of your lives left for the second."


func _waves_sentence(rules: Dictionary) -> String:
	if _has_number(rules, "max_waves_running"):
		return "At most %d waves can be on the map at once." % int(rules["max_waves_running"])
	return "Only a few waves can be on the map at once."


func _has_number(rules: Dictionary, key: String) -> bool:
	return rules.has(key) and (rules[key] is int or rules[key] is float)
