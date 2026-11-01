# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Base for every Forkline test file. Start a test file with:
##     extends "res://tests/base_test.gd"
## The runner calls each method whose name starts with "test_" on a fresh
## instance, with before_each() before it and after_each() after it.

## Messages from failed checks in the current test. The runner reads this.
var failures: PackedStringArray = PackedStringArray()


## Override to build fixtures. Runs before every test method.
func before_each() -> void:
	pass


## Override to clean up. Runs after every test method.
func after_each() -> void:
	pass


## Marks the current test as failed.
func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail(_with_context("expected true, got false", message))


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail(_with_context("expected false, got true", message))


## Passes when both values have the same type and are equal. An int and a
## float with the same numeric value also count as equal.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _values_equal(actual, expected):
		fail(_with_context("expected %s, got %s" % [_describe(expected), _describe(actual)], message))


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if _values_equal(actual, unexpected):
		fail(_with_context("expected anything but %s" % _describe(unexpected), message))


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail(_with_context("expected null, got %s" % _describe(value), message))


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail(_with_context("expected a value, got null", message))


## Passes when two numbers are within tolerance of each other.
func assert_near(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail(_with_context("expected %s within %s, got %s" % [expected, tolerance, actual], message))


func _values_equal(a: Variant, b: Variant) -> bool:
	var type_a: int = typeof(a)
	var type_b: int = typeof(b)
	if type_a == type_b:
		return a == b
	var a_is_number: bool = type_a == TYPE_INT or type_a == TYPE_FLOAT
	var b_is_number: bool = type_b == TYPE_INT or type_b == TYPE_FLOAT
	if a_is_number and b_is_number:
		return float(a) == float(b)
	return false


func _describe(value: Variant) -> String:
	return "%s (%s)" % [str(value), type_string(typeof(value))]


func _with_context(detail: String, message: String) -> String:
	if message.is_empty():
		return detail
	return "%s: %s" % [message, detail]
