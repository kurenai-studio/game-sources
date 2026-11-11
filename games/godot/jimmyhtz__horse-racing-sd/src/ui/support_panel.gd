extends VBoxContainer
const SUPPORT_QR := preload("res://assets/support-paypal.svg")
var configuration: Dictionary={}

func _ready() -> void:
	var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://data/support.json"))
	if parsed is Dictionary: configuration=parsed
	var title:=Label.new(); title.text="Optional support"; title.add_theme_font_size_override("font_size",23); add_child(title)
	var note:=Label.new(); note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	note.text="Help with the costs of making the game. Entirely optional, with no effect on game access, credits or race results."
	add_child(note)
	var amounts:=HBoxContainer.new(); amounts.add_theme_constant_override("separation",14); add_child(amounts)
	for amount in [5,10,25]:
		var button:=Button.new(); button.name="Support%d" % amount; button.text="$%d" % amount
		button.custom_minimum_size=Vector2(110,48); amounts.add_child(button)
		button.pressed.connect(func(): show_amount(amount))
	var instruction:=Label.new(); instruction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	instruction.text="Choose an amount, then scan the code in PayPal. Amounts are in US dollars. Desktop links with a preselected amount are awaiting setup."
	if not amount_url(5).is_empty(): instruction.text="Choose an amount to review it before opening PayPal. Amounts are in US dollars."
	add_child(instruction)

func amount_url(amount: int) -> String:
	if not amount in [5,10,25]: return ""
	var link:=str(configuration.get("paypal_me","")).trim_suffix("/")
	if not link.begins_with("https://paypal.me/"): return ""
	var handle:=link.trim_prefix("https://paypal.me/")
	if handle.is_empty() or handle.length()>20: return ""
	for character in handle:
		if not character in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789": return ""
	return link+"/%dUSD" % amount

func show_amount(amount: int) -> AcceptDialog:
	var link:=amount_url(amount)
	var dialog:=AcceptDialog.new(); dialog.name="SupportAmount"; dialog.title="Optional support: US $%d" % amount
	dialog.get_ok_button().text="Close"; dialog.min_size=Vector2i(470,180 if not link.is_empty() else 460)
	var box:=VBoxContainer.new(); box.custom_minimum_size.x=420; dialog.add_child(box)
	var text:=Label.new(); text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x=420
	text.text="Support the game with US $%d. Recipient: %s." % [amount,configuration.get("recipient","")]; box.add_child(text)
	if not link.is_empty():
		var open:=Button.new(); open.name="OpenPayPal"; open.text="Continue to PayPal"; box.add_child(open)
		open.pressed.connect(func(): OS.shell_open(link))
	else:
		var qr:=TextureRect.new(); qr.name="PayPalQR"; qr.texture=SUPPORT_QR
		qr.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		qr.custom_minimum_size=Vector2(290,290); qr.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		qr.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; box.add_child(qr)
		var steps:=Label.new(); steps.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		steps.custom_minimum_size.x=420
		steps.text="Scan with the PayPal app, then enter US $%d. This QR code does not prefill an amount. Review the recipient and amount in PayPal before paying." % amount
		box.add_child(steps)
	dialog.confirmed.connect(dialog.queue_free); dialog.canceled.connect(dialog.queue_free)
	add_child(dialog); dialog.popup_centered(); return dialog
