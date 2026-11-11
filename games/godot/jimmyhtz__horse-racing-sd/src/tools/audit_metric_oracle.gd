extends "res://tools/movement_compare.gd"
# Reuse the original measurement definitions to validate the independent analyzer.
func _initialize() -> void:
	var input := FileAccess.open("res://test-results/algorithm-audit/oracle.jsonl",FileAccess.READ)
	var output := FileAccess.open("res://test-results/algorithm-audit/oracle-metrics.jsonl",FileAccess.WRITE)
	var count := 0
	while input.get_position() < input.get_length():
		var row = JSON.parse_string(input.get_line())
		output.store_line(JSON.stringify({"id":row.id,"metrics":metrics(row.samples,int(row.result.first))}))
		count += 1
	print("METRIC ORACLE: %d" % count)
	quit(0)
