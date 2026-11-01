class_name ShareCard
extends RefCounted
## The text a player copies to share a result: one plain line, no emoji, no solution, no board.
## "Algomind, level 9 Around the wall: 10 commands, par 10." for a level and
## "Algomind daily 2026-10-20: 7 commands, par 5." for a daily. A link goes on the next line.


static func level_text(number: int, title: String, commands: int, par_commands: int) -> String:
	return "Algomind, level %d %s: %s." % [number, title, _result(commands, par_commands)]


static func daily_text(date: String, commands: int, par_commands: int) -> String:
	return "Algomind daily %s: %s." % [date, _result(commands, par_commands)]


## The card with its link on a following line; the card alone when there is no link.
static func with_link(text: String, url: String) -> String:
	return text if url.is_empty() else "%s\n%s" % [text, url]


static func _result(commands: int, par_commands: int) -> String:
	var line := "%d command%s" % [commands, "" if commands == 1 else "s"]
	if par_commands > 0:
		line += ", par %d" % par_commands
	return line
