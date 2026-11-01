extends GutTest
## Runs the shared scoring fixtures of packages/level-contract against the GDScript mirror.


func test_fixtures_are_present() -> void:
	assert_gt(ContractSupport.fixture_names("scoring").size(), 7, "scoring fixtures")


func test_every_fixture_scores_the_same_as_the_typescript_implementation() -> void:
	var failures: Array[String] = []
	for file_name in ContractSupport.fixture_names("scoring"):
		var data: Dictionary = ContractSupport.load_fixture("scoring", file_name)
		var got := Scoring.score_result(data["rules"], data["input"])
		var want: Dictionary = data["expected"]
		for key: String in ["stars", "points", "levelScore"]:
			if int(got[key]) != int(want[key]):
				failures.append("%s: %s is %d, want %d" % [file_name, key, got[key], want[key]])
	assert_eq(failures, [], "scoring fixtures that disagree")


func test_default_rules_are_the_fixture_rules() -> void:
	var data: Dictionary = ContractSupport.load_fixture("scoring", "at-par-with-par-steps.json")
	var rules: Dictionary = data["rules"]
	assert_eq(int(rules["version"]), int(Scoring.DEFAULT_RULES["version"]))
	for difficulty: String in ["easy", "medium", "hard"]:
		assert_eq(int(rules["base"][difficulty]), int(Scoring.DEFAULT_RULES["base"][difficulty]))
	for key: String in ["parFull", "parNear", "nearSlots", "stepsBonus", "firstClear"]:
		assert_eq(int(rules[key]), int(Scoring.DEFAULT_RULES[key]), key)
