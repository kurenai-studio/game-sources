class_name SkinCatalog extends RefCounted
## The built in skins. Gumdrop is the default; Slate and Nova are the
## alternates, in settings order. There is no skin import of any kind.
##
## Each skin also has its own board view and tile view, built on
## SkinBoardView and SkinTileView (docs/ARCHITECTURE.md section 6). Make them
## only through the factories here.

const DEFAULT_ID: StringName = &"gumdrop"
## Settings order.
const IDS: Array[StringName] = [&"gumdrop", &"slate", &"nova"]
const SKIN_PATH: String = "res://src/skins/%s/%s.tres"

const BOARD_VIEWS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/skins/gumdrop/gumdrop_board_view.gd"),
	&"slate": preload("res://src/skins/slate/slate_board_view.gd"),
	&"nova": preload("res://src/skins/nova/nova_board_view.gd"),
}
const TILE_VIEWS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/skins/gumdrop/gumdrop_tile_view.gd"),
	&"slate": preload("res://src/skins/slate/slate_tile_view.gd"),
	&"nova": preload("res://src/skins/nova/nova_tile_view.gd"),
}


## The skin with this id. An unknown id, for example from an old or damaged
## save, returns the default skin.
static func get_skin(id: StringName) -> SkinData:
	var skin_id: StringName = id if IDS.has(id) else DEFAULT_ID
	var skin: SkinData = load(SKIN_PATH % [skin_id, skin_id]) as SkinData
	if skin == null:
		push_error("could not load skin '%s'" % skin_id)
	return skin


## A board view for this skin. Call setup(skin, columns, rows) on it next.
## An unknown skin id gets the default skin's view.
static func make_board_view(skin: SkinData) -> SkinBoardView:
	if skin == null:
		push_error("make_board_view() needs a skin")
		return null
	var script: GDScript = BOARD_VIEWS.get(skin.id, BOARD_VIEWS[DEFAULT_ID])
	return script.new() as SkinBoardView


## A tile view for this skin, already set up with it. Give it a size and a
## value with set_value(). An unknown skin id gets the default skin's view.
static func make_tile_view(skin: SkinData) -> SkinTileView:
	if skin == null:
		push_error("make_tile_view() needs a skin")
		return null
	var script: GDScript = TILE_VIEWS.get(skin.id, TILE_VIEWS[DEFAULT_ID])
	var view: SkinTileView = script.new() as SkinTileView
	view.setup(skin)
	return view
