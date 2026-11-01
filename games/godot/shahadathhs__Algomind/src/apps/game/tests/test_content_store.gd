extends GutTest
## The on-device cache and the API client's pure parts.

const DIR := "user://test_content_store"

var _store: ContentStore


func before_each() -> void:
	_store = ContentStore.new(DIR)
	_store.clear()


func after_each() -> void:
	_store.clear()


# ---- the cache ----


func test_level_round_trips_through_the_cache() -> void:
	assert_true(
		_store.save_level("one", {"levelVersion": 2, "content": ContentFixtures.level("one", 2)})
	)
	assert_eq(_store.cached_version("one"), 2)
	assert_eq(_store.load_level("one")["content"]["slug"], "one")


func test_unknown_level_reads_as_missing() -> void:
	assert_null(_store.load_level("nothing"))
	assert_eq(_store.cached_version("nothing"), 0)


func test_unsafe_names_are_refused() -> void:
	for name in ["../escape", "a/b", "A", "", "-lead", "trail-", "x".repeat(65)]:
		assert_false(_store.save_level(name, {"content": {}}), "name %s" % name)
		assert_null(_store.load_level(name))


func test_damaged_file_reads_as_missing() -> void:
	DirAccess.make_dir_recursive_absolute(DIR + "/levels")
	var file := FileAccess.open(DIR + "/levels/broken.json", FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_null(_store.load_level("broken"))


func test_catalog_round_trips() -> void:
	assert_null(_store.load_catalog())
	assert_true(_store.save_catalog(ContentFixtures.catalog({"one": 1})))
	assert_eq(_store.load_catalog()["worlds"].size(), 1)


# ---- the API client's pure parts ----


func test_only_https_is_accepted_in_release_builds() -> void:
	assert_eq(
		ApiClient.normalize_base_url("https://api.example.com/v1/", false),
		"https://api.example.com/v1"
	)
	assert_eq(ApiClient.normalize_base_url("http://localhost:8000/v1", false), "")
	assert_eq(
		ApiClient.normalize_base_url("http://localhost:8000/v1", true), "http://localhost:8000/v1"
	)
	assert_eq(ApiClient.normalize_base_url("", true), "")
	assert_eq(ApiClient.normalize_base_url("ftp://x", true), "")


func test_http_completions_become_results() -> void:
	var ok := ApiClient.interpret(HTTPRequest.RESULT_SUCCESS, 200, '{"a":1}'.to_utf8_buffer())
	assert_true(ok["ok"])
	assert_eq(ok["json"]["a"], 1)
	assert_eq(
		ApiClient.interpret(HTTPRequest.RESULT_SUCCESS, 404, PackedByteArray())["error"], "http"
	)
	assert_eq(
		ApiClient.interpret(HTTPRequest.RESULT_SUCCESS, 200, "nope".to_utf8_buffer())["error"],
		"parse"
	)
	assert_eq(
		ApiClient.interpret(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray())["error"],
		"offline"
	)
	assert_eq(
		ApiClient.interpret(HTTPRequest.RESULT_TIMEOUT, 0, PackedByteArray())["error"], "timeout"
	)
