class_name ConfirmDialog extends "res://src/ui/dialog_base.gd"
## A yes or no question (DESIGN_SYSTEM.md 7.4): a title, a muted body, then
## the confirm button (primary) and the cancel button (secondary) side by
## side. Used for New game during a run (D-34). Back cancels.

signal confirmed()
signal cancelled()

var _title: String = ""
var _body: String = ""
var _confirm_text: String = ""
var _cancel_text: String = ""


func setup(skin: SkinData, title: String, body: String, confirm_text: String, cancel_text: String) -> void:
	_title = title
	_body = body
	_confirm_text = confirm_text
	_cancel_text = cancel_text
	_frame(skin)
	var align: HorizontalAlignment = UiParts.block_alignment(skin)
	_content.add_child(UiParts.label(skin, &"TitleLabel", title, align))
	_content.add_child(UiParts.paragraph(skin, &"MutedLabel", body, align))
	var row: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	_content.add_child(row)
	var yes: Button = UiParts.button(skin, &"PrimaryButton", confirm_text)
	yes.name = "Confirm"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(_on_confirm)
	row.add_child(yes)
	var no: Button = UiParts.button(skin, &"SecondaryButton", cancel_text)
	no.name = "Cancel"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_on_cancel)
	row.add_child(no)


## Rebuilds the dialog in a new skin, still open, with the same words.
func apply_skin(skin: SkinData) -> void:
	setup(skin, _title, _body, _confirm_text, _cancel_text)


func _on_confirm() -> void:
	if not _closing:
		confirmed.emit()


func _on_cancel() -> void:
	if not _closing:
		cancelled.emit()
