extends Control
class_name NightShiftUI

@onready var clock_label: Label = get_node_or_null("TopLeft/ClockLabel")
@onready var tickets_container: VBoxContainer = get_node_or_null("TopRight/TicketsContainer")
@onready var polaroid_card: PanelContainer = get_node_or_null("BottomLeft/PolaroidCard")
@onready var polaroid_title: Label = get_node_or_null("BottomLeft/PolaroidCard/VBox/PhotoTitle")
@onready var polaroid_time: Label = get_node_or_null("BottomLeft/PolaroidCard/VBox/PhotoTime")
@onready var viewfinder: Control = get_node_or_null("Viewfinder")
@onready var crosshair: CenterContainer = get_node_or_null("Crosshair")
@onready var help_panel: PanelContainer = get_node_or_null("HelpPanel")
@onready var victory_panel: PanelContainer = get_node_or_null("VictoryPanel")

func _ready():
	_ensure_nodes()
	if polaroid_card:
		polaroid_card.visible = false
	if viewfinder:
		viewfinder.visible = false
	if help_panel:
		help_panel.visible = false
	if victory_panel:
		victory_panel.visible = false

func _ensure_nodes():
	if not clock_label:
		clock_label = get_node_or_null("TopLeft/ClockLabel")
	if not tickets_container:
		tickets_container = get_node_or_null("TopRight/TicketsContainer")
	if not polaroid_card:
		polaroid_card = get_node_or_null("BottomLeft/PolaroidCard")
	if not polaroid_title:
		polaroid_title = get_node_or_null("BottomLeft/PolaroidCard/VBox/PhotoTitle")
	if not polaroid_time:
		polaroid_time = get_node_or_null("BottomLeft/PolaroidCard/VBox/PhotoTime")
	if not viewfinder:
		viewfinder = get_node_or_null("Viewfinder")
	if not crosshair:
		crosshair = get_node_or_null("Crosshair")
	if not help_panel:
		help_panel = get_node_or_null("HelpPanel")
	if not victory_panel:
		victory_panel = get_node_or_null("VictoryPanel")

func update_time(time_str: String):
	_ensure_nodes()
	if clock_label:
		clock_label.text = "[ %s ] SITE-42 NIGHT SHIFT" % time_str

func update_tickets(tickets: Array):
	_ensure_nodes()
	if not tickets_container:
		return
	for c in tickets_container.get_children():
		c.queue_free()
		
	var header = Label.new()
	header.text = "-- MAINTENANCE LOG --"
	header.modulate = Color(0.2, 1.0, 0.4)
	tickets_container.add_child(header)
	
	for t in tickets:
		var lbl = Label.new()
		var prefix = "[✓]" if t["status"] == "RESOLVED" else ("[•]" if t["status"] == "PENDING" else "[!]")
		lbl.text = "%s %s [%s]" % [prefix, t["title"], t["status"]]
		if t["status"] == "RESOLVED":
			lbl.modulate = Color(0.5, 0.8, 0.5)
		elif t["status"] == "AVAILABLE":
			lbl.modulate = Color(1.0, 0.9, 0.2)
		else:
			lbl.modulate = Color(0.8, 0.8, 0.8)
		tickets_container.add_child(lbl)

func on_photo_taken(photo_data: Dictionary):
	_ensure_nodes()
	if polaroid_card:
		polaroid_card.visible = true
	if polaroid_title:
		polaroid_title.text = photo_data.get("title", "PHOTO")
	if polaroid_time:
		polaroid_time.text = "TIMESTAMP: " + photo_data.get("time", "00:00")

func set_aiming(is_aiming: bool):
	_ensure_nodes()
	if viewfinder:
		viewfinder.visible = is_aiming
	if crosshair:
		crosshair.visible = not is_aiming

func toggle_help():
	_ensure_nodes()
	if help_panel:
		help_panel.visible = not help_panel.visible

func show_shift_complete():
	_ensure_nodes()
	if victory_panel:
		victory_panel.visible = true
