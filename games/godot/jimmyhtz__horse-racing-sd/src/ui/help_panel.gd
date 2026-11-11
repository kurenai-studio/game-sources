extends AcceptDialog

const HELP_PATH := "res://docs/help_topics.json"
var topics: Array = []
var visible_topics: Array = []
var navigation: ItemList
var article: RichTextLabel
var search: LineEdit
var selected_id := "quick"

func configure(context: String = "") -> void:
	title = "Horse Racing | SD mode help"
	theme = preload("res://ui/settings_style.gd").make(18)
	size = Vector2i(940, 680)
	min_size = Vector2i(740, 480)
	get_ok_button().text = "Back"
	confirmed.connect(queue_free)
	canceled.connect(queue_free)
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(HELP_PATH))
	if source is Array:
		topics = source
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(700, 400)
	add_child(box)
	search = LineEdit.new()
	search.placeholder_text = "Search help topics and settings"
	search.text_changed.connect(filter_topics)
	box.add_child(search)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(row)
	navigation = ItemList.new()
	navigation.custom_minimum_size.x = 285
	navigation.item_selected.connect(show_topic)
	row.add_child(navigation)
	article = RichTextLabel.new()
	article.name = "HelpArticle"
	article.bbcode_enabled = true
	article.add_theme_color_override("default_color", Color("1b2938"))
	article.add_theme_font_size_override("normal_font_size", 18)
	article.add_theme_font_size_override("bold_font_size", 20)
	article.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	article.selection_enabled = true
	row.add_child(article)
	open_context(context)
	about_to_popup.connect(search.grab_focus)

func topic_for_context(context: String) -> Dictionary:
	# Catalog keys are exact identifiers. Normalize section capitalization only after
	# checking the exact keys so a label cannot shadow a setting's direct context.
	for topic in topics:
		if context in topic.contexts:
			return topic
	for topic in topics:
		for alias in topic.contexts:
			if context.nocasecmp_to(alias) == 0:
				return topic
	return {}

func open_context(context: String) -> void:
	selected_id = str(topic_for_context(context).get("id", "quick"))
	search.text = ""
	filter_topics("")

func filter_topics(query: String) -> void:
	navigation.clear()
	visible_topics.clear()
	var terms := Array(query.strip_edges().to_lower().split(" ", false))
	var selected := 0
	for topic in topics:
		var is_setting: bool = topic.has("category")
		if terms.is_empty() and is_setting and topic.id != selected_id:
			continue
		var searchable := ("%s %s %s %s" % [topic.title, topic.get("category", ""), " ".join(topic.contexts), " ".join(topic.paragraphs)]).to_lower()
		if not terms.is_empty() and terms.any(func(term): return not term in searchable):
			continue
		if topic.id == selected_id:
			selected = visible_topics.size()
		visible_topics.append(topic)
		var caption: String = topic.title
		if topic.get("planned", false):
			caption += " [Planned]"
		navigation.add_item(caption)
		navigation.set_item_tooltip(navigation.item_count - 1, caption)
	if visible_topics.is_empty():
		article.text = "No matching help topics. Try another word." if not topics.is_empty() else "Help content is unavailable."
		return
	navigation.select(selected)
	navigation.ensure_current_is_visible()
	show_topic(selected)

func show_topic(index: int) -> void:
	if index < 0 or index >= visible_topics.size():
		return
	var topic: Dictionary = visible_topics[index]
	selected_id = topic.id
	article.clear()
	article.push_bold()
	article.add_text(topic.title)
	article.pop()
	var section: String = topic.get("category", "")
	article.add_text(("\n" + section if not section.is_empty() else "") + "\n\n" + "\n\n".join(topic.paragraphs))
	article.scroll_to_line(0)
