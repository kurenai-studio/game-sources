extends Node3D
class_name FinishGate
## Arco luminoso da linha de chegada.

var _portal: MeshInstance3D
var _time := 0.0
var _used := false


func build(accent := Color("7dffdf")) -> void:
	var stone := ObstacleKit.material(Color("2a2440"), 0.0)
	var gold := ObstacleKit.material(Color("ffd166"), 0.35)

	for side in [-1.0, 1.0]:
		ObstacleKit.add_box(self, Vector3(0.55, 4.4, 0.55), Vector3(2.65 * side, 2.2, 0), stone)
		ObstacleKit.add_box(self, Vector3(1.0, 0.35, 1.0), Vector3(2.65 * side, 4.55, 0), gold)
		ObstacleKit.add_cylinder(self, 0.06, 3.2, Vector3(2.65 * side, 2.2, 0.5), ObstacleKit.glow_material(accent, 2.0), 10)
	ObstacleKit.add_box(self, Vector3(6.0, 0.55, 0.65), Vector3(0, 4.45, 0), stone)
	ObstacleKit.add_box(self, Vector3(4.8, 0.12, 0.6), Vector3(0, 4.15, 0), ObstacleKit.glow_material(accent, 1.8))

	# Portal animado
	_portal = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(4.5, 3.6)
	_portal.mesh = quad
	_portal.position = Vector3(0, 2.0, 0)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 portal_color : source_color = vec4(0.35, 1.0, 0.8, 1.0);
void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.0, 0.8));
	float rings = sin(d * 34.0 - TIME * 4.5) * 0.5 + 0.5;
	float swirl = sin(atan(uv.y, uv.x) * 5.0 + TIME * 2.0) * 0.5 + 0.5;
	float alpha = smoothstep(0.52, 0.18, d) * (0.18 + rings * 0.24 + swirl * 0.08);
	ALBEDO = portal_color.rgb;
	EMISSION = portal_color.rgb * (0.7 + rings * 1.6);
	ALPHA = alpha;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("portal_color", accent)
	_portal.material_override = mat
	_portal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_portal)

	var light := OmniLight3D.new()
	light.light_color = accent
	light.light_energy = 2.2
	light.omni_range = 8.0
	light.position = Vector3(0, 2.0, 1.0)
	add_child(light)

	var area := Area3D.new()
	area.collision_layer = 4
	area.collision_mask = 2
	area.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(5.0, 3.5, 1.2)
	shape.shape = box
	shape.position = Vector3(0, 1.7, 0)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

	var finish_label := ObstacleKit.add_label(self, Loc.t("finish_label"), Vector3(0, 5.6, 0), Color("eafff8"), 72, 0.012)
	Loc.bind_text(finish_label, "finish_label")


func _process(delta: float) -> void:
	_time += delta
	if _portal:
		_portal.position.y = 2.0 + sin(_time * 1.3) * 0.05


func _on_body_entered(body: Node3D) -> void:
	if _used or not (body is TuxPlayer):
		return
	_used = true
	get_tree().call_group("game", "finish")
