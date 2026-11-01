class_name SocialFixtures
extends RefCounted
## Canned answers shaped like the social endpoints, for the social tests.


static func profile(name: Variant = "Marlo", opted: bool = true) -> Dictionary:
	return {
		"displayName": name,
		"leaderboardOptIn": opted,
		"hideName": false,
		"publicId": "p-1",
		"total": 120,
		"rank": {"name": "Novice", "next": {"name": "Tinkerer", "at": 200}},
	}


static func entry(rank: int, name: String, you: bool = false) -> Dictionary:
	return {"rank": rank, "publicId": "p-%d" % rank, "name": name, "points": 100 - rank, "you": you}


static func day(date: String, slug: String = "daily-elm", version: int = 1) -> Dictionary:
	return {
		"date": date,
		"levelSlug": slug,
		"levelVersion": version,
		"title": "Elm",
		"difficulty": "medium",
		"maxCommands": 13,
		"par": 11,
		"source": "rotation",
	}


static func schedule(server_date: String) -> Dictionary:
	var upcoming: Array = []
	for i in range(1, 4):
		upcoming.append(day(DailyDates.shift(server_date, i), "daily-d%d" % i))
	return {"serverDate": server_date, "today": day(server_date), "upcoming": upcoming}


## A fetcher (see ApiClient.fetch_json) serving the schedule and a valid level for any slug.
static func fetcher(server_date: String, calls: Array) -> Callable:
	return func(path: String) -> Dictionary:
		calls.append(path)
		if path == "daily":
			return AccountFixtures.ok(schedule(server_date))
		if path.begins_with("levels/"):
			var slug := path.trim_prefix("levels/")
			return AccountFixtures.ok(ContentFixtures.served(slug))
		return AccountFixtures.fail(404)
