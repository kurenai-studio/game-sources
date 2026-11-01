# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name NoticeDialog
extends Modal
## A short message with one button. The back button closes it too.

var message_label: Label
var ok_button: TapButton


func _init(title: String, message: String) -> void:
	super(title)
	message_label = UiKit.label(message)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(message_label)
	ok_button = UiKit.button("OK", &"PrimaryButton")
	ok_button.tapped.connect(request_close)
	body.add_child(ok_button)
