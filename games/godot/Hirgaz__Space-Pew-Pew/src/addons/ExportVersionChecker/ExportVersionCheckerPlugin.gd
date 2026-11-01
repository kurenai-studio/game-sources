@tool
extends EditorPlugin

var export_plugin: ExportVersionCheckerPlugin = null


func _enter_tree() -> void:
	export_plugin = ExportVersionCheckerPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null
