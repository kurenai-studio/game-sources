extends SceneTree
## Checks the Google Play store graphics in docs/store/graphics/ against
## Play's rules, reading each PNG's own header (the IHDR chunk), not Godot's
## idea of it. From the repo root:
##     godot --headless --path . --script res://tools/store/store_check.gd
## Prints one line per file and exits with 0 when every file passes, else 1.
##
## The rules:
##   icon_512.png          512 by 512, 8 bit RGBA (32 bit), under 1024 KB
##   feature_1024x500.png  1024 by 500, 8 bit RGB (24 bit, no alpha), under 15 MB
##   phone_*.png           1080 by 1920 (9:16, Play allows up to 2:1), 8 bit
##                         RGB, under 8 MB; at least 4 and at most 8 of them

const FOLDER: String = "res://docs/store/graphics"
const PNG_SIGNATURE: PackedByteArray = [137, 80, 78, 71, 13, 10, 26, 10]
## PNG color types.
const RGB: int = 2
const RGBA: int = 6
const KB: int = 1024
const MIN_PHONE: int = 4
const MAX_PHONE: int = 8


func _init() -> void:
	var failed: int = 0
	var phones: int = 0
	var names: PackedStringArray = DirAccess.get_files_at(FOLDER)
	names.sort()
	for file_name: String in names:
		if file_name.get_extension() != "png":
			print("FAIL %s: not a PNG; only the store graphics belong here" % file_name)
			failed += 1
			continue
		var rule: Dictionary = _rule_for(file_name)
		if rule.is_empty():
			print("FAIL %s: no rule for this name" % file_name)
			failed += 1
			continue
		if file_name.begins_with("phone_"):
			phones += 1
		if not _check(FOLDER.path_join(file_name), rule):
			failed += 1
	for required: String in ["icon_512.png", "feature_1024x500.png"]:
		if not names.has(required):
			print("FAIL %s is missing" % required)
			failed += 1
	if phones < MIN_PHONE or phones > MAX_PHONE:
		print("FAIL %d phone screenshots; Play needs %d to %d" % [phones, MIN_PHONE, MAX_PHONE])
		failed += 1
	else:
		print("PASS %d phone screenshots (Play takes %d to %d)" % [phones, MIN_PHONE, MAX_PHONE])
	print("store check: %s, %d problems." % ["PASS" if failed == 0 else "FAIL", failed])
	quit(0 if failed == 0 else 1)


func _rule_for(file_name: String) -> Dictionary:
	if file_name == "icon_512.png":
		return {"width": 512, "height": 512, "color": RGBA, "max_bytes": 1024 * KB}
	if file_name == "feature_1024x500.png":
		return {"width": 1024, "height": 500, "color": RGB, "max_bytes": 15 * KB * KB}
	if file_name.begins_with("phone_"):
		return {"width": 1080, "height": 1920, "color": RGB, "max_bytes": 8 * KB * KB}
	return {}


func _check(path: String, rule: Dictionary) -> bool:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var file_name: String = path.get_file()
	if bytes.size() < 33 or bytes.slice(0, 8) != PNG_SIGNATURE or bytes.slice(12, 16).get_string_from_ascii() != "IHDR":
		print("FAIL %s: not a PNG file" % file_name)
		return false
	var width: int = _u32(bytes, 16)
	var height: int = _u32(bytes, 20)
	var depth: int = bytes[24]
	var color: int = bytes[25]
	var bits: int = depth * (4 if color == RGBA else 3 if color == RGB else 0)
	var problems: PackedStringArray = PackedStringArray()
	if width != int(rule["width"]) or height != int(rule["height"]):
		problems.append("size %dx%d, wanted %dx%d" % [width, height, rule["width"], rule["height"]])
	if depth != 8 or color != int(rule["color"]):
		problems.append("bit depth %d, color type %d, wanted 8 bit %s" % [depth, color, "RGBA" if int(rule["color"]) == RGBA else "RGB"])
	if bytes.size() >= int(rule["max_bytes"]):
		problems.append("%d bytes, the limit is %d" % [bytes.size(), rule["max_bytes"]])
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.get_width() != width or image.get_height() != height:
		problems.append("Godot cannot read it back")
	var line: String = "%s %dx%d, %d bit %s, %s bytes (%.1f KB)" % [file_name, width, height, bits, "RGBA" if color == RGBA else "RGB", _grouped(bytes.size()), float(bytes.size()) / float(KB)]
	if problems.is_empty():
		print("PASS %s" % line)
		return true
	print("FAIL %s: %s" % [line, "; ".join(problems)])
	return false


static func _u32(bytes: PackedByteArray, at: int) -> int:
	return (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3]


static func _grouped(value: int) -> String:
	var text: String = str(value)
	var out: String = ""
	while text.length() > 3:
		out = "," + text.right(3) + out
		text = text.left(text.length() - 3)
	return text + out
