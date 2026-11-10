class_name JournalPresenter
extends RefCounted
## The world journal as lines for the panel, newest first. Pure logic, no nodes.


## "Day 12  The Lookout was completed." for the latest `limit` entries (all if limit <= 0).
static func lines(world: WorldState, limit: int = 0) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for index: int in range(world.journal.size() - 1, -1, -1):
		var entry: JournalEntry = world.journal[index]
		result.append(line_for(entry))
		if limit > 0 and result.size() >= limit:
			break
	return result


static func line_for(entry: JournalEntry) -> String:
	return "Day %d  %s" % [entry.day + 1, entry.text]


## The same entries as day numbers and texts, newest first, so a panel can style the day apart.
## `skip` leaves out that many of the newest, so a long journal can be read a page at a time.
static func entries(world: WorldState, limit: int = 0, skip: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in range(world.journal.size() - 1 - maxi(skip, 0), -1, -1):
		var entry: JournalEntry = world.journal[index]
		result.append({"day": entry.day + 1, "text": entry.text})
		if limit > 0 and result.size() >= limit:
			break
	return result
