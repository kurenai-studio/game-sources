extends GutTest
## Syncing from the API (a fake fetcher, no network) and the campaign built from the cache.

const DIR := "user://test_content_sync"

var _store: ContentStore


func before_each() -> void:
	_store = ContentStore.new(DIR)
	_store.clear()


func after_each() -> void:
	_store.clear()


# ---- reading the catalog ----


func test_catalog_becomes_placement_by_slug() -> void:
	var parsed := ContentSync.read_catalog(ContentFixtures.catalog({"one": 1, "two": 4}))
	var chapter: Dictionary = parsed["placement"]["worlds"][0]["chapters"][0]
	assert_eq(chapter["levels"], ["one", "two"])
	assert_eq(parsed["placement"]["worlds"][0]["summary"], "About it")
	assert_eq(parsed["levels"][1]["levelVersion"], 4)


func test_malformed_catalogs_are_rejected() -> void:
	assert_eq(ContentSync.read_catalog(null), {})
	assert_eq(ContentSync.read_catalog({"worlds": "x"}), {})
	assert_eq(ContentSync.read_catalog({"worlds": [{"chapters": [{"levels": [{"id": 1}]}]}]}), {})


# ---- refreshing ----


func test_first_refresh_downloads_every_level() -> void:
	var calls: Array = []
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1, "two": 1}),
		"levels/one": ContentFixtures.served("one"),
		"levels/two": ContentFixtures.served("two"),
	}
	var result: Dictionary = await ContentSync.refresh(
		ContentFixtures.fetcher(routes, calls), _store
	)
	assert_eq(result["status"], "updated")
	assert_eq(result["updated"], 2)
	assert_eq(result["errors"], [])
	assert_eq(_store.cached_version("two"), 1)


func test_second_refresh_fetches_only_what_changed() -> void:
	var calls: Array = []
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1, "two": 1}),
		"levels/one": ContentFixtures.served("one"),
		"levels/two": ContentFixtures.served("two"),
	}
	await ContentSync.refresh(ContentFixtures.fetcher(routes, calls), _store)
	calls.clear()
	var again: Dictionary = await ContentSync.refresh(
		ContentFixtures.fetcher(routes, calls), _store
	)
	assert_eq(again["status"], "unchanged")
	assert_eq(calls, ["campaign"], "nothing is downloaded twice")
	routes["campaign"] = ContentFixtures.catalog({"one": 1, "two": 2})
	routes["levels/two"] = ContentFixtures.served("two", 2)
	calls.clear()
	var third: Dictionary = await ContentSync.refresh(
		ContentFixtures.fetcher(routes, calls), _store
	)
	assert_eq(third["status"], "updated")
	assert_eq(calls, ["campaign", "levels/two"])
	assert_eq(_store.cached_version("two"), 2)


func test_offline_refresh_keeps_the_cache() -> void:
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1}), "levels/one": ContentFixtures.served("one")
	}
	await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	var result: Dictionary = await ContentSync.refresh(ContentFixtures.offline([]), _store)
	assert_eq(result["status"], "offline")
	assert_eq(_store.cached_version("one"), 1)


func test_disabled_api_reports_disabled() -> void:
	var fetch := func(_path: String) -> Dictionary:
		return {"ok": false, "status": 0, "json": null, "error": "disabled"}
	var result: Dictionary = await ContentSync.refresh(fetch, _store)
	assert_eq(result["status"], "disabled")


func test_unreadable_catalog_changes_nothing() -> void:
	var result: Dictionary = await ContentSync.refresh(
		ContentFixtures.fetcher({"campaign": {"worlds": "nope"}}, []), _store
	)
	assert_eq(result["status"], "invalid")
	assert_null(_store.load_catalog())


func test_invalid_level_is_reported_and_never_replaces_a_good_copy() -> void:
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1}), "levels/one": ContentFixtures.served("one")
	}
	await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	var broken := ContentFixtures.served("one", 2)
	broken["content"]["board"]["width"] = 99
	routes["campaign"] = ContentFixtures.catalog({"one": 2})
	routes["levels/one"] = broken
	var result: Dictionary = await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	assert_eq(result["errors"].size(), 1)
	assert_eq(_store.cached_version("one"), 1, "the good copy stays")
	assert_eq(_store.load_level("one")["content"]["board"]["width"], 5)


func test_level_naming_another_slug_is_refused() -> void:
	var wrong := ContentFixtures.served("one")
	wrong["content"]["slug"] = "other"
	var routes := {"campaign": ContentFixtures.catalog({"one": 1}), "levels/one": wrong}
	var result: Dictionary = await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	assert_eq(result["errors"].size(), 1)
	assert_null(_store.load_level("one"))


func test_level_that_cannot_be_downloaded_is_reported() -> void:
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1, "two": 1}),
		"levels/two": ContentFixtures.served("two")
	}
	var result: Dictionary = await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	assert_eq(result["errors"].size(), 1)
	assert_eq(_store.cached_version("two"), 1)


# ---- the campaign from the cache ----


func test_campaign_is_built_from_the_cache_in_catalog_order() -> void:
	var routes := {
		"campaign": ContentFixtures.catalog({"two": 1, "one": 1}),
		"levels/one": ContentFixtures.served("one"),
		"levels/two": ContentFixtures.served("two"),
	}
	await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	var campaign := ContentSync.build_campaign(_store)
	assert_eq(campaign.errors, [])
	assert_eq(campaign.entries[0]["id"], "two")
	assert_eq(campaign.entries[1]["number"], 2)
	assert_eq(campaign.worlds[0]["summary"], "About it")
	assert_eq(campaign.entries[0]["par"]["commands"], 3)


func test_empty_cache_builds_an_empty_campaign() -> void:
	assert_eq(ContentSync.build_campaign(_store).entries.size(), 0)


func test_level_needing_a_newer_game_is_skipped_but_known_mechanics_play() -> void:
	var future := ContentFixtures.served("two")
	future["content"]["requires"]["mechanics"] = ["move", "loop"]
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1, "two": 1}),
		"levels/one": ContentFixtures.served("one"),
		"levels/two": future,
	}
	await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	var campaign := ContentSync.build_campaign(_store)
	assert_eq(campaign.entries.size(), 1, "the level with an unknown mechanic is left out")
	assert_eq(campaign.errors.size(), 1)


func test_app_state_prefers_downloaded_levels_and_falls_back() -> void:
	var bundled := Campaign.from_data(
		{
			"worlds":
			[{"id": "b", "title": "B", "chapters": [{"id": "c", "title": "C", "levels": ["b1"]}]}]
		},
		func(id: String) -> Variant: return ContentFixtures.level(id)
	)
	var progress := ProgressStore.new("user://test_content_progress.json")
	var state := AppState.new(bundled, progress, _store)
	assert_eq(state.source, "bundled")
	var routes := {
		"campaign": ContentFixtures.catalog({"one": 1}), "levels/one": ContentFixtures.served("one")
	}
	await ContentSync.refresh(ContentFixtures.fetcher(routes, []), _store)
	state = AppState.new(bundled, progress, _store)
	assert_eq(state.source, "downloaded")
	assert_eq(state.campaign.entries[0]["id"], "one")
