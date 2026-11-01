class_name ContentSync
extends RefCounted
## Brings the cached campaign up to date with the API and builds a Campaign from the cache.
##
## `refresh` asks the API for the published campaign tree, then fetches each level whose version
## is not already cached. Every level goes through LevelValidator before it is stored; one that
## fails is reported and the previously cached copy (if any) stays. A failed request changes
## nothing. The result is
## { status, updated, errors } with status one of "updated", "unchanged", "offline", "disabled",
## or "invalid" (the API answered with something the game cannot read).


## The campaign tree from `GET /v1/campaign` as the Campaign loader expects it, plus the levels
## in play order with their served version and par. Returns {} when the shape is wrong.
static func read_catalog(catalog: Variant) -> Dictionary:
	if typeof(catalog) != TYPE_DICTIONARY or typeof(catalog.get("worlds")) != TYPE_ARRAY:
		return {}
	var worlds: Array = []
	var levels: Array = []
	for raw_world: Variant in catalog["worlds"]:
		if typeof(raw_world) != TYPE_DICTIONARY or typeof(raw_world.get("chapters")) != TYPE_ARRAY:
			return {}
		var chapters: Array = []
		for raw_chapter: Variant in raw_world["chapters"]:
			if (
				typeof(raw_chapter) != TYPE_DICTIONARY
				or typeof(raw_chapter.get("levels")) != TYPE_ARRAY
			):
				return {}
			var slugs: Array = []
			for raw_level: Variant in raw_chapter["levels"]:
				if (
					typeof(raw_level) != TYPE_DICTIONARY
					or typeof(raw_level.get("slug")) != TYPE_STRING
				):
					return {}
				var slug: String = raw_level["slug"]
				slugs.append(slug)
				(
					levels
					. append(
						{
							"slug": slug,
							"levelVersion": int(raw_level.get("levelVersion", 0)),
							"par": _read_par(raw_level.get("par")),
						}
					)
				)
			(
				chapters
				. append(
					{
						"id": str(raw_chapter.get("id", "")),
						"title": str(raw_chapter.get("title", "")),
						"levels": slugs,
					}
				)
			)
		(
			worlds
			. append(
				{
					"id": str(raw_world.get("id", "")),
					"title": str(raw_world.get("title", "")),
					"summary": str(raw_world.get("description", "")),
					"chapters": chapters,
				}
			)
		)
	return {"placement": {"worlds": worlds}, "levels": levels}


## `{ commands, steps }` as whole numbers, or {} when the level has no par.
static func _read_par(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or not raw.has("commands"):
		return {}
	return {"commands": int(raw["commands"]), "steps": int(raw.get("steps", 0))}


## Fetches what is new. `fetch` is a Callable(path) -> Dictionary (see ApiClient.fetch_json); it
## may be a coroutine. Never throws.
static func refresh(fetch: Callable, store: ContentStore) -> Dictionary:
	var result := {"status": "unchanged", "updated": 0, "errors": []}
	var response: Dictionary = await fetch.call("campaign")
	if not response["ok"]:
		result["status"] = "disabled" if response["error"] == "disabled" else "offline"
		return result
	var catalog := read_catalog(response["json"])
	if catalog.is_empty():
		result["status"] = "invalid"
		return result
	var fetched_any := false
	for item: Dictionary in catalog["levels"]:
		var slug: String = item["slug"]
		var served := int(item["levelVersion"])
		if served > 0 and store.cached_version(slug) == served:
			continue
		var detail: Dictionary = await fetch.call("levels/%s" % slug)
		if not detail["ok"]:
			result["errors"].append("Level %s could not be downloaded." % slug)
			continue
		var problem := store_level(store, slug, detail["json"])
		if problem.is_empty():
			fetched_any = true
			result["updated"] += 1
		else:
			result["errors"].append("Level %s was not saved: %s" % [slug, problem])
	# Compare the normalized catalogs: the cached copy and the new one differ in number types only.
	var previous := read_catalog(store.load_catalog())
	if previous.is_empty() or JSON.stringify(previous) != JSON.stringify(catalog):
		if store.save_catalog(response["json"]):
			fetched_any = true
	if fetched_any:
		result["status"] = "updated"
	return result


## Validates a level response and stores it. Returns "" on success, else why it was refused.
static func store_level(store: ContentStore, slug: String, body: Variant) -> String:
	if typeof(body) != TYPE_DICTIONARY or typeof(body.get("content")) != TYPE_DICTIONARY:
		return "the response was not a level"
	var content: Dictionary = body["content"]
	var check := LevelValidator.validate_level(content)
	if not check["ok"]:
		var first: Dictionary = check["issues"][0] if not check["issues"].is_empty() else {}
		return str(first.get("message", "invalid level"))
	if str(content.get("slug", "")) != slug:
		return "the level names a different slug"
	var saved := (
		store
		. save_level(
			slug,
			{
				"levelVersion": int(body.get("levelVersion", content.get("levelVersion", 0))),
				"schemaVersion": int(body.get("schemaVersion", 1)),
				"par": _read_par(body.get("par")),
				"content": content,
			}
		)
	)
	return "" if saved else "it could not be written to the device"


## The campaign made from what is on the device. Empty (no entries) when nothing is cached.
static func build_campaign(store: ContentStore) -> Campaign:
	var catalog := read_catalog(store.load_catalog())
	if catalog.is_empty():
		return Campaign.new()
	var loader := func(slug: String) -> Variant:
		var record: Variant = store.load_level(slug)
		return record["content"] if record != null else null
	var campaign := Campaign.from_data(catalog["placement"], loader)
	var pars := {}
	for item: Dictionary in catalog["levels"]:
		pars[item["slug"]] = item["par"]
	for entry in campaign.entries:
		entry["par"] = pars.get(entry["id"], {})
	var built := {}
	for world: Dictionary in campaign.worlds:
		built[world["id"]] = true
	for raw: Dictionary in catalog["placement"]["worlds"]:
		if built.has(raw["id"]):
			continue
		var count := 0
		for chapter: Dictionary in raw["chapters"]:
			count += (chapter["levels"] as Array).size()
		if count > 0:
			campaign.pending_worlds.append(
				{"id": raw["id"], "title": raw["title"], "summary": raw["summary"], "count": count}
			)
	return campaign
