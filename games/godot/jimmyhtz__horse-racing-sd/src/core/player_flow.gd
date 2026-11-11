extends RefCounted
const Identity = preload("res://core/player_identity.gd")
const Access = preload("res://core/operator_access.gd")

var session: RefCounted
var preferences: RefCounted
var screen := "overview"
var active_player := -1
var settings_open := false
var settings_player := -1
var settings_return_notice := ""
var error := ""
var drafts: Array = []
var virtual_draft := {}
var manager_pins := {}
var manager_only := false
var countdown := 0
var _entry := {}
var _return := {}

func _init(game: RefCounted, settings: RefCounted) -> void:
	session = game
	preferences = settings

func reject(message: String) -> bool:
	error = message
	session.diagnostic_event.emit("flow_rejected",{"reason":message,"screen":screen,"player":active_player})
	return false

func select_player(index: int) -> bool:
	if settings_open or session.phase != "BETTING" or not session.valid_player(index) or session.players[index].state == "PENDING PAYOUT":
		return reject("This player is not available for betting.")

	active_player = index
	session.diagnostic_event.emit("player_selected",{"player":index})
	if session.virtual_config.seats[index].enabled:
		screen="virtual"
		return true
	if session.players[index].balance<=0 and session.wager_total(index)==0:
		screen="inactive"
		return true
	screen = "pin" if session.access.credentials.has("player_%d" % index) else "betting"
	if screen == "betting":
		open_betting()
	error = ""
	return true

func open_betting() -> void:
	screen = "betting"
	if session.players[active_player].balance > 0 or session.wager_total(active_player) > 0:
		session.set_ready(active_player,false)

func enter_pin(pin: String) -> bool:
	if settings_open or screen != "pin" or session.phase != "BETTING":
		return reject("Select a player first.")
	if not session.authorize("player_%d" % active_player,pin):
		return reject("PIN not accepted. Try again, or ask the manager for help.")
	open_betting()
	error = ""
	return true

func request_out_toggle(index: int) -> bool:
	if settings_open or session.phase!="BETTING" or not session.valid_player(index) or session.players[index].state=="PENDING PAYOUT":
		return reject("This player's participation cannot change now.")
	var success: bool=session.set_ready(index,false) if session.players[index].state=="OUT" else session.set_out(index)
	if not success: return reject(session.error)
	if active_player==index or screen=="start_pin": screen="overview"; active_player=-1
	error=""
	return true

func cycle_virtual(index: int) -> bool:
	if settings_open or session.phase!="BETTING" or not session.valid_player(index): return reject("V mode is available on the betting screen.")
	var choice: int=(session.virtual_choice(index)+1)%(session.virtual_config.styles.size()+3)
	if not session.set_virtual_choice(index,choice): return reject(session.error)
	if active_player==index:
		if choice>0: screen="virtual"
		elif session.players[index].state in ["OUT","PENDING PAYOUT"]:
			screen="overview"; active_player=-1
		else: screen="pin" if session.access.credentials.has("player_%d" % index) else "betting"
	error=""
	return true

func back() -> void:
	if not settings_open and screen in ["pin","start_pin","virtual","inactive"]:
		screen = "overview"
		active_player = -1
		error = ""

func request_ready_toggle(index: int) -> bool:
	if settings_open or session.phase != "BETTING" or not session.valid_player(index) or session.players[index].state in ["OUT","PENDING PAYOUT"] or screen == "start_pin":
		return reject("Join this race before marking Ready.")
	if session.virtual_config.seats[index].enabled:
		return reject("Virtual players mark themselves Ready.")
	if not session.set_ready(index,session.players[index].state != "READY"):
		return reject(session.error)
	if active_player == index:
		screen = "overview"
		active_player = -1
	error = ""
	return true

func ready() -> bool:
	if settings_open or screen != "betting" or not session.set_ready(active_player,true):
		return reject(session.error)
	screen = "overview"
	active_player = -1
	return true

func out() -> bool:
	if settings_open or screen != "betting" or not session.set_out(active_player):
		return reject(session.error)
	screen = "overview"
	active_player = -1
	return true

func begin_settings(pin: String = "") -> bool:
	if session.phase!="BETTING": return reject("Settings are available on the betting screen.")
	if settings_open:
		return true
	if session.access.credentials.has("operator") and not session.authorize("operator",pin):
		return reject("Settings PIN not accepted.")
	_return = {"screen":screen,"player":active_player}
	settings_return_notice = ""
	settings_player = active_player if screen == "pin" else -1
	virtual_draft=session.virtual_config.duplicate(true)
	_entry = {"virtual_config":session.virtual_config.duplicate(true),"preferences":preferences.export_data(),"profiles":session.player_profiles.duplicate(true),"names":[],"manager_only":session.manager_only_start,"countdown":session.start_countdown}
	for player in session.players:
		_entry.names.append(player.nickname)
	settings_open = true
	reset_drafts()
	error = ""
	return true

func reset_drafts() -> void:
	drafts.clear()
	for i in range(8):
		drafts.append({"nickname":_entry.names[i],"profile":_entry.profiles[i].duplicate(true),"pin":"","confirm":"","remove":false})
	manager_pins.clear()
	for domain in ["operator","start","rtp"]:
		manager_pins[domain] = {"pin":"","confirm":"","remove":false}
	manager_only = _entry.manager_only
	countdown = _entry.countdown

func revert_settings() -> void:
	if settings_open:
		preferences.restore(_entry.preferences)
		virtual_draft=_entry.virtual_config.duplicate(true)
		reset_drafts()
		error = ""

func validate_pin_edit(edit: Dictionary) -> bool:
	if edit.remove:
		return edit.pin.is_empty() and edit.confirm.is_empty()
	if edit.pin.is_empty() and edit.confirm.is_empty():
		return true
	return session.access.valid_pin(edit.pin) and edit.pin == edit.confirm

func finish_settings() -> bool:
	if not settings_open:
		return false
	if not session.VirtualPlayers.valid(virtual_draft): return reject("Check the virtual player style ranges.")
	var profiles: Array = []
	for i in range(8):
		var draft: Dictionary = drafts[i]
		if draft.nickname.strip_edges().is_empty() or draft.nickname.length() > 24:
			settings_player = i
			return reject("Player %d needs a name of 1 to 24 characters." % (i+1))
		if not validate_pin_edit(draft):
			settings_player = i
			return reject("Player %d: enter the same four digits twice, or leave both fields empty." % (i+1))
		profiles.append(draft.profile.duplicate(true))
	var invalid := Identity.validate(profiles)
	if not invalid.is_empty():
		return reject(invalid)
	for domain in manager_pins:
		if not validate_pin_edit(manager_pins[domain]):
			return reject("Manager PINs must contain matching four-digit entries, or both fields must be empty.")
	var candidate = Access.new()
	candidate.credentials = session.access.credentials.duplicate(true)
	for i in range(8):
		apply_pin_edit(candidate,"player_%d" % i,drafts[i])
	for domain in manager_pins:
		apply_pin_edit(candidate,domain,manager_pins[domain])
	if manager_only and not candidate.credentials.has("start"):
		return reject("Set a four-digit Start PIN before enabling manager-only starting.")
	if countdown < 0 or countdown > 10:
		return reject("Countdown must be off or between 1 and 10 seconds.")
	# All validation precedes mutation. Identity maintenance never alters account state.
	for i in range(8):
		var name: String = drafts[i].nickname.strip_edges()
		if session.players[i].nickname != name or session.player_profiles[i] != profiles[i]:
			session.players[i].nickname = name
			session.record("player_identity_updated",i)
	# Settings edits styles only. Seat ownership is controlled by the public V button.
	session.virtual_config.styles=virtual_draft.styles.duplicate(true)
	session.player_profiles = profiles
	session.access.credentials = candidate.credentials
	session.manager_only_start = manager_only
	session.start_countdown = countdown
	session.record("manager_settings_updated")
	screen = _return.screen
	active_player = _return.player
	if session.valid_player(active_player):
		if session.virtual_config.seats[active_player].enabled and screen in ["betting","pin"]:
			screen="virtual"
		elif screen=="virtual" and not session.virtual_config.seats[active_player].enabled:
			screen="pin" if session.access.credentials.has("player_%d" % active_player) else "betting"
			if screen=="betting": open_betting()
	if screen == "pin" and not session.access.credentials.has("player_%d" % active_player):
		settings_return_notice = "Player %d PIN removed. Select their summary to open the console." % (active_player+1)
		screen = "overview"
		active_player = -1
	settings_open = false
	settings_player = -1
	drafts.clear()
	manager_pins.clear()
	_entry.clear()
	_return.clear()
	error = ""
	return true

func apply_pin_edit(access: RefCounted, domain: String, edit: Dictionary) -> void:
	if edit.remove:
		access.credentials.erase(domain)
	elif not edit.pin.is_empty():
		access.set_pin(domain,edit.pin)

func can_start() -> bool:
	return not settings_open and screen in ["overview","start_pin","virtual","inactive"] and session.can_start()

func authorize_start(pin: String = "") -> bool:
	if not can_start():
		return reject("Close the open panel and mark every participating player Ready or Out.")
	if session.manager_only_start and not session.authorize("start",pin):
		return reject("Start PIN not accepted.")
	return true
