extends SceneTree

const Settings = preload("res://core/game_settings.gd")
const Help = preload("res://ui/help_panel.gd")
const SettingsPanel = preload("res://ui/settings_panel.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var settings := Settings.new()
	var panel := SettingsPanel.new()
	root.add_child(panel)
	panel.configure(settings, func(): pass)
	var help := Help.new()
	panel.add_child(help)
	help.configure("Race Control")
	var contexts := {}
	var catalog_articles := 0
	for topic in help.topics:
		if str(topic.id).begins_with("setting-"): catalog_articles += 1
		check(not topic.paragraphs.is_empty(), "Empty topic: " + str(topic.id))
		for context in topic.contexts:
			check(not contexts.has(context.to_lower()) or contexts[context.to_lower()] == topic.id, "Ambiguous context: " + str(context))
			contexts[context.to_lower()] = topic.id
	check(catalog_articles == settings.catalog.size(), "Exactly one setting article per catalog key.")
	for item in settings.catalog:
		var topic: Dictionary = help.topic_for_context(item.key)
		check(topic.get("id") == "setting-" + item.key, "Missing setting help: " + item.key)
		check(topic.get("title") == item.label, "Incorrect setting title: " + item.key)
		check(topic.get("planned") == not panel.implemented(item.key), "Incorrect Planned status: " + item.key)
		var row := panel.find_child("Setting_" + item.key, true, false)
		check(is_instance_valid(row) and panel.control_help_context(row) == item.key, "Missing context for settings row: " + item.key)
		check(is_instance_valid(row.find_child("SettingHelp", true, false)), "Missing help button: " + item.key)
	for section_index in range(panel.navigation.item_count):
		var section := panel.navigation.get_item_text(section_index)
		check(not help.topic_for_context(section).is_empty(), "Missing section help: " + section)
	check(help.selected_id == "race-control", "Configure should resolve its initial section.")
	help.open_context("replay_lengths")
	check(help.selected_id == "setting-replay_lengths" and "second-place" in help.article.get_parsed_text() and "qualification" in help.article.get_parsed_text(), "Replay travel should explain its scope.")
	help.open_context("photo_frequency")
	check("first-versus-second" in help.article.get_parsed_text() and "target across many races" in help.article.get_parsed_text(), "Replay eligibility should explain the long-run target and gap.")
	help.filter_topics("preferred payoff")
	check(help.visible_topics.any(func(topic): return topic.id == "virtual-factors"), "Help search should match article text.")
	help.filter_topics("x_no_help_x")
	check(help.visible_topics.is_empty() and "No matching" in help.article.get_parsed_text(), "Empty help search should explain that no topic matches.")
	var requests: Array[String] = []
	panel.help_requested = func(context): requests.append(context)
	panel.filter_rows("photo replay duration")
	var replay_row := panel.find_child("Setting_replay_seconds", true, false)
	var help_button := replay_row.find_child("SettingHelp", true, false) as Button
	help_button.pressed.emit()
	check(requests == ["replay_seconds"], "Help button should keep the setting context after search reparenting.")
	check(panel.tabs.current_tab == panel.search_index, "Help should preserve the settings search page.")
	print("Release help coverage: %d settings, %d topic entries, %d failures." % [settings.catalog.size(), help.topics.size(), failures])
	quit(1 if failures else 0)
