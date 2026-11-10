class_name AwaySummary
extends RefCounted
## What to tell the player on launch about the time they were away. Null when it was too short or
## nothing happened. Pure logic, no nodes.

## How many of the newest events to list; the rest are counted.
const MAX_LINES: int = 6

var duration_text: String = ""
## Oldest first, so it reads as a story.
var lines: PackedStringArray = PackedStringArray()
var more_count: int = 0
var decisions_waiting: int = 0
var time_was_skipped: bool = false


static func present(
	report: CatchUpReport, world: WorldState, min_seconds: float
) -> AwaySummary:
	if report == null or report.elapsed_seconds < min_seconds:
		return null
	var waiting: int = world.pending.size()
	if report.journal_entries.is_empty() and waiting == 0:
		return null
	var summary: AwaySummary = AwaySummary.new()
	summary.duration_text = describe_duration(report.elapsed_seconds)
	summary.decisions_waiting = waiting
	summary.time_was_skipped = report.ticks_dropped > 0
	var entries: Array[JournalEntry] = report.journal_entries
	var start: int = maxi(entries.size() - MAX_LINES, 0)
	summary.more_count = start
	for index: int in range(start, entries.size()):
		summary.lines.append(entries[index].text)
	return summary


## "a moment", "12 min", "2 h 15 min", "1 day 3 h"...
static func describe_duration(seconds: float) -> String:
	var minutes: int = int(seconds / 60.0)
	if minutes < 1:
		return "a moment"
	if minutes < 60:
		return "%d min" % minutes
	var hours: int = minutes / 60
	if hours < 24:
		var rest: int = minutes % 60
		return "%d h" % hours if rest == 0 else "%d h %d min" % [hours, rest]
	var days: int = hours / 24
	var rest_hours: int = hours % 24
	var day_word: String = "day" if days == 1 else "days"
	return "%d %s" % [days, day_word] if rest_hours == 0 \
			else "%d %s %d h" % [days, day_word, rest_hours]
