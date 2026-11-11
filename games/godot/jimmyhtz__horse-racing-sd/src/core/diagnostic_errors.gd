extends Logger
var sink: Callable
func _log_error(function: String, file: String, line: int, _code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if sink.is_valid(): sink.call("engine_error",{"function":function,"source":file.get_file(),"line":line,"reason":rationale,"type":error_type})
