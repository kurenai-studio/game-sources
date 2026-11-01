class_name DailyPlay
extends RefCounted
## A daily challenge as the play screen wants it: the same shape as a campaign entry, so the
## screen plays it like any level. The extra key `daily` holds the UTC date. A daily has no
## number, no world, and no next level.


## The entry for the daily of `date` from the device's copy, or {} when it is not saved yet.
static func entry(store: DailyStore, date: String) -> Dictionary:
	var info := store.day(date)
	var saved := store.level(date)
	if info.is_empty() or saved.is_empty():
		return {}
	return {
		"id": str(info["levelSlug"]),
		"number": 0,
		"world": -1,
		"chapter": 0,
		"level": saved["content"],
		"par": saved["par"],
		"daily": date,
	}
