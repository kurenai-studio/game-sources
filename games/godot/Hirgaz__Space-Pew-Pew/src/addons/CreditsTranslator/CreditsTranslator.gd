@tool
extends EditorPlugin


const CreditsTranslationPlugin = preload("res://addons/CreditsTranslator/CreditsTranslationPlugin.gd")
var credits_translation_plugin : CreditsTranslationPlugin

func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass


func _enter_tree() -> void:
	credits_translation_plugin = CreditsTranslationPlugin.new()
	add_translation_parser_plugin(credits_translation_plugin)


func _exit_tree() -> void:
	remove_translation_parser_plugin(credits_translation_plugin)
	credits_translation_plugin = null
