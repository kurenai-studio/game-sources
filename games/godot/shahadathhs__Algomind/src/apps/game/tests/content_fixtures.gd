class_name ContentFixtures
extends RefCounted
## Builders shared by the content tests: levels, catalogs, and a fake API.


static func level(slug: String, version: int = 1) -> Dictionary:
	return {
		"schemaVersion": 1,
		"levelId": "id-%s" % slug,
		"levelVersion": version,
		"slug": slug,
		"title": slug.capitalize(),
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": ["move", "turn"]},
		"board": {"width": 5, "height": 5, "walls": []},
		"initialState": {"position": [0, 4], "direction": "north"},
		"availableCommands": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
		"constraints": {"maxCommands": 8, "maxSteps": 20},
		"goal": {"type": "reach_tile", "position": [0, 0]},
		"hints": [],
	}


static func catalog(versions: Dictionary) -> Dictionary:
	var levels: Array = []
	for slug: String in versions:
		(
			levels
			. append(
				{
					"id": "id-%s" % slug,
					"slug": slug,
					"title": slug,
					"levelVersion": versions[slug],
					"par": {"commands": 3, "steps": 3},
				}
			)
		)
	return {
		"worlds":
		[
			{
				"id": "w1",
				"title": "World",
				"description": "About it",
				"order": 0,
				"chapters": [{"id": "c1", "title": "Chapter", "order": 0, "levels": levels}],
			}
		]
	}


static func fetcher(routes: Dictionary, calls: Array) -> Callable:
	return func(path: String) -> Dictionary:
		calls.append(path)
		if routes.has(path):
			return {"ok": true, "status": 200, "json": routes[path], "error": ""}
		return {"ok": false, "status": 404, "json": null, "error": "http"}


static func offline(calls: Array) -> Callable:
	return func(path: String) -> Dictionary:
		calls.append(path)
		return {"ok": false, "status": 0, "json": null, "error": "offline"}


static func served(slug: String, version: int = 1) -> Dictionary:
	return {
		"id": "id-%s" % slug,
		"slug": slug,
		"schemaVersion": 1,
		"levelVersion": version,
		"par": {"commands": 3, "steps": 3},
		"publishedAt": "2026-01-01T00:00:00.000Z",
		"content": level(slug, version),
	}
