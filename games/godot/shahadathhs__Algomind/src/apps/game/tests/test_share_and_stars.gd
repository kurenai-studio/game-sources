extends GutTest
## The share card text and the stars on level tiles.

const PAR := {"commands": 5, "steps": 12}


func test_level_card() -> void:
	var text := ShareCard.level_text(9, "Around the wall", 10, 10)
	assert_eq(text, "Algomind, level 9 Around the wall: 10 commands, par 10.")


func test_daily_card_and_singular() -> void:
	assert_eq(
		ShareCard.daily_text("2026-10-20", 7, 5), "Algomind daily 2026-10-20: 7 commands, par 5."
	)
	assert_eq(ShareCard.daily_text("2026-10-20", 1, 0), "Algomind daily 2026-10-20: 1 command.")


func test_the_link_goes_on_a_following_line_when_there_is_one() -> void:
	var card := ShareCard.daily_text("2026-10-20", 7, 5)
	assert_eq(ShareCard.with_link(card, "https://x.test/s/abc"), card + "\nhttps://x.test/s/abc")
	assert_eq(ShareCard.with_link(card, ""), card)


func test_the_card_has_no_emoji_or_exclamation() -> void:
	var text := ShareCard.level_text(3, "Two corners", 4, 4)
	for i in text.length():
		assert_lt(text.unicode_at(i), 128)
	assert_false(text.contains("!"))


func test_provisional_stars_follow_the_scoring_mirror() -> void:
	assert_eq(LevelStars.provisional(PAR, "easy", 5), 3)
	assert_eq(LevelStars.provisional(PAR, "easy", 4), 3)
	assert_eq(LevelStars.provisional(PAR, "easy", 7), 2)
	assert_eq(LevelStars.provisional(PAR, "easy", 8), 1)
	assert_eq(LevelStars.provisional(PAR, "easy", 0), 0)
	assert_eq(LevelStars.provisional({}, "easy", 5), 0)
	assert_eq(LevelStars.provisional(PAR, "odd", 5), 0)


func test_the_servers_stars_win_over_the_provisional_ones() -> void:
	var progress := ProgressStore.new("user://test_stars_progress.json")
	var entry := {"id": "a", "level": {"difficulty": "easy", "levelVersion": 1}, "par": PAR}
	assert_eq(LevelStars.of(progress, entry), 0, "not solved")
	progress.record_completion("a", 1, 8)
	assert_eq(LevelStars.of(progress, entry), 1)
	progress.results.apply_result("a", {"stars": 2, "points": 20, "total": 20})
	assert_eq(LevelStars.of(progress, entry), 2)
	assert_eq(LevelStars.words(1), "1 star")
	assert_eq(LevelStars.words(3), "3 stars")
