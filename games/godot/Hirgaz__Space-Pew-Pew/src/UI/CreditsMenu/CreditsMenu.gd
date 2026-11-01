extends Control


signal close_pressed()


const TITLE_ATTRIBUTE_NAME = "title"
const URL_ATTRIBUTE_NAME = "url"
const LINK_ATTRIBUTE_NAME = "link"
const TEXT_ATTRIBUTE_NAME = "text"
const ELEMENTS_ATTRIBUTE_NAME = "elements"
const FILES_ATTRIBUTE_NAME = "files"
const FROM_ATTRIBUTE_NAME = "from"
const FROM_URL_ATTRIBUTE_NAME = "from_url"
const AUTHOR_ATTRIBUTE_NAME = "author"
const AUTHOR_URL_ATTRIBUTE_NAME = "author_url"
const SOURCE_ATTRIBUTE_NAME = "source"
const TRANSLATE_ATTRIBUTE_NAME = "translate"
const TRANSLATE_FROM_ATTRIBUTE_NAME = "translate_from"
const TRANSLATE_AUTHOR_ATTRIBUTE_NAME = "translate_author"

const BODY_PRE = "[font_size=18]\n"
const BODY_POST = "[/font_size]\n"

const LINK_PLAIN_TEMPLATE = "[url]{0}[/url]"
const LINK_TEMPLATE = "[url={0}]{1}[/url]"

const SUPER_SECTION_TEMPLATE = "[font_size=32][center]{0}[/center][/font_size]\n[hr]\n"
const SECTION_TEMPLATE = "[font_size=24][center]{0}[/center][/font_size]\n[hr]\n"
const SUB_SECTION_TEMPLATE = "[font_size=20][center]{0}[/center][/font_size]\n[hr]\n"

const ENTRY_LINK_EMPTY_TEMPLATE = "[ul bullet=-][url]{0}[/url][/ul]\n"
const ENTRY_LINK_TEMPLATE = "[ul bullet=-][url={0}]{1}[/url][/ul]\n"

const FROM_TEMPLATE = "From {0} by {1}:"
const FILE_TEMPLATE = "[ul bullet=-][code]res://{0}[/code][/ul]"


@onready var game_credits_label := %GameCreditsRichTextLabel

@onready var license_option_button := %LicenseOptionButton
@onready var engine_credits_label := %EngineCreditsRichTextLabel

@onready var close_button := %CloseButton


func _ready() -> void:
	_fill_credits()
	_fill_license_options()


func _build_header(template: String, entry: Dictionary) -> String:
	if entry.has(TITLE_ATTRIBUTE_NAME):
		var title = entry[TITLE_ATTRIBUTE_NAME] as String

		if entry.get(TRANSLATE_ATTRIBUTE_NAME, false):
			title = tr(title, &"Credits")

		var url := ""
		if entry.has(URL_ATTRIBUTE_NAME):
			url = entry[URL_ATTRIBUTE_NAME] as String

		if not url.is_empty():
			title = LINK_TEMPLATE.format([url, title])

		return template.format([title])

	return ""


func _build_element(data: Dictionary) -> String:
	if data.has(LINK_ATTRIBUTE_NAME):
		return BODY_PRE + ENTRY_LINK_EMPTY_TEMPLATE.format([data[LINK_ATTRIBUTE_NAME]]) + BODY_POST
	elif data.has(TEXT_ATTRIBUTE_NAME):
		var body := data[TEXT_ATTRIBUTE_NAME] as String

		if data.get(TRANSLATE_ATTRIBUTE_NAME, false):
			body = tr(body, &"Credits")

		return BODY_PRE + body + BODY_POST
	elif data.has(SOURCE_ATTRIBUTE_NAME):
		var path = "res://" + data[SOURCE_ATTRIBUTE_NAME]
		if not FileAccess.file_exists(path):
			return ""

		var source := FileAccess.get_file_as_string(path)

		if data.get(TRANSLATE_ATTRIBUTE_NAME, false):
			source = tr(source, &"Credits")

		return BODY_PRE + source + BODY_POST
	elif data.has(FILES_ATTRIBUTE_NAME):
		# Should have at least from and author.
		if not data.has_all([ FROM_ATTRIBUTE_NAME, AUTHOR_ATTRIBUTE_NAME ]):
			return ""

		var from = data[FROM_ATTRIBUTE_NAME]

		if data.get(TRANSLATE_FROM_ATTRIBUTE_NAME, false):
			from = tr(from, &"Credits")

		var author = data[AUTHOR_ATTRIBUTE_NAME]

		if data.get(TRANSLATE_AUTHOR_ATTRIBUTE_NAME, false):
			author = tr(author, &"Credits")

		if data.has(FROM_URL_ATTRIBUTE_NAME):
			var url = data[FROM_URL_ATTRIBUTE_NAME]
			from = LINK_TEMPLATE.format([url, from])

		if data.has(AUTHOR_URL_ATTRIBUTE_NAME):
			var url = data[AUTHOR_URL_ATTRIBUTE_NAME]
			author = LINK_TEMPLATE.format([url, author])

		var entry = tr(FROM_TEMPLATE, &"Credits").format([from, author])

		var body := ""
		for file: String in data[FILES_ATTRIBUTE_NAME] as Array:
			body += FILE_TEMPLATE.format([file])

		return BODY_PRE + "[ul]" + entry + body + "\n[/ul]\n" + BODY_POST

	else:
		#print("Rest: ", data)
		return ""


func _build_sub_section(data: Array) -> String:
	var ret := ""
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			ret += _build_header(SUB_SECTION_TEMPLATE, entry)
			for element in entry[ELEMENTS_ATTRIBUTE_NAME] as Array:
				ret += _build_element(element)
		else:
			ret += _build_element(entry)

	return ret


func _build_section(data: Array) -> String:
	var ret := ""
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			ret += _build_header(SECTION_TEMPLATE, entry)
			ret += _build_sub_section(entry[ELEMENTS_ATTRIBUTE_NAME])
		else:
			ret += _build_element(entry)

	return ret


func _build_super_sections(data: Array) -> String:
	var ret := ""
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			ret += _build_header(SUPER_SECTION_TEMPLATE, entry)
			ret += _build_section(entry[ELEMENTS_ATTRIBUTE_NAME])
		else:
			ret += _build_element(entry)

	return ret


func _parse_license() -> String:
	var license_json := FileAccess.get_file_as_string("res://Misc/COPYING.json")
	var license_data = JSON.parse_string(license_json)

	if license_data is not Array:
		return ""

	return _build_super_sections(license_data)


func _fill_credits() -> void:
	game_credits_label.text = _parse_license()


func _fill_credits_option(index: int) -> void:
	var license_info_array : Array[Dictionary] = Engine.get_copyright_info()
	if index >= license_info_array.size():
		# Out of range
		return

	var license_info : Dictionary = license_info_array[index]
	var license_parts : Array = license_info["parts"]

	# TODO: Add some proper entry for "public-domain".

	# TODO: Handle links in the entries.

	# TODO: Handle multi-license cases by grouping licenses better.
	var combined_license_regex := RegEx.create_from_string( \
			"((?<name_1>.+) (and|or) (?<name_2>.+) (and|or) (?<name_3>.+) (and|or) (?<name_4>.+) (and|or) (?<name_5>.+))|" + \
			"((?<name_1>.+) (and|or) (?<name_2>.+) (and|or) (?<name_3>.+) (and|or) (?<name_4>.+))|" + \
			"((?<name_1>.+) (and|or) (?<name_2>.+) (and|or) (?<name_3>.+))|" + \
			"((?<name_1>.+) (and|or) (?<name_2>.+))")

	var licenses := {}

	# Helper function to add entries.
	var add_entries := func (license: String, copyright: Array) -> void:
		var authors : Array = licenses.get_or_add(license, [])
		for author: String in copyright:
			if not authors.has(author):
				authors.push_back(author)

	for part: Dictionary in license_parts:
		var license : String = part["license"]
		var check_combined := combined_license_regex.search(license)
		if check_combined:
			var name_1 := check_combined.get_string("name_1")
			var name_2 := check_combined.get_string("name_2")
			var name_3 := check_combined.get_string("name_3")
			var name_4 := check_combined.get_string("name_4")
			var name_5 := check_combined.get_string("name_5")
			add_entries.call(name_1, part["copyright"])
			add_entries.call(name_2, part["copyright"])
			if name_3:
				add_entries.call(name_3, part["copyright"])
			if name_4:
				add_entries.call(name_4, part["copyright"])
			if name_5:
				add_entries.call(name_5, part["copyright"])
		else:
			add_entries.call(license, part["copyright"])

	var license_string : String = ""

	for license: String in licenses.keys():
		license_string += "[font_size=20]" + license + "[/font_size]\n"
		license_string += "\n[hr]\n\n"
		var authors : Array = licenses[license]
		for author: String in authors:
			license_string += "[indent]" + author + "[/indent]\n"
		license_string += "\n[hr]\n\n"
		license_string += Engine.get_license_info().get(license, "N/A") + "\n\n"

	engine_credits_label.text = license_string


func _fill_license_options() -> void:
	for entry in Engine.get_copyright_info():
		license_option_button.add_item(entry["name"])
	# Fill first entry automatically.
	_fill_credits_option(0)


func _on_license_option_button_item_selected(index: int) -> void:
	_fill_credits_option(index)


func _on_credits_rich_text_label_meta_clicked(meta: Variant) -> void:
	# Open directly with shell.
	OS.shell_open(meta)


func _on_close_button_pressed() -> void:
	close_pressed.emit()


func _on_visibility_changed() -> void:
	if visible:
		close_button.grab_focus()
