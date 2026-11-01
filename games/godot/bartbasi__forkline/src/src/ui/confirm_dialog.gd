# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name ConfirmDialog
extends Modal
## A question with two answers. The safe answer is the big honey button; the
## other answer is a plain one. The back button cancels.

signal confirmed()
signal cancelled()


func _init(title: String, message: String, confirm_text: String, cancel_text: String = "Cancel") -> void:
	super(title)
	var text: Label = UiKit.label(message)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(text)
	var cancel: TapButton = UiKit.button(cancel_text, &"PrimaryButton")
	cancel.tapped.connect(request_close)
	body.add_child(cancel)
	var confirm: TapButton = UiKit.button(confirm_text)
	confirm.tapped.connect(_confirm)
	body.add_child(confirm)


func request_close() -> void:
	cancelled.emit()
	closed.emit()


## The dialog closes first, so a screen the answer opens is not hidden by it.
func _confirm() -> void:
	closed.emit()
	confirmed.emit()
