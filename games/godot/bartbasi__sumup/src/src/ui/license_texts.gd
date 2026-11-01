extends RefCounted
## The license texts the About screen opens (DESIGN_SYSTEM.md 7.14,
## docs/ARCHITECTURE.md section 11 flow 12), as a list of blocks to show:
## - &"game": "Notice" and NOTICE, then "GNU General Public License" and
##   COPYING;
## - &"godot": "Godot Engine license" and Engine.get_license_text(), then
##   "Third party parts" (each part of Engine.get_copyright_info() by name,
##   with "Copyright {line}" and "License: {name}"), then "Android libraries"
##   (the intro and each of Copy.ANDROID_PARTS the same way), then "License texts"
##   (each text of Engine.get_license_info() by name);
## - &"outfit": OFL.txt.
## The files are read at runtime (the export packs them as plain files). A
## file that cannot be read, or reads but does not look like itself (a damaged
## package can give a file of the right length with the wrong contents), shows
## a plain message instead; it never shows garbage and never crashes.
##
## Reflowed for the phone: blank lines split paragraphs; inside a paragraph
## every line break and run of spaces becomes one space; nothing else changes.
## A rule line (three or more of one of -, = or *, and only spaces besides)
## also splits paragraphs and becomes a rule block, drawn as the divider.

const NOTICE_PATH: String = "res://NOTICE"
const COPYING_PATH: String = "res://COPYING"
const OFL_PATH: String = "res://src/design/fonts/OFL.txt"
const IDS: Array[StringName] = [&"game", &"godot", &"outfit"]
## These texts are 2 to 36 KB; anything far larger is not one of them.
const MAX_BYTES: int = 262144
const _BYTE_NUL: int = 0
const _REPLACEMENT_CHAR: int = 0xFFFD

## What each file must begin with and hold to count as itself.
const _CHECKS: Dictionary[String, Array] = {
	NOTICE_PATH: ["SumUp", "Copyright 2026 Play, Inc."],
	COPYING_PATH: ["GNU GENERAL PUBLIC LICENSE", "Version 3, 29 June 2007"],
	OFL_PATH: ["Copyright", "SIL OPEN FONT LICENSE Version 1.1"],
}

## One block of a license view: a heading, a name (a part or license name, in
## the body role), a paragraph, the plain message for a missing text, or a
## rule (a rule line of the source, drawn as the skin's divider).
enum Kind { HEADING, NAME, PARAGRAPH, MISSING, RULE }

## The characters a rule line is made of (DESIGN_SYSTEM.md 7.14).
const RULE_CHARACTERS: String = "-=*"
## The fewest of them that make a rule line.
const RULE_MIN_LENGTH: int = 3

const Copy: GDScript = preload("res://src/ui/screen_copy.gd")

## Runs of ASCII white space, built on first use.
static var _white: RegEx = null


## The blocks of one license view, in order: {"kind": Kind, "text": String}.
## An unknown id gives no blocks.
static func blocks(id: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match id:
		&"game":
			_add(out, Kind.HEADING, Copy.NOTICE_HEADING)
			_add_file(out, NOTICE_PATH)
			_add(out, Kind.HEADING, Copy.GPL_HEADING)
			_add_file(out, COPYING_PATH)
		&"godot":
			_add(out, Kind.HEADING, Copy.GODOT_LICENSE_HEADING)
			_add_paragraphs(out, Engine.get_license_text())
			_add(out, Kind.HEADING, Copy.GODOT_PARTS_HEADING)
			for component: Dictionary in Engine.get_copyright_info():
				_add(out, Kind.NAME, String(component.get("name", "")))
				for part: Dictionary in component.get("parts", []):
					for line: Variant in part.get("copyright", []):
						_add(out, Kind.PARAGRAPH, Copy.PART_COPYRIGHT % String(line))
					_add(out, Kind.PARAGRAPH, Copy.PART_LICENSE % String(part.get("license", "")))
			_add(out, Kind.HEADING, Copy.ANDROID_HEADING)
			_add(out, Kind.PARAGRAPH, Copy.ANDROID_INTRO)
			for library: Dictionary in Copy.ANDROID_PARTS:
				_add(out, Kind.NAME, String(library["name"]))
				_add(out, Kind.PARAGRAPH, Copy.PART_COPYRIGHT % String(library["copyright"]))
				_add(out, Kind.PARAGRAPH, Copy.PART_LICENSE % String(library["license"]))
			_add(out, Kind.HEADING, Copy.GODOT_TEXTS_HEADING)
			var licenses: Dictionary = Engine.get_license_info()
			for license_name: Variant in licenses:
				_add(out, Kind.NAME, String(license_name))
				_add_paragraphs(out, String(licenses[license_name]))
		&"outfit":
			_add_file(out, OFL_PATH)
	return out


## The text of one of the license files when it reads and looks like itself,
## else "".
static func read_license_file(path: String) -> String:
	var check: Array = _CHECKS.get(path, ["", ""])
	return read_checked(path, String(check[0]), String(check[1]))


## The text of the file at path when it reads whole, holds no NUL and no
## broken UTF-8, begins with starts_with (after leading white space) and
## holds contains; else "".
static func read_checked(path: String, starts_with: String, contains: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var length: int = file.get_length()
	if length < 1 or length > MAX_BYTES:
		file.close()
		return ""
	var bytes: PackedByteArray = file.get_buffer(length)
	file.close()
	if bytes.size() != length or bytes.has(_BYTE_NUL):
		return ""
	var text: String = bytes.get_string_from_utf8()
	if text.is_empty() or text.contains(String.chr(_REPLACEMENT_CHAR)):
		return ""
	if not text.strip_edges().begins_with(starts_with) or not text.contains(contains):
		return ""
	return text


## text reflowed: one entry per paragraph, rule lines left out
## (DESIGN_SYSTEM.md 7.14). A rule line still ends the paragraph before it.
static func reflow(text: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for part: String in reflow_parts(text):
		if not part.is_empty():
			out.append(part)
	return out


## text reflowed with its rule lines kept in place: one entry per paragraph,
## and an empty entry for each rule line. Blank lines and rule lines end a
## paragraph; inside one, every line break and run of spaces becomes one
## space.
static func reflow_parts(text: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var lines: PackedStringArray = text.replace("\r\n", "\n").replace("\r", "\n").replace("\t", " ").replace("\f", " ").replace("\v", " ").split("\n")
	var paragraph: PackedStringArray = PackedStringArray()
	for line: String in lines:
		# The words of the line, one space between each (split is native, so
		# this stays fast on the 37 KB of COPYING).
		var words: String = " ".join(line.split(" ", false))
		var rule: bool = is_rule_line(line)
		if words.is_empty() or rule:
			if not paragraph.is_empty():
				out.append(" ".join(paragraph))
				paragraph = PackedStringArray()
			if rule:
				out.append("")
		else:
			paragraph.append(words)
	if not paragraph.is_empty():
		out.append(" ".join(paragraph))
	return out


## True for a rule line: three or more of one character, -, = or *, and
## nothing else but spaces (DESIGN_SYSTEM.md 7.14). "*  6. Disclaimer *" is
## text.
static func is_rule_line(line: String) -> bool:
	var marks: String = line.replace(" ", "").replace("\t", "")
	if marks.length() < RULE_MIN_LENGTH or not RULE_CHARACTERS.contains(marks[0]):
		return false
	return marks == marks[0].repeat(marks.length())


## text with its rule lines taken out, for comparing a view with its source:
## the view draws them as dividers, which hold no text.
static func without_rules(text: String) -> String:
	var kept: PackedStringArray = PackedStringArray()
	for line: String in text.replace("\r\n", "\n").split("\n"):
		kept.append("" if is_rule_line(line) else line)
	return "\n".join(kept)


## text with every run of white space (spaces, tabs, line breaks, ASCII
## only) as one space, and none at either end. Also what tests compare with.
static func squeeze(text: String) -> String:
	if _white == null:
		_white = RegEx.create_from_string("[ \\t\\n\\r\\f\\v]+")
	return _white.sub(text, " ", true).strip_edges()


static func _add_file(out: Array[Dictionary], path: String) -> void:
	var text: String = read_license_file(path)
	if text.is_empty():
		_add(out, Kind.MISSING, Copy.TEXT_MISSING)
	else:
		_add_paragraphs(out, text)


static func _add_paragraphs(out: Array[Dictionary], text: String) -> void:
	for part: String in reflow_parts(text):
		if part.is_empty():
			_add(out, Kind.RULE, "")
		else:
			_add(out, Kind.PARAGRAPH, part)


static func _add(out: Array[Dictionary], kind: Kind, text: String) -> void:
	out.append({"kind": kind, "text": text})
