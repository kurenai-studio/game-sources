@tool
extends EditorTranslationParserPlugin


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


var result : Array[PackedStringArray]


func _process_header(entry: Dictionary) -> void:
	if entry.has(TITLE_ATTRIBUTE_NAME):
		if not entry.get(TRANSLATE_ATTRIBUTE_NAME, false):
			return

		var title := entry[TITLE_ATTRIBUTE_NAME] as String

		print_verbose("Credits Translator: Header: \"", title, "\"")
		result.push_back(PackedStringArray([title, "Credits"]))


func _process_element(data: Dictionary) -> void:
	if data.has(LINK_ATTRIBUTE_NAME):
		pass
	elif data.has(TEXT_ATTRIBUTE_NAME):
		if not data.get(TRANSLATE_ATTRIBUTE_NAME, false):
			return

		var text := data[TEXT_ATTRIBUTE_NAME] as String

		print_verbose("Credits Translator: Element Text: \"", text, "\"")
		result.push_back(PackedStringArray([text, "Credits"]))
	elif data.has(SOURCE_ATTRIBUTE_NAME):
		if not data.get(TRANSLATE_ATTRIBUTE_NAME, false):
			return

		var path = "res://" + data[SOURCE_ATTRIBUTE_NAME]
		if not FileAccess.file_exists(path):
			return

		var source := FileAccess.get_file_as_string(path)

		print_verbose("Credits Translator: Element Source: \"", source, "\"")
		result.push_back(PackedStringArray([source, "Credits"]))
	elif data.has(FILES_ATTRIBUTE_NAME):
		# Should have at least from and author.
		if not data.has_all([ FROM_ATTRIBUTE_NAME, AUTHOR_ATTRIBUTE_NAME ]):
			return

		if data.get(TRANSLATE_FROM_ATTRIBUTE_NAME, false):
			var from = data[FROM_ATTRIBUTE_NAME]
			print_verbose("Credits Translator: Element From: \"", from, "\"")
			result.push_back(PackedStringArray([from, "Credits"]))

		if data.get(TRANSLATE_AUTHOR_ATTRIBUTE_NAME, false):
			var author = data[AUTHOR_ATTRIBUTE_NAME]

			print_verbose("Credits Translator: Element Author: \"", author, "\"")
			result.push_back(PackedStringArray([author, "Credits"]))
	else:
		pass


func _process_sub_section(data: Array) -> void:
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			_process_header(entry)
			for element in entry[ELEMENTS_ATTRIBUTE_NAME] as Array:
				_process_element(element)
		else:
			_process_element(entry)


func _process_section(data: Array) -> void:
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			_process_header(entry)
			_process_sub_section(entry[ELEMENTS_ATTRIBUTE_NAME])
		else:
			_process_element(entry)


func _process_super_sections(data: Array) -> void:
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			_process_header(entry)
			_process_section(entry[ELEMENTS_ATTRIBUTE_NAME])
		else:
			_process_element(entry)


func _parse_file(path: String) -> Array[PackedStringArray]:
	var license_json := FileAccess.get_file_as_string(path)
	var license_data = JSON.parse_string(license_json)

	result = []

	if license_data is Array:
		_process_super_sections(license_data)

	return result


func _get_recognized_extensions() -> PackedStringArray:
	return ["json"]
