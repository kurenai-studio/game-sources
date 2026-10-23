class_name PathView
extends Node3D
## Weg der Bodengegner als Pfeile auf dem Boden. Ein Lichtlauf wandert in Laufrichtung. Beim Bauen zeigt
## eine helle Vorschau den Weg, der mit dem neuen Turm entstehen würde.

const HEIGHT := 0.215  # knapp über der Bodenkachel
const COLOR := Color(1.0, 0.78, 0.1)
const PREVIEW_COLOR := Color(0.75, 0.95, 1.0)
const FLOW_SPEED := 6.0  # Felder pro Sekunde

var _multi := MultiMesh.new()
var _count := 0
var _color := COLOR
var _time := 0.0


func _ready() -> void:
	_multi.transform_format = MultiMesh.TRANSFORM_3D
	_multi.use_colors = true
	_multi.mesh = _arrow_mesh()
	var node := MultiMeshInstance3D.new()
	node.multimesh = _multi
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


## Pfeil als flacher Winkel, Spitze zeigt nach +z, mit dunklem Rand darunter, damit er auf Gras und Stein
## gleich gut zu sehen ist.
func _arrow_mesh() -> Mesh:
	var mesh := ArrayMesh.new()
	_add_chevron(mesh, 1.3, 0.0, Color(0.1, 0.06, 0.02, 0.75), false, -1)
	_add_chevron(mesh, 1.0, 0.01, Color.WHITE, true, 0)
	return mesh


func _add_chevron(mesh: ArrayMesh, size: float, lift: float, color: Color, tinted: bool, priority: int) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(0, 0, 0.36), Vector3(0.36, 0, -0.14), Vector3(0, 0, 0.04),
			Vector3(0, 0, 0.36), Vector3(0, 0, 0.04), Vector3(-0.36, 0, -0.14)]
	for p: Vector3 in points:
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(p.x * size, lift, (p.z - 0.11) * size + 0.11))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = tinted
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.render_priority = priority
	st.set_material(material)
	st.commit(mesh)


func show_path(path: Array[Vector2i], preview := false) -> void:
	_color = PREVIEW_COLOR if preview else COLOR
	_count = maxi(0, path.size() - 1)
	_multi.instance_count = _count
	for i in _count:
		var from := Board.world_of(path[i], HEIGHT)
		var to := Board.world_of(path[i + 1], HEIGHT)
		var dir := to - from
		var basis := Basis(Vector3.UP, atan2(dir.x, dir.z))
		_multi.set_instance_transform(i, Transform3D(basis, from.lerp(to, 0.5)))
	_update_colors()


func _process(delta: float) -> void:
	_time += delta
	_update_colors()


func _update_colors() -> void:
	# Heller Puls alle 8 Felder, der mit FLOW_SPEED Richtung Burg läuft.
	var head := fposmod(_time * FLOW_SPEED, 8.0)
	for i in _count:
		var d := fposmod(i - head, 8.0)
		var glow := maxf(0.0, 1.0 - minf(d, 8.0 - d) / 2.0)
		var color := _color
		color.a = 0.8 + 0.2 * glow
		color = color.lerp(Color.WHITE, 0.5 * glow)
		_multi.set_instance_color(i, color)
