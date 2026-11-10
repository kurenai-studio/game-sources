class_name PanelSkin
extends RefCounted
## How the panels look in one age: the material (a hide in the Cave Age, later clay, papyrus...),
## its colours and font, and where each piece sits in the age's atlas. Art comes from the
## tools/art/ui_skin_<age>.js script, so adding an age's skin is: draw the atlas, add a factory
## here and register it in `skins()`. Unknown ages fall back to the Cave skin.

const ASSET_DIR: String = "res://assets/ui/"
const FONT_PATH: String = "res://assets/fonts/PixelifySans.ttf"
const FONT_SIZE: int = 12
## Tighter than the font's own line spacing, which is airy at this size.
const LINE_SPACING: int = -4
## The panel's art height, and the y of the row of small pieces under it in the atlas.
const PANEL_HEIGHT: int = 160
const ITEM_ROW: int = PANEL_HEIGHT + 4
## A shorter panel keeps the top of the art (title, rule, ornament) and this many rows of the bottom
## rail, and drops the plain middle, so it looks the same, only shorter.
const PANEL_FOOT: int = 8
## The OpenType tag of the weight axis ("wght") and the weight used for titles.
const WEIGHT_TAG: int = 0x77676874
const TITLE_WEIGHT: int = 700
## Corner size of the stitched button 9-patch.
const BUTTON_MARGIN: int = 4

var era_id: StringName = &""
var atlas_path: String = ""
var ink: Color = Color("2b2d42")
var muted: Color = Color("5a4630")
var title_color: Color = Color("7d3e22")
var day_color: Color = Color("8a4a2a")
var button_text: Color = Color("2b2d42")
var button_text_disabled: Color = Color("6a5a40")
var scroll_track: Color = Color("b48c58")
var scroll_grabber: Color = Color("6a4326")
## The hover tooltip's paper; its border is `muted` and its text `ink`.
var tooltip_fill: Color = Color("e6d3a6")
## Padding between the panel's art edge and its content (left, top, right, bottom).
var content_margins: Rect2 = Rect2(14, 11, 14, 10)
var panel_region: Rect2 = Rect2(0, 0, 384, PANEL_HEIGHT)
var button_regions: Dictionary = {}
var close_regions: Dictionary = {}
var icon_regions: Dictionary = {}

var _atlas: Texture2D
var _font: Font
var _title_font: Font
var _panel_textures: Dictionary = {}


## The registered factories: era id -> Callable returning a PanelSkin.
static func skins() -> Dictionary:
	return {
		&"cave": cave, &"settled": clay, &"bronze": bronze, &"iron": iron,
		&"classical": classical,
	}


static func for_era(era: StringName) -> PanelSkin:
	var factories: Dictionary = skins()
	if factories.has(era):
		return (factories[era] as Callable).call()
	return cave()


static func cave() -> PanelSkin:
	var skin: PanelSkin = PanelSkin.new()
	skin.era_id = &"cave"
	skin.atlas_path = ASSET_DIR + "skin_hide.png"
	skin._place_pieces()
	return skin


## The Settled Age: a timber frame round a plastered clay wall, fired-clay tile buttons, and a
## wheat ear. Same atlas layout as the Cave skin.
static func clay() -> PanelSkin:
	var skin: PanelSkin = PanelSkin.new()
	skin.era_id = &"settled"
	skin.atlas_path = ASSET_DIR + "skin_clay.png"
	skin.title_color = Color("8a3a22")
	skin.muted = Color("5a3a28")
	skin.button_text_disabled = Color("6a5a48")
	skin.scroll_track = Color("c9a07a")
	skin.scroll_grabber = Color("6e4a2c")
	skin.tooltip_fill = Color("ead9bb")
	skin._place_pieces()
	return skin


## The Bronze Age: a hammered-bronze frame round a sun-baked mud-brick wall, bronze-plate buttons,
## and a Greek key under the title. Same atlas layout as the Cave skin.
static func bronze() -> PanelSkin:
	var skin: PanelSkin = PanelSkin.new()
	skin.era_id = &"bronze"
	skin.atlas_path = ASSET_DIR + "skin_bronze.png"
	skin.title_color = Color("6e3a12")
	skin.muted = Color("4e3418")
	skin.button_text_disabled = Color("5a5a48")
	skin.scroll_track = Color("c8a066")
	skin.scroll_grabber = Color("8f5a1c")
	skin.tooltip_fill = Color("e8d2a2")
	skin._place_pieces()
	return skin


## The Iron Age: a forged dark-iron frame with rust trim round a pale limewashed wall, iron-bound
## buttons, and a ring-chain under the title. Same atlas layout as the Cave skin.
static func iron() -> PanelSkin:
	var skin: PanelSkin = PanelSkin.new()
	skin.era_id = &"iron"
	skin.atlas_path = ASSET_DIR + "skin_iron.png"
	skin.title_color = Color("6a2e14")
	skin.muted = Color("48443a")
	skin.day_color = Color("7a4426")
	skin.button_text_disabled = Color("66665f")
	skin.scroll_track = Color("bcbab0")
	skin.scroll_grabber = Color("555d6b")
	skin.tooltip_fill = Color("e4e2d8")
	skin._place_pieces()
	return skin


## The Classical Age: pale limestone beams and fluted columns round a plastered cream wall, a Greek
## key under the title, terracotta-tile buttons and an amphora. Same atlas layout as the Cave skin.
static func classical() -> PanelSkin:
	var skin: PanelSkin = PanelSkin.new()
	skin.era_id = &"classical"
	skin.atlas_path = ASSET_DIR + "skin_classical.png"
	skin.title_color = Color("8a3f24")
	skin.muted = Color("584d3a")
	skin.day_color = Color("9a5430")
	skin.button_text_disabled = Color("7a7466")
	skin.scroll_track = Color("d8ccb0")
	skin.scroll_grabber = Color("b86a42")
	skin.tooltip_fill = Color("f0e8d4")
	skin._place_pieces()
	return skin


## Where each small piece sits in an age's atlas: the skins share one layout.
func _place_pieces() -> void:
	button_regions = {
		&"normal": Rect2(0, ITEM_ROW, 16, 16), &"hover": Rect2(16, ITEM_ROW, 16, 16),
		&"pressed": Rect2(32, ITEM_ROW, 16, 16), &"disabled": Rect2(48, ITEM_ROW, 16, 16),
	}
	close_regions = {
		&"normal": Rect2(64, ITEM_ROW, 14, 14), &"hover": Rect2(78, ITEM_ROW, 14, 14),
	}
	icon_regions = {
		&"wood": Rect2(96, ITEM_ROW, 10, 10), &"food": Rect2(106, ITEM_ROW, 10, 10),
	}


func atlas() -> Texture2D:
	if _atlas == null:
		_atlas = load(atlas_path) as Texture2D
	return _atlas


## A piece of the atlas as a texture.
func piece(region: Rect2) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = atlas()
	texture.region = region
	return texture


## The panel's art at `height` rows: the whole piece at full height, otherwise its top and bottom
## rail with the middle cut out (a short panel for short content). Built once per height.
func panel_texture(height: int) -> Texture2D:
	var full: int = int(panel_region.size.y)
	if height >= full:
		return piece(panel_region)
	height = maxi(height, PANEL_FOOT + 1)
	if _panel_textures.has(height):
		return _panel_textures[height]
	var source: Image = atlas().get_image()
	var width: int = int(panel_region.size.x)
	var image: Image = Image.create(width, height, false, source.get_format())
	image.blit_rect(source, Rect2i(0, 0, width, height - PANEL_FOOT), Vector2i.ZERO)
	image.blit_rect(
		source, Rect2i(0, full - PANEL_FOOT, width, PANEL_FOOT), Vector2i(0, height - PANEL_FOOT)
	)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	_panel_textures[height] = texture
	return texture


## The icon for a resource or item, or null if the skin has none (the panel then writes its name).
func icon_for(key: StringName) -> Texture2D:
	if not icon_regions.has(key):
		return null
	return piece(icon_regions[key])


func font() -> Font:
	if _font == null:
		_font = _load_font()
	return _font


## The same face in bold, for titles.
func title_font() -> Font:
	if _title_font == null:
		var bold: FontVariation = FontVariation.new()
		bold.base_font = font()
		bold.variation_opentype = {WEIGHT_TAG: TITLE_WEIGHT}
		_title_font = bold
	return _title_font


func _load_font() -> Font:
	var face: FontFile = load(FONT_PATH) as FontFile
	if face == null:
		return ThemeDB.fallback_font
	# Crisp pixel text: no smoothing, no sub-pixel placement.
	face.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	face.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	face.hinting = TextServer.HINTING_NONE
	return face
