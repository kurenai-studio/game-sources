extends Node2D

# for the actual book positions
@onready var markerList = [$BookMarkers/Marker2D, $BookMarkers/Marker2D2, $BookMarkers/Marker2D3, $BookMarkers/Marker2D4, $BookMarkers/Marker2D5]
@onready var posList: Array
@onready var bookList = [$Book1, $Book2, $Book3, $Book4, $Book5]
@onready var cMod = $CanvasModulate

# for the position markers/the order that you are supposed to put the books in
@onready var bookToMarkerHM = {$Book1: $"PositionMarkerSprites/1", $Book2: $"PositionMarkerSprites/2", $Book3: $"PositionMarkerSprites/3", $Book4: $"PositionMarkerSprites/4", $Book5: $"PositionMarkerSprites/5"}
@onready var posMarkerList = [$PositionMarkers/Marker2D, $PositionMarkers/Marker2D2, $PositionMarkers/Marker2D3, $PositionMarkers/Marker2D4, $PositionMarkers/Marker2D5]
@onready var posMarkerPosList: Array
@onready var orderedBookList: Array = [$Book1, $Book2, $Book3, $Book4, $Book5]

@onready var ovheadLight = $OverheadLight

@onready var selectedArray: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ovheadLight.energy = 0
	for marker in markerList:
		if marker:
			posList.append(marker.position)
			
	for marker in posMarkerList:
		if marker:
			posMarkerPosList.append(marker.position)
			
	bookList.shuffle()
	for i in range(bookList.size()):
		var book = bookList[i]
		book.position = posList[i]
	reset()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not self.visible: return
	if selectedArray.size() == 2:
		var index0 = bookList.find(selectedArray[0])
		var index1 = bookList.find(selectedArray[1])
		var book0pos = posList[index0]
		var book1pos = posList[index1]
		
		var tween0 = create_tween()
		tween0.tween_property(selectedArray[0], "position", book1pos, 0.3)
	
		var tween1 = create_tween()
		tween1.tween_property(selectedArray[1], "position", book0pos, 0.3)
		
		var temp = bookList[index0]
		bookList[index0] = bookList[index1]
		bookList[index1] = temp
		
		selectedArray[0].selected = false
		selectedArray[0].tweenDown()
		selectedArray[1].selected = false
		selectedArray[1].tweenDown()
		selectedArray.clear()
		
	if bookList == orderedBookList:
		var tween1 = create_tween()
		tween1.tween_property(ovheadLight, "energy", 1.0, 0.3)
		tween1.tween_property(ovheadLight, "energy", 0.0, 0.3)
		await tween1.finished
		reset()
		print(bookList)
		
func tweenIn() -> void:
	cMod.show()
	$Lantern.position = Vector2(500, 550)
	var lanterntween = create_tween()
	lanterntween.tween_property($Lantern, "position:y", 200, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func tweenOut() -> void:
	cMod.hide()
	var lanterntween = create_tween()
	lanterntween.tween_property($Lantern, "position:y", 550, 1.0)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
func reset() -> void:
	Global.sanity += 10
	orderedBookList.shuffle()
	for i in range(orderedBookList.size()):
		var marker = bookToMarkerHM.get(orderedBookList[i])
		marker.position = posMarkerPosList[i]
