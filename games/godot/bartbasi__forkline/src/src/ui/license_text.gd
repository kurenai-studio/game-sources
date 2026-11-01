# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name LicenseText
extends RefCounted
## The license texts About shows, read from the files that ship with the app and
## from the engine itself, reflowed for a phone and cut into pieces. A piece is
## a small block of text that becomes one Label, so a long text opens at once
## and scrolls smoothly: the viewer adds the pieces a few at a time.
##
## A piece is {"text": String, "head": bool}. A heading piece names the text
## that follows. A file that cannot be read is replaced by MISSING.

const MISSING: String = "This text could not be read in this copy of Forkline. Installing the app again should bring it back."
const NOTICE_PATH: String = "res://NOTICE"
const LICENSE_PATH: String = "res://LICENSE"
const FONT_LICENSE_PATH: String = "res://src/theme/fonts/OFL.txt"
const MAX_PIECE_CHARS: int = 1200

## The three rows of About.
const FORKLINE: StringName = &"forkline"
const GODOT: StringName = &"godot"
const FONT: StringName = &"font"


## The pieces for one About row: FORKLINE, GODOT or FONT.
static func build(kind: StringName) -> Array[Dictionary]:
	match kind:
		FORKLINE:
			return _forkline()
		GODOT:
			return _godot()
		FONT:
			return _font()
	return []


## Paragraphs of `text`: blank lines end a paragraph, hard line breaks inside a
## paragraph become one space, and indentation is dropped. Every word stays.
static func reflow(text: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var current: PackedStringArray = PackedStringArray()
	var normal: String = text.replace("\r\n", "\n").replace("\r", "\n")
	for raw: String in normal.split("\n"):
		var line: String = raw.strip_edges()
		if line.is_empty():
			if not current.is_empty():
				out.append(" ".join(current))
				current = PackedStringArray()
		else:
			current.append(line)
	if not current.is_empty():
		out.append(" ".join(current))
	return out


## Groups paragraphs into pieces of at most `max_chars`. A paragraph longer than
## that is cut at a space.
static func pieces(paragraphs: PackedStringArray, max_chars: int = MAX_PIECE_CHARS) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var group: String = ""
	for paragraph: String in paragraphs:
		var rest: String = paragraph
		while rest.length() > max_chars:
			var cut: int = rest.rfind(" ", max_chars)
			if cut <= 0:
				cut = max_chars
			if not group.is_empty():
				out.append(group)
				group = ""
			out.append(rest.substr(0, cut))
			rest = rest.substr(cut).strip_edges(true, false)
		if group.is_empty():
			group = rest
		elif group.length() + 2 + rest.length() <= max_chars:
			group += "\n\n" + rest
		else:
			out.append(group)
			group = rest
	if not group.is_empty():
		out.append(group)
	return out


## The whole text of a file, or "" when it cannot be read.
static func read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var text: String = FileAccess.get_file_as_string(path)
	if FileAccess.get_open_error() != OK:
		return ""
	return text


# The rows.

static func _forkline() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_file(out, "Forkline notice", NOTICE_PATH)
	_file(out, "GNU General Public License, version 3", LICENSE_PATH)
	return out


static func _font() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_file(out, "Outfit font", FONT_LICENSE_PATH)
	return out


static func _godot() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_add(out, "Godot Engine", reflow(Engine.get_license_text()))
	_add(out, "Parts of the engine", PackedStringArray([
		"The engine includes these parts. Each one lists its files, its copyright holders and its license. The license texts follow."]))
	for entry: Dictionary in Engine.get_copyright_info():
		_add_part(out, entry)
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: Variant in licenses:
		_add(out, "License: %s" % license_name, reflow(str(licenses[license_name])))
	_add_android(out)
	return out


## The Android libraries the export adds, named in NOTICE.
static func _add_android(out: Array[Dictionary]) -> void:
	var android: PackedStringArray = PackedStringArray()
	for paragraph: String in reflow(read_file(NOTICE_PATH)):
		if paragraph.begins_with("On Android"):
			android.append(paragraph)
	if android.is_empty():
		android.append(MISSING)
	else:
		android.append("The Apache License, version 2.0 is in the list above, under Apache-2.0.")
	_add(out, "Android libraries", android)


static func _add_part(out: Array[Dictionary], entry: Dictionary) -> void:
	var lines: PackedStringArray = PackedStringArray()
	var parts: Array = entry.get("parts", [])
	for part: Dictionary in parts:
		var files: PackedStringArray = PackedStringArray(part.get("files", []))
		var holders: PackedStringArray = PackedStringArray(part.get("copyright", []))
		lines.append("Files: " + ", ".join(files))
		for holder: String in holders:
			lines.append("Copyright " + holder)
		lines.append("License: " + str(part.get("license", "")))
		lines.append("")
	out.append({"text": str(entry.get("name", "")), "head": true})
	for piece: String in pieces(PackedStringArray(["\n".join(lines).strip_edges()])):
		out.append({"text": piece, "head": false})


static func _file(out: Array[Dictionary], heading: String, path: String) -> void:
	var text: String = read_file(path)
	_add(out, heading, reflow(text) if not text.is_empty() else PackedStringArray([MISSING]))


static func _add(out: Array[Dictionary], heading: String, paragraphs: PackedStringArray) -> void:
	out.append({"text": heading, "head": true})
	for piece: String in pieces(paragraphs):
		out.append({"text": piece, "head": false})
