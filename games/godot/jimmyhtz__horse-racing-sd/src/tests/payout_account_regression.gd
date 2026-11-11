extends "res://tests/run_tests.gd"
## Reuse the established account and recovery checks without rerunning race simulations.
func _initialize() -> void:
	test_accounts()
	test_persistence()
	finish()
