extends GutTest
## The account file: round trip, damaged file, sign-out, and the atomic write.

const PATH := "user://test_account.json"


func before_each() -> void:
	_remove()


func after_each() -> void:
	_remove()


func _remove() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func test_a_new_account_is_signed_out() -> void:
	var account := Account.new(PATH)
	account.load_data()
	assert_false(account.signed_in())
	assert_eq(account.email, "")


func test_a_session_survives_a_restart() -> void:
	var account := Account.new(PATH)
	account.start("a@example.com", "refresh-1")
	account.last_sync_at = 123.5
	account.save()
	var again := Account.new(PATH)
	again.load_data()
	assert_true(again.signed_in())
	assert_eq(again.email, "a@example.com")
	assert_eq(again.refresh_token, "refresh-1")
	assert_eq(again.last_sync_at, 123.5)


func test_a_damaged_file_means_signed_out_not_a_crash() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var account := Account.new(PATH)
	account.load_data()
	assert_false(account.signed_in())


func test_a_file_with_the_wrong_shape_means_signed_out() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string('{"email": 5, "refreshToken": ["x"]}')
	file.close()
	var account := Account.new(PATH)
	account.load_data()
	assert_false(account.signed_in())


func test_a_damaged_file_falls_back_to_the_last_good_copy() -> void:
	var account := Account.new(PATH)
	account.start("a@example.com", "refresh-1")
	account.save()  # a second save, so the first is kept as the backup
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var again := Account.new(PATH)
	again.load_data()
	assert_true(again.signed_in(), "the session is not lost to a damaged file")
	assert_eq(again.refresh_token, "refresh-1")


func test_clearing_forgets_the_session_on_disk_too() -> void:
	var account := Account.new(PATH)
	account.start("a@example.com", "refresh-1")
	account.clear()
	var again := Account.new(PATH)
	again.load_data()
	assert_false(again.signed_in())


func test_saving_leaves_no_temporary_file() -> void:
	var account := Account.new(PATH)
	account.start("a@example.com", "refresh-1")
	assert_false(FileAccess.file_exists(PATH + ".tmp"))
