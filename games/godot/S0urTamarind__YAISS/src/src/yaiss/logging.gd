extends RefCounted

enum Level { DEBUG, INFO, WARNING, ERROR, FATAL }

static func record(level: Level, msg: String, tags: Array[String] = [], color: Color = Color.WHITE, is_bold: bool = false) -> void:
	var tags_str = ""
	if tags:
		tags_str = "[" + "][".join(tags) + "]"
		
	var datetime = Time.get_datetime_string_from_system(false, true)
	# TODO: This has scope for future enhancement to match Boost.log semantics
	if is_bold:
		print_rich("[b][color=#%s][%s][%s]%s %s[/color][/b]" % [color.to_html(), datetime, Level.find_key(level), tags_str, msg])
	else:
		print_rich("[color=#%s][%s][%s]%s %s[/color]" % [color.to_html(), datetime, Level.find_key(level), tags_str, msg])

static func record_debug(msg: String, tags: Array[String] = []) -> void:
	record(Level.DEBUG, msg, tags, Color.GRAY, false)

static func record_info(msg: String, tags: Array[String] = []) -> void:
	record(Level.INFO, msg, tags, Color.WHITE, false)

static func record_warning(msg: String, tags: Array[String] = []) -> void:
	record(Level.WARNING, msg, tags, Color.YELLOW, false)

static func record_error(msg: String, tags: Array[String] = []) -> void:
	record(Level.ERROR, msg, tags, Color.RED, false)

static func record_fatal(msg: String, tags: Array[String] = []) -> void:
	record(Level.FATAL, msg, tags, Color.RED, true)

		
