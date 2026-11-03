---
type: 'Task Contract'
title: 'GAME.md de The Bathrooms (contenido como datos, perfil voxel)'
description: 'Documento GAME.md del protocolo (perfil voxel) con toda la identidad visual y de contenido del juego: paleta de materiales enfermizos, prefabs low-poly de mobiliario de bano, knobs de mundo/jugador/audio en platform y textos.'
tags: ['bathrooms', 'game-protocol', 'data', 'game']

task: game-md-bathrooms
intent: "Declarar el contenido y balance de The Bathrooms como datos GAME.md (perfil voxel) que lintean y exportan en verde."
target: src/game/GAME.md
signature: "GAME.md (front-matter YAML, profile: voxel) - contrato de datos, sin funcion"
test_command: "node vendor/game-protocol/tools/game-lint.js src/game/GAME.md && node vendor/game-protocol/tools/game-export.js src/game/GAME.md src/game/game-data.generated.js && node --test tests/game/game-md.test.mjs"
budget:
  max_cyclomatic_complexity: 1
  max_nesting_depth: 1
tests: "tests/game/game-md.test.mjs"
tests_sha256: "952c31ccfd9a27d743d4304491ad727a12778eb03f7b041ef334c5c772571789"
touch_only: ['src/game/GAME.md', 'src/game/game-data.generated.js']
deps_allowed: []
forbids: ['network', 'editar vendor/', 'editar los tests congelados']
---

# Contract: game-md-bathrooms

## Intent
"Gameplay as Data": todo el contenido visual y de balance de The Bathrooms vive en un
unico `src/game/GAME.md` (perfil `voxel` del GAME Protocol vendoreado, ver
[nodo del protocolo](../game-protocol.md)) — paleta de materiales, prefabs voxel
low-poly del mobiliario del bano, knobs del mundo y textos. El motor 3D consume el
artefacto compilado `game-data.generated.js` (`window.GAME`), nunca el .md.

## Interface
Front-matter YAML de `src/game/GAME.md` (subset YAML del protocolo: mapas de bloque,
mapas/listas de flujo en una linea; SIN `- item` de bloque):
- `version: "0.1"`, `name: The Bathrooms`, `profile: voxel`.
- `platform:` (meta universal, se copia verbatim al artefacto) con:
  `chunkSize: 18`, `cellSize: 2`, `wallHeight` en [2.5,4], `playerSpeed` en (0,8],
  `playerRadius` en (0.1,0.5), `viewChunks` en [1,3] (entero), `eyeHeight` en [1.4,1.8],
  `audio: { refDist: >0, maxDist: >refDist y <=60 }`,
  `texts: { title: The Bathrooms, rec: REC, hint: <instrucciones de control, >=10 chars> }`.
- `materials:` >= 13 materiales `NOMBRE: { color: [r,g,b] }` 0..255, incluyendo
  EXACTAMENTE estos nombres (mas los que hagan falta): `TILE_WALL, TILE_FLOOR, GROUT,
  STALL, PORCELAIN, MIRROR, WATER, MOLD, GRIME, CEILING, LIGHT_ON, LIGHT_DEAD, PAPER`.
- `prefabs:` piezas voxel reutilizables (resolucion: 8 voxeles = 1 celda = 2m,
  1 voxel = 0.25m). `size: [w,h,d]` enteros; `fill` y/o `cells`.
- `structures:` composiciones por referencia. REQUERIDAS (el motor las instancia por
  nombre): `stall_unit` (cubiculo de uso independiente: mamparas completas, puerta
  entreabierta con luz de piso, retrete visible adentro), `sink_unit` (lavabo + espejo),
  `urinal_unit` (pieza mural reconocible a media altura), `toilet_unit` (retrete exento:
  mochila + taza + asiento), `bin_full` (papelera desbordada de papel), `dispenser_empty`
  (dispensador vacio), `light_fixture` (tubo fluorescente de techo). Cada una con
  `count > 0` y extension < 24 voxeles por eje.

## Invariants
- `node vendor/game-protocol/tools/game-lint.js src/game/GAME.md` termina exit 0 con
  `"errors": 0` (warnings 0 idealmente).
- El export produce `game-data.generated.js` cuyo `window.GAME` cumple el oraculo:
  perfil/name correctos, materiales requeridos con RGB valido, estructuras requeridas
  no vacias y acotadas, refs de materiales resueltas, knobs de `platform` en rango.
- **Direccion de arte (cuerpo del .md y eleccion de colores)**: liminal, repulsivo,
  enfermizo. Azulejos palidos amarillentos/verdosos con lechada oscurecida, moho,
  mugre, porcelana manchada, agua turbia, luz fluorescente amarillenta. NADA de colores
  alegres o saturados.
- **Legibilidad (feedback v2 del usuario)**: las estructuras deben RECONOCERSE como
  mobiliario de bano a 4-6 m bajo luz fluorescente tenue: proporciones inequivocas
  (retrete = mochila alta + taza baja que sobresale; urinario = cuenco mural a media
  altura; lavabo = pileta que sobresale de la pared con espejo encima; cubiculo =
  mamparas hasta ~2.2 m con puerta y hueco inferior de ~2 voxeles) y CONTRASTE fuerte de
  material (PORCELAIN clara contra pared oscura; puertas STALL distintas de la pared).
  Todas las estructuras se disenan mirando a +z (rot 0): el motor las rota hacia el
  espacio caminable.
- El cuerpo Markdown documenta cada seccion del perfil (`Overview`, `Materials`,
  `Prefabs`, `Structures`, `Do's and Don'ts`) como doc canonica de diseno del juego.

## Examples
- `stall_unit`: paredes laterales STALL de ~9 voxeles de alto sobre pata, puerta STALL
  ligeramente entreabierta o cerrada, taza PORCELAIN con tapa; hueco visible.
- `sink_unit`: pileta PORCELAIN con manchas GRIME, espejo MIRROR con esquinas MOLD,
  caneria PIPE debajo.
- `bin_full`: cesto METAL/TRASH desbordado con voxeles PAPER derramados alrededor.

## Do / Don't
- DO: reusar prefabs dentro de structures por referencia (esa es la gracia del perfil).
- DO: respetar el subset YAML del protocolo (comas dentro de texto de flujo, entre comillas).
- DON'T: tocar `vendor/` ni los tests congelados; no editar el artefacto generado a mano
  (se regenera con el export; el test lo valida).
- DON'T: logica en los datos — el layout del laberinto y el render son de otros contratos.

## Ampliacion v3 (estructuras de variedad de salas, obligatoria)
- Estructuras nuevas requeridas: `shower_unit` (plato de ducha + regadera mural +
  cortina a medio caer o barra), `dryer_unit` (secador de manos mural METAL a media
  altura, boca abajo), `mop_bucket` (cubo con agua sucia y palo de fregona), `bench_unit`
  (banco bajo de vestuario sobre patas). Mismas reglas de legibilidad y orientacion
  (+z) que v2; materiales nuevos permitidos (p.ej. CURTAIN, RUST) manteniendo la
  direccion de arte enfermiza.

## Tests
Oraculo congelado en `tests/game/game-md.test.mjs` (sellado por `tests_sha256`).
El `test_command` encadena: lint del protocolo -> export -> tests de claves del artefacto.
Correr desde la raiz del repo.

## Constraints
- Sin red; solo editar `src/game/GAME.md` y regenerar `src/game/game-data.generated.js`
  con el export del protocolo. Budget informativo (es un contrato de datos).
- PARAR y reportar si el subset YAML del protocolo no alcanza para declarar algo requerido, o si un test congelado parece incorrecto.
