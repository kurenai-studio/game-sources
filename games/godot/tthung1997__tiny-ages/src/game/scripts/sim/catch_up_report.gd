class_name CatchUpReport
extends RefCounted
## What happened while the player was away, for a "while you were away" summary.

var elapsed_seconds: float = 0.0
var ticks_simulated: int = 0
## Ticks beyond the catch-up cap that were skipped rather than simulated.
var ticks_dropped: int = 0
var journal_entries: Array[JournalEntry] = []
var decisions_opened: Array[PendingDecision] = []


func is_empty() -> bool:
	return journal_entries.is_empty() and decisions_opened.is_empty()
