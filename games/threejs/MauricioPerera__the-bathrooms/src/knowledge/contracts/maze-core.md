---
type: 'Task Contract'
title: 'Nucleo del laberinto infinito de The Bathrooms'
description: 'Generador determinista por chunks del laberinto infinito de banos publicos: celdas, props, luces, charcos, consulta de caminabilidad y colision con deslizamiento. ESM puro, sin DOM, sin Three.js.'
tags: ['bathrooms', 'maze', 'procedural', 'game']

task: maze-core
intent: "Generar deterministicamente el laberinto infinito de banos por chunks con colision y conectividad garantizada."
target: src/game/maze-core.mjs
signature: "function generateChunk(seed, cx, cz, opts)"
test_command: "node --test tests/game/maze-core.test.mjs"
budget:
  max_cyclomatic_complexity: 12
  max_nesting_depth: 4
tests: "tests/game/maze-core.test.mjs"
tests_sha256: "12c8f98f94ebb65126421329a57d6044788b8dada7c0daea83f8d37227c6dd40"
touch_only: ['src/game/maze-core.mjs']
deps_allowed: []
forbids: ['network', 'Math.random', 'Date.now', 'DOM', 'three.js', 'editar los tests congelados']
---

# Contract: maze-core

## Intent
Nucleo logico del juego "The Bathrooms": un laberinto INFINITO de banos publicos generado
por chunks de forma 100% determinista a partir de una seed. Es la unica fuente de verdad
sobre que celda es caminable, donde hay props (cubiculos, lavabos, espejos, urinarios,
dispensadores, papeleras, tuberias), donde hay luces de techo y charcos. El motor 3D
(otro contrato) consume este modulo; este modulo NO conoce render ni DOM.

## Interface
```js
// src/game/maze-core.mjs — ESM puro, cero dependencias.
export function generateChunk(seed, cx, cz, opts) // -> chunk
export function isWalkable(seed, wx, wz, opts)    // -> boolean (celda mundial entera)
export function chunksInRadius(px, pz, r, opts)   // -> [{cx, cz}] ordenado y determinista
export function resolveMovement(seed, pos, delta, radius, opts) // -> {x, z}
```
- `opts` opcional; unico knob relevante: `chunkSize` (default **18**).
- Unidades: 1.0 = una celda. `pos`/`delta` son floats en coordenadas de celda mundial;
  `wx`/`wz` son enteros (indice de celda mundial); `cx`/`cz` indice de chunk.
- `chunk = { cx, cz, size, cells, props, lights, puddles }` donde:
  - `cells`: Array plano de `size*size` enteros, indexado `[z*size+x]`.
    Tipos: `0`=pared/no caminable, `1`=corredor, `2`=zona de cubiculos, `3`=zona de
    lavabos, `4`=inundada (caminable, con agua).
  - `props`: `[{x, z, type, rot}]` con `type` en
    `stall|sink|mirror|urinal|dispenser|bin|pipes`, coordenadas LOCALES enteras
    `[0,size)`, `rot` 0..3 (0=+z, 1=+x, 2=-z, 3=-x, apuntando hacia el espacio caminable).
  - `lights`: `[{x, z}]` locales, sobre celdas caminables (luz de techo por celda).
  - `puddles`: `[{x, z, r}]` locales sobre celdas caminables, `r` en `(0.15, 0.6]`.

## Invariants
- **Determinismo total**: mismos `(seed, cx, cz, opts)` => resultado deep-equal. Toda la
  aleatoriedad sale de un hash entero puro de `(seed, coordenadas)` (p.ej. mulberry32 /
  xorshift sobre una mezcla de bits). PROHIBIDO `Math.random` y `Date.now`.
- **Reticula de corredores**: toda celda mundial con `wx % 6 === 0` o `wz % 6 === 0`
  (modulo matematico, tambien para negativos) es SIEMPRE caminable. Esto garantiza
  conectividad global infinita: los bloques 5x5 entre corredores contienen las salas.
- **Conectividad local**: toda celda caminable de un bloque alcanza la reticula por BFS
  de 4-vecinos (los tests lo verifican con ventana chunk+1 de margen).
- **Coherencia**: `isWalkable(seed, wx, wz)` === (`cells[...]` del chunk correspondiente
  `!== 0`), con `floor` correcto para coordenadas negativas.
- **Props de pared** (`stall|sink|mirror|urinal|dispenser`): ocupan celda NO caminable y
  tienen >=1 vecino 4-conexo caminable (su frente). **Props sueltos** (`bin|pipes`):
  sobre celda caminable.
- **Colision**: `resolveMovement` mueve un disco de radio `radius` (en celdas) separando
  ejes (primero x, luego z) para deslizar por paredes; nunca deja el disco invadiendo
  una celda no caminable ni atraviesa paredes con deltas grandes (clampear por pasos o
  por distancia al borde). Delta cero => posicion identica.
- **Ambiente**: los chunks deben sentirse como banos publicos infinitos: filas de
  cubiculos identicos (props `stall` en serie contigua a lo largo de paredes), paredes de
  lavabos con espejo (`sink` + `mirror` apareados), urinarios en fila, papeleras `bin`
  dispersas, `pipes` ocasionales, y regiones inundadas (tipo 4) que agrupen varias celdas
  contiguas. Densidad caminable global en (0.25, 0.85).

## Examples
- `generateChunk(20260711, 0, 0)` => chunk 18x18 con `cells.length === 324`, >=1 luz,
  >=1 charco, props mixtos; identico en llamadas repetidas.
- `isWalkable(20260711, 0, 0)` => `true` (celda de reticula: 0 % 6 === 0).
- `isWalkable(20260711, -6, 3)` => `true` (reticula con coordenada negativa).
- `resolveMovement(20260711, {x:0.5,z:0.5}, {x:0,z:0}, 0.3)` => `{x:0.5,z:0.5}`.
- `chunksInRadius(9.5, 9.5, 1)` => incluye `{cx:0,cz:0}` y sus 4 vecinos.

## Do / Don't
- DO: hash entero puro y rapido (se llama por celda); helpers privados los que hagan falta.
- DO: manejar coordenadas negativas con `Math.floor` y modulo matematico `((n%m)+m)%m`.
- DO: variar los bloques (salas de cubiculos, salas de lavabos, salas inundadas, bloques
  macizos) segun el hash para que perderse sea inevitable pero el mapa nunca bloquee.
- DON'T: estado mutable entre llamadas (sin caches que cambien resultados), sin I/O,
  sin DOM, sin dependencias, sin tocar nada fuera de `src/game/maze-core.mjs`.
- DON'T: editar `tests/game/maze-core.test.mjs` — si un test parece mal, PARA y reportalo.

## Ampliacion v3 (variedad de salas, obligatoria)
- Tipos de celda ampliados a 0..6: `5` = sala de duchas (caminable), `6` = cuarto de
  limpieza / vestuario (caminable). Ambos deben aparecer en la muestra de 25 chunks.
- Props nuevos: de pared `shower` (ducha) y `dryer` (secador de manos mural, tipico
  cerca de lavabos); sueltos `mop_bucket` (cubo de fregona con palo, en cuartos tipo 6)
  y `bench` (banco de vestuario, en salas 5/6). Mismas reglas que los existentes
  (pared = celda no caminable con vecino caminable; suelto = celda caminable).
- Coherencia tematica: duchas en filas dentro de salas tipo 5; mop_bucket/bench en
  salas tipo 6; dryer cerca de zonas de lavabos. Las salas nuevas conviven con las
  existentes sin romper reticula, conectividad ni densidades ya contratadas.

## Tests
Oraculo congelado en `tests/game/maze-core.test.mjs` (sellado por `tests_sha256`):
determinismo, forma del chunk, reticula de corredores, coherencia isWalkable/cells,
conectividad BFS, validez y ubicacion de props/luces/charcos, densidades, chunksInRadius,
y resolveMovement (sin tunel, deslizamiento, delta cero). Correr:
`node --test tests/game/maze-core.test.mjs` (desde la raiz del repo).

## Constraints
- ESM puro (`.mjs`), Node >= 18, cero dependencias, sin red, sin reloj, sin aleatoriedad
  no sembrada. Presupuesto de complejidad informativo: ciclomatica <= 12, anidado <= 4.
- Perimetro: SOLO `src/game/maze-core.mjs`.
- PARAR y reportar si un test congelado parece incorrecto o el contrato es inviable; no editarlo.
