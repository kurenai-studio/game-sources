@tool
extends EditorScript

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

const LINK_PLAIN_TEMPLATE = "[%s]"
const LINK_TEMPLATE = "[{1}]({0})"

const SUPER_SECTION_TEMPLATE = "# %s\n\n"
const SECTION_TEMPLATE = "## %s\n\n"
const SUB_SECTION_TEMPLATE = "### %s\n\n"

const ENTRY_LINK_EMPTY_TEMPLATE = "- {link}\n"
const ENTRY_LINK_TEMPLATE = "- [{0}]({1})\n"

const FROM_TEMPLATE = "* From {0} by {1}:\n"
const FILE_TEMPLATE = "\t- [`{0}`]({0})\n"


func _build_header(template: String, entry: Dictionary, output_file: FileAccess):
	if entry.has(TITLE_ATTRIBUTE_NAME):
		var title = entry[TITLE_ATTRIBUTE_NAME] as String
		var url := ""
		if entry.has(URL_ATTRIBUTE_NAME):
			url = entry[URL_ATTRIBUTE_NAME] as String
#
		if not url.is_empty():
			title = LINK_TEMPLATE.format([url, title])

		output_file.store_string(template % title)


func _build_element(data: Dictionary, output_file: FileAccess):
	if data.has(LINK_ATTRIBUTE_NAME):
		output_file.store_string(ENTRY_LINK_EMPTY_TEMPLATE.format(data))
	elif data.has(TEXT_ATTRIBUTE_NAME):
		# Just use the plain text data.
		output_file.store_string(data[TEXT_ATTRIBUTE_NAME] + "\n\n")
	elif data.has(SOURCE_ATTRIBUTE_NAME):
		var path = "res://" + data[SOURCE_ATTRIBUTE_NAME]
		if not FileAccess.file_exists(path):
			return
		var source := FileAccess.get_file_as_string(path)
		# Just use the plain text data.
		output_file.store_string(source + "\n")
	elif data.has(FILES_ATTRIBUTE_NAME):
		# Should have at least from and author.
		if not data.has_all([ FROM_ATTRIBUTE_NAME, AUTHOR_ATTRIBUTE_NAME ]):
			return

		var from = data[FROM_ATTRIBUTE_NAME]
		var author = data[AUTHOR_ATTRIBUTE_NAME]

		if data.has(FROM_URL_ATTRIBUTE_NAME):
			var url = data[FROM_URL_ATTRIBUTE_NAME]
			from = LINK_TEMPLATE.format([url, from])

		if data.has(AUTHOR_URL_ATTRIBUTE_NAME):
			var url = data[AUTHOR_URL_ATTRIBUTE_NAME]
			author = LINK_TEMPLATE.format([url, author])

		var entry = FROM_TEMPLATE.format([from, author])

		output_file.store_string(entry)

		var body := ""
		for file: String in data[FILES_ATTRIBUTE_NAME] as Array:
			body += FILE_TEMPLATE.format([file])

		output_file.store_string(body)
		output_file.store_string("\n")
#
	else:
		print("Rest: ", data)


func _build_sub_section(data: Array, output_file: FileAccess):
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			_build_header(SUB_SECTION_TEMPLATE, entry, output_file)
			for element in entry[ELEMENTS_ATTRIBUTE_NAME] as Array:
				_build_element(element, output_file)
		else:
			_build_element(entry, output_file)


func _build_section(data: Array, output_file: FileAccess):
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			_build_header(SECTION_TEMPLATE, entry, output_file)
			_build_sub_section(entry[ELEMENTS_ATTRIBUTE_NAME], output_file)
		else:
			_build_element(entry, output_file)


func _build_super_sections(data: Array, output_file: FileAccess):
	for entry in data:
		if entry is not Dictionary:
			# Malformed, skip.
			continue

		if entry.has(ELEMENTS_ATTRIBUTE_NAME):
			_build_header(SUPER_SECTION_TEMPLATE, entry, output_file)
			_build_section(entry[ELEMENTS_ATTRIBUTE_NAME], output_file)
		else:
			_build_element(entry, output_file)


func _run():
	var license_json := FileAccess.get_file_as_string("res://Misc/COPYING.json")
	var license_data = JSON.parse_string(license_json)
	var output_file := "res://COPYING.md"
	var output_file_access := FileAccess.open(output_file, FileAccess.WRITE)

	if not output_file_access or not output_file_access.is_open():
		# Failed to open file.
		return

	if license_data is Array:
		_build_super_sections(license_data, output_file_access)
