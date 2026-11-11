extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var support=load("res://ui/support_panel.gd").new(); root.add_child(support)
	check(support.configuration.recipient=="Jim Holtz","recipient matches supplied QR")
	check(support.configuration.paypal_me=="https://paypal.me/SuperpuppySD","verified public profile configured")
	for amount in [5,10,25]:
		check(support.amount_url(amount)=="https://paypal.me/SuperpuppySD/%dUSD" % amount,"correct recipient, amount and currency")
		check(support.find_child("Support%d" % amount,true,false)!=null,"requested amount available")
		var dialog=support.show_amount(amount)
		check(dialog.find_child("OpenPayPal",true,false)!=null,"selected amount has a browser launch button")
		check(dialog.find_child("PayPalQR",true,false)==null,"desktop support does not ask for manual amount entry")
		dialog.queue_free(); await process_frame
	support.configuration.paypal_me=""
	var fallback=support.show_amount(5)
	check(fallback.find_child("PayPalQR",true,false).texture!=null,"supplied QR fallback remains available if link is unconfigured")
	fallback.queue_free(); await process_frame
	support.configuration.paypal_me="https://paypal.me/example"
	check(support.amount_url(25)=="https://paypal.me/example/25USD","documented amount syntax when a real handle is configured")
	support.configuration.paypal_me="https://paypal.me/123example"
	check(not support.amount_url(5).is_empty(),"documented alphanumeric handles may start with a digit")
	support.configuration.paypal_me="https://paypal.me/../evil"
	check(support.amount_url(25).is_empty(),"invalid payment handle rejected")
	check(support.amount_url(999).is_empty(),"only requested support amounts accepted")
	support.queue_free(); await process_frame
	print("Support 20 failures: ",failures); quit(1 if failures else 0)
