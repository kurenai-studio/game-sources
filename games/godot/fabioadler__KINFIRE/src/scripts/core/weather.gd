class_name Weather
extends RefCounted
## Fase 7.6 (MECANICAS #14.4): clima e partículas ambientais.
## Chuva determinística por (semente do mundo, dia) - o jogador pode
## "prever" o tempo pelo forecast; o resto é consulta por bioma.
## Class estática no padrão WindField/LightFx (sem autoload).

## Emissor por bioma (#14.4): folhas, neve, cinzas, esporos, poeira.
const BIOME_EMITTER := {
	&"planicie": &"dust",
	&"floresta": &"leaf",
	&"deserto": &"dust",
	&"tundra": &"snow",
	&"pantano": &"spore",
	&"vulcanico": &"ash",
	&"corrompido": &"ash",
}

## Vagalumes noturnos (#14.4): planícies e floresta, só à noite.
const FIREFLY_BIOMES := [&"planicie", &"floresta"]

## Névoa volumétrica fake (#14.4): pântano e Terras Corrompidas.
const FOG_BIOMES := [&"pantano", &"corrompido"]

## Massa da partícula (#14.5.3): sensibilidade ao vento - folha leve
## voa inteira com a ventania, neve quase não sente.
const EMITTER_MASS := {
	&"leaf": 1.0, &"snow": 0.5, &"ash": 0.7, &"spore": 0.9,
	&"dust": 0.6, &"firefly": 0.2, &"rain": 0.4,
}

## Cores dos emissores (data-driven, sem assets externos).
const EMITTER_COLOR := {
	&"leaf": Color(0.55, 0.72, 0.25), &"snow": Color(0.95, 0.97, 1.0),
	&"ash": Color(0.85, 0.55, 0.35), &"spore": Color(0.65, 1.0, 0.55),
	&"dust": Color(0.85, 0.78, 0.6), &"firefly": Color(2.4, 2.8, 1.1),
	&"rain": Color(0.55, 0.65, 0.85),
}

static var world_seed := 0


## Chove neste dia? (#14.4: determinístico semente+dia, ~20% dos dias)
static func rain_on(day: int) -> bool:
	return _day_hash(day) < 0.20


## Previsão do dia para a HUD ("chuva" entra no relatório do dia).
static func forecast(day: int) -> StringName:
	return &"chuva" if rain_on(day) else &"claro"


static func _day_hash(day: int) -> float:
	return fmod(absf(sin(float(day * 2654435761 % 100003) * 127.1
		+ float(world_seed) * 311.7)) * 43758.5453, 1.0)


## Nome legível do emissor do bioma.
static func emitter_of(biome: StringName) -> StringName:
	return BIOME_EMITTER.get(biome, &"dust")


## Vagalumes neste bioma à noite?
static func fireflies_at(biome: StringName, night: bool) -> bool:
	return night and FIREFLY_BIOMES.has(biome)


## Névoa neste bioma?
static func fog_at(biome: StringName) -> bool:
	return FOG_BIOMES.has(biome)
