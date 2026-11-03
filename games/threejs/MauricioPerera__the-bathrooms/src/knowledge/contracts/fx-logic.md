---
type: 'Task Contract'
title: 'Logica pura de VHS, luces y audio ambiental de The Bathrooms'
description: 'Funciones puras y deterministas: timestamp de camcorder VHS, maquina de estados de luces fluorescentes (estable/parpadeo/muerta), atenuacion por distancia y scheduler componible de eventos ambientales de bano.'
tags: ['bathrooms', 'vhs', 'audio', 'game']

task: fx-logic
intent: "Proveer la logica determinista de timestamp VHS, estado de luces fluorescentes y planificacion de eventos sonoros ambientales."
target: src/game/fx-logic.mjs
signature: "function lightState(seed, id, timeMs)"
test_command: "node --test tests/game/fx-logic.test.mjs"
budget:
  max_cyclomatic_complexity: 10
  max_nesting_depth: 4
tests: "tests/game/fx-logic.test.mjs"
tests_sha256: "4f16d9bd83bffb4a435c7cc16ee0d8ea919eff118715598452e7d048efedea82"
touch_only: ['src/game/fx-logic.mjs']
deps_allowed: []
forbids: ['network', 'Math.random', 'Date.now', 'DOM', 'editar los tests congelados']
---

# Contract: fx-logic

## Intent
Separar del motor 3D toda la logica que se puede testear sin GPU ni audio real: el
timestamp del overlay VHS, el comportamiento de cada luz fluorescente del techo
(estable / parpadeante / muerta) y el plan determinista de eventos sonoros ambientales
(cadenas de inodoro, secadores de manos que rugen solos, ruidos de cubiculo, golpes de
tuberia). El motor consume estas funciones cada frame; aqui NO hay estado ni efectos.

## Interface
```js
// src/game/fx-logic.mjs — ESM puro, cero dependencias, funciones puras.
export function vhsTimestamp(epochMs)                 // -> { date, time }
export function lightState(seed, id, timeMs)          // -> { mode, intensity }
export function attenuation(dist, refDist, maxDist)   // -> gain [0,1]
export function scheduleAmbientEvents(seed, t0, t1)   // -> [{t, type, dx, dz}]
```
- `vhsTimestamp`: UTC. `date` = `"MMM.D YYYY"` con mes en `JAN FEB MAR APR MAY JUN JUL
  AUG SEP OCT NOV DEC` y dia SIN cero a la izquierda (`JUL.11 2026`, `JAN.1 1970`).
  `time` = `"HH:MM:SS"` 24h con cero a la izquierda. Milisegundos truncan.
- `lightState`: `mode` en `steady|flicker|dead`, funcion SOLO de `(seed, id)` (una luz no
  cambia de modo con el tiempo). `intensity` en `[0,1]`: `dead` => 0 siempre; `steady` =>
  constante >= 0.6 (puede tener micro-variacion >= 0.6); `flicker` => varia con `timeMs`
  tocando valores < 0.3 y > 0.6 dentro de cualquier ventana de ~20s muestreada cada 40ms.
- `attenuation`: 1 si `dist <= refDist`; 0 si `dist >= maxDist`; monotona no creciente y
  estrictamente entre 0 y 1 en el medio (curva suave, p.ej. lineal o cuadratica invertida).
- `scheduleAmbientEvents`: eventos con `t` en `[t0, t1)` ORDENADOS por `t`, `type` en
  `flush|dryer|stall_noise|pipe_knock`, `dx`/`dz` offset relativo al jugador en metros
  con `|dx|,|dz| <= 20`. **Componible sin estado**: `events(a,c)` debe ser identico a
  `events(a,b) ++ events(b,c)` — genera sobre una reticula fija de slots de tiempo
  (p.ej. slots de 10s hasheados con la seed) y filtra por ventana. Tasa: en 10 minutos
  entre 6 y 180 eventos; en 30 minutos deben aparecer >= 3 tipos distintos.

## Invariants
- Todas las funciones son puras y deterministas: mismos argumentos => mismo resultado
  (deep-equal). PROHIBIDO `Math.random`, `Date.now`, estado de modulo mutable.
- Distribucion de modos de luz sobre 200 ids consecutivos (0..199) con cualquier seed
  fija: muertas en [10, 70], flicker en [20, 100], steady >= 60. Sugerencia: umbral por
  hash de `(seed, id)`.
- Sin dependencias, sin DOM, sin I/O.

## Examples
- `vhsTimestamp(0)` => `{ date: 'JAN.1 1970', time: '00:00:00' }`.
- `vhsTimestamp(Date.UTC(2026, 6, 11, 20, 56, 3))` => `{ date: 'JUL.11 2026', time: '20:56:03' }`.
- `attenuation(2, 2, 30)` => `1`; `attenuation(30, 2, 30)` => `0`; `attenuation(16, 2, 30)` en (0,1).
- `scheduleAmbientEvents(s, 0, 120000)` === `[...scheduleAmbientEvents(s, 0, 60000),
  ...scheduleAmbientEvents(s, 60000, 120000)]`.

## Do / Don't
- DO: un unico helper de hash entero compartido (mulberry32/xorshift) para modos, slots
  de eventos y fase del flicker.
- DO: flicker con textura organica (mezcla de senos + hash por tramo esta bien) mientras
  cumpla los rangos del contrato.
- DON'T: acumular estado entre llamadas; el motor puede consultar cualquier t en
  cualquier orden.
- DON'T: editar `tests/game/fx-logic.test.mjs` — si un test parece mal, PARA y reportalo.

## Ampliacion v3 (eventos sonoros nuevos, obligatoria)
- `scheduleAmbientEvents` amplia los tipos a 8: los 4 existentes mas `shower_hiss`
  (ducha que se abre sola), `door_slam` (portazo de cubiculo), `drain_gurgle`
  (gorgoteo de desague) y `faucet_squeal` (chirrido de grifo). En 30 minutos deben
  aparecer >= 6 tipos distintos. Composicion por slots y rangos existentes sin cambios.

## Tests
Oraculo congelado en `tests/game/fx-logic.test.mjs` (sellado por `tests_sha256`):
formato exacto del timestamp, estabilidad del modo por luz, rangos de intensidad,
distribucion de modos, variabilidad del flicker, monotonia de la atenuacion, y
determinismo + composicion de ventanas + variedad del scheduler. Correr:
`node --test tests/game/fx-logic.test.mjs` (desde la raiz del repo).

## Constraints
- ESM puro (`.mjs`), Node >= 18, cero dependencias. Presupuesto informativo:
  ciclomatica <= 10, anidado <= 4.
- Perimetro: SOLO `src/game/fx-logic.mjs`.
- PARAR y reportar si un test congelado parece incorrecto o el contrato es inviable; no editarlo.
