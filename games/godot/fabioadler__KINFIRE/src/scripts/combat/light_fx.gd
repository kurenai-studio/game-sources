class_name LightFx
extends RefCounted
## Fase 7.2: gestão de luzes 2D - tremulação por fonte (fogueira oscila, lava
## pulsa, tocha crepita) e ORCAMENTO DE SOMBRA: no máx. 8 luzes com sombra
## ativas perto da tela; o resto degrada para luz sem sombra (MECANICAS #14.2).
## Sombras reais vêm dos occlusores de tile (paredes, árvores, lápides) - cada
## luz com sombra os projeta conforme se move. Luz sagrada ignora oclusores
## e luz sombria não projeta sombra (LORE #16): ambas simplesmente registram
## sem sombra - em 2D, occlusores só afetam luzes COM sombra ligada.

enum Flicker { NONE, FIRE, LAVA, TORCH }

const SHADOW_BUDGET := 8        ## máx. de luzes com sombra simultâneas
const SHADOW_RANGE := 720.0     ## além disto da câmera a sombra não compensa

## registro: {"light": PointLight2D, "flicker": int, "base": float,
##            "phase": float, "shadow": bool}
static var _reg: Array = []
static var _seq := 0


## Registra uma luz para tremulação e/ou candidatura a sombra. Retorna a
## própria luz (encadeável em Fx.make_light).
static func register(light: PointLight2D, flicker := Flicker.NONE, shadow := false) -> PointLight2D:
	_seq += 1
	_reg.append({
		"light": light, "flicker": flicker, "base": light.energy,
		"phase": float(_seq % 97) * 0.61, "shadow": shadow,
	})
	return light


## Chamado a cada frame pelo World._process: tremula as luzes registradas e
## distribui o orçamento de sombra às mais próximas do centro da tela.
static func update(center: Vector2, t: float) -> void:
	if _reg.is_empty():
		return
	_reg = _reg.filter(func(e): return is_instance_valid(e.light))
	for e in _reg:
		if e.flicker != Flicker.NONE:
			e.light.energy = e.base * _flicker(int(e.flicker), t, e.phase)
	var mode := int(Game.settings.get("shadows", 1))   # 0=off 1=PCF5 2=PCF13
	var wants: Array = []
	for e in _reg:
		if not e.shadow:
			continue
		if mode == 0 or not is_instance_valid(e.light):
			e.light.shadow_enabled = false
		else:
			wants.append(e)
	if wants.is_empty():
		return
	wants.sort_custom(func(a, b):
		return (a.light as PointLight2D).global_position.distance_squared_to(center) \
			< (b.light as PointLight2D).global_position.distance_squared_to(center))
	var granted := 0
	for e in wants:
		var on := granted < SHADOW_BUDGET \
			and (e.light as PointLight2D).global_position.distance_to(center) <= SHADOW_RANGE
		var l := e.light as PointLight2D
		l.shadow_enabled = on
		if on:
			l.shadow_filter = PointLight2D.SHADOW_FILTER_PCF5 if mode == 1 else PointLight2D.SHADOW_FILTER_PCF13
			l.shadow_filter_smooth = 1.0 if mode == 1 else 2.5
			granted += 1


## Quantas luzes registradas pedem sombra (smoke/inspeção)
static func shadow_candidates() -> int:
	var n := 0
	for e in _reg:
		if is_instance_valid(e.light) and e.shadow:
			n += 1
	return n


## Tremulação registrada para uma luz (-1 = não registrada) - smoke/inspeção
static func flicker_of(light: PointLight2D) -> int:
	for e in _reg:
		if e.light == light:
			return int(e.flicker)
	return -1


static func _flicker(kind: int, t: float, p: float) -> float:
	match kind:
		Flicker.FIRE:   ## fogueira: oscilação viva, rápida e irregular
			return 1.0 + 0.13 * (0.6 * sin(t * 13.0 + p) + 0.4 * sin(t * 29.0 + p * 2.0))
		Flicker.LAVA:   ## lava: pulso lento e pesado
			return 1.0 + 0.10 * sin(t * 1.7 + p)
		Flicker.TORCH:  ## tocha: crepitar em saltos curtos
			return 1.0 + 0.11 * (0.5 * sin(t * 7.0 + p) + 0.5 * sin(t * 23.0 + p * 3.0))
	return 1.0
