class_name CameraRig
extends Node3D
## Isometrische Kamera ohne Perspektive. Der Rig steht auf dem Boden, die Kamera schaut schräg von oben.
## Verschieben per Ziehen (der gegriffene Bodenpunkt bleibt unter dem Finger), Zoomen per Mausrad oder zwei Fingern.

const MIN_SIZE := 7.0
const MAX_SIZE := 26.0
const DISTANCE := 25.0

var camera := Camera3D.new()
var bounds := Rect2(0, 0, 40, 26)
var _anchor := Vector3.ZERO


func _ready() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0
	camera.near = 0.1
	camera.far = 200.0
	add_child(camera)
	# Klassische Isometrie: 45° gedreht, Blick 35,26° von oben.
	camera.position = Vector3(1, 1, 1).normalized() * DISTANCE
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	camera.current = true
	get_viewport().size_changed.connect(_fit_aspect)
	_fit_aspect()


## Im Hochformat gilt die Zoomgröße für die Breite, sonst wäre nur ein schmaler Streifen der Karte zu sehen.
func _fit_aspect() -> void:
	var view := get_viewport().get_visible_rect().size
	camera.keep_aspect = Camera3D.KEEP_WIDTH if view.x < view.y else Camera3D.KEEP_HEIGHT


func zoom(factor: float) -> void:
	camera.size = clampf(camera.size * factor, MIN_SIZE, MAX_SIZE)


## Bodenpunkt unter `screen` festhalten (beim Aufsetzen eines Fingers).
func grab(screen: Vector2) -> void:
	_anchor = ground_point(screen, 0.0)


## So verschieben, dass der festgehaltene Bodenpunkt unter `screen` liegt. Rechnet über denselben Strahl wie
## das Tippen und braucht weder `relative` noch einen Pixelmaßstab.
func drag_to(screen: Vector2) -> void:
	var offset := _anchor - ground_point(screen, 0.0)
	position.x = clampf(position.x + offset.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z + offset.z, bounds.position.y, bounds.end.y)
	# Am Rand rutscht der Punkt weg: neu greifen, sonst klebt die Kamera beim Zurückziehen in der Ecke.
	_anchor = ground_point(screen, 0.0)


## Bildschirmbewegung in Pixeln -> Bewegung auf dem Boden (Trackpad-Geste).
func pan(screen_delta: Vector2) -> void:
	var view := get_viewport().get_visible_rect().size
	var units := camera.size / (view.x if camera.keep_aspect == Camera3D.KEEP_WIDTH else view.y)
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var right_ground := Vector3(right.x, 0, right.z).normalized()
	var up_ground := Vector3(up.x, 0, up.z).normalized()
	# Auf dem Boden ist eine Bildschirmzeile wegen der Schräglage länger: 1 / sin(35,26°).
	var move := -right_ground * screen_delta.x * units + up_ground * screen_delta.y * units / sin(deg_to_rad(35.264))
	position += move
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z, bounds.position.y, bounds.end.y)


## Punkt auf dem Boden (Höhe `height`) unter einer Bildschirmposition.
func ground_point(screen: Vector2, height := 0.2) -> Vector3:
	var origin := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return origin
	var t := (height - origin.y) / dir.y
	return origin + dir * t
