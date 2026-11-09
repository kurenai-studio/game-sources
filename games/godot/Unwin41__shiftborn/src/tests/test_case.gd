class_name TestCase
extends RefCounted
## Base class for unit tests run by res://tests/run_tests.gd.
## Each method starting with `test_` is one test. A test fails if any
## assertion inside it fails.

var failures: PackedStringArray = []


func assert_true(condition: bool, message: String = "expected true") -> void:
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String = "expected false") -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s expected <%s> got <%s>" % [message, expected, actual])


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s expected ~<%s> got <%s>" % [message, expected, actual])
