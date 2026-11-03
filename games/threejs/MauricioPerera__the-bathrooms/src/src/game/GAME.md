---
version: "0.1"
name: The Bathrooms
profile: voxel
description: "Mundo liminal de baños infinitos capturado en VHS: azulejos enfermizos, moho, luz fluorescente muerta. Sin objetivos, sin salida."
platform:
  chunkSize: 18
  cellSize: 2
  wallHeight: 3
  playerSpeed: 3.4
  playerRadius: 0.3
  viewChunks: 2
  eyeHeight: 1.6
  audio: { refDist: 4, maxDist: 28 }
  texts: { title: "The Bathrooms", rec: "REC", hint: "WASD para caminar, mouse para mirar, Shift para correr" }
materials:
  TILE_WALL: { color: [150, 156, 130] }
  TILE_FLOOR: { color: [120, 122, 102] }
  GROUT: { color: [66, 64, 52] }
  STALL: { color: [104, 122, 98] }
  PORCELAIN: { color: [226, 224, 212] }
  MIRROR: { color: [98, 122, 120] }
  WATER: { color: [88, 108, 98] }
  MOLD: { color: [52, 66, 44] }
  GRIME: { color: [92, 80, 64] }
  CEILING: { color: [176, 172, 150] }
  LIGHT_ON: { color: [232, 228, 180] }
  LIGHT_DEAD: { color: [110, 112, 108] }
  PAPER: { color: [214, 210, 196] }
  PIPE: { color: [104, 106, 102] }
  METAL: { color: [126, 128, 124] }
  TRASH: { color: [72, 68, 56] }
  CURTAIN: { color: [178, 176, 158] }
  RUST: { color: [120, 78, 54] }
prefabs:
  wall_slab: { size: [8, 9, 1], fill: TILE_WALL }
  floor_slab: { size: [8, 1, 8], fill: TILE_FLOOR }
  ceiling_slab: { size: [8, 1, 8], fill: CEILING }
  toilet_tank: { size: [4, 5, 2], fill: PORCELAIN }
  toilet_bowl: { size: [4, 3, 3], fill: PORCELAIN }
  toilet_seat: { size: [4, 1, 4], fill: PORCELAIN }
  toilet_foot: { size: [2, 1, 2], fill: PORCELAIN }
  stall_side: { size: [1, 9, 8], fill: STALL }
  stall_back: { size: [8, 9, 1], fill: STALL }
  stall_door: { size: [4, 7, 1], fill: STALL }
  sink_basin: { size: [6, 2, 4], fill: PORCELAIN }
  faucet_stem: { size: [1, 2, 1], fill: METAL }
  faucet_spout: { size: [1, 1, 2], fill: METAL }
  mirror_panel: { size: [6, 5, 1], fill: MIRROR, cells: [{ x: 0, y: 0, z: 0, m: MOLD }, { x: 5, y: 0, z: 0, m: MOLD }, { x: 0, y: 4, z: 0, m: MOLD }, { x: 5, y: 4, z: 0, m: MOLD }] }
  urinal_back: { size: [4, 6, 1], fill: PORCELAIN }
  urinal_basin: { size: [4, 3, 2], fill: PORCELAIN }
  urinal_lip: { size: [4, 1, 1], fill: PORCELAIN }
  pipe_segment: { size: [1, 4, 1], fill: PIPE }
  pipe_short: { size: [1, 3, 1], fill: PIPE }
  grime_patch: { size: [2, 1, 1], fill: GRIME }
  grime_streak: { size: [1, 3, 1], fill: GRIME }
  water_puddle: { size: [4, 1, 4], fill: WATER }
  water_pool: { size: [3, 1, 3], fill: WATER }
  bin_body: { size: [4, 5, 4], fill: METAL }
  paper_heap: { size: [3, 2, 3], fill: PAPER }
  paper_wad: { size: [1, 1, 1], fill: PAPER }
  dispenser_box: { size: [3, 4, 1], fill: METAL }
  light_tube: { size: [6, 1, 1], fill: LIGHT_ON }
  light_tube_dead: { size: [6, 1, 1], fill: LIGHT_DEAD }
  shower_tray: { size: [6, 1, 6], fill: PORCELAIN }
  shower_riser: { size: [1, 8, 1], fill: METAL }
  shower_head: { size: [2, 1, 2], fill: METAL }
  shower_rail: { size: [6, 1, 1], fill: METAL }
  shower_curtain: { size: [6, 5, 1], fill: CURTAIN, cells: [{ x: 0, y: 0, z: 0, m: MOLD }, { x: 5, y: 1, z: 0, m: GRIME }, { x: 2, y: 0, z: 0, m: GRIME }] }
  dryer_body: { size: [4, 3, 2], fill: METAL }
  dryer_hood: { size: [2, 1, 2], fill: METAL }
  dryer_nozzle: { size: [2, 1, 1], fill: METAL }
  bucket_body: { size: [4, 4, 3], fill: METAL, cells: [{ x: 0, y: 1, z: 1, m: RUST }, { x: 3, y: 2, z: 1, m: RUST }, { x: 1, y: 0, z: 0, m: RUST }] }
  bucket_water: { size: [3, 1, 2], fill: WATER }
  mop_seg: { size: [1, 1, 1], fill: PIPE }
  mop_head: { size: [2, 2, 1], fill: GRIME }
  bench_board: { size: [12, 1, 3], fill: STALL }
  bench_leg: { size: [2, 2, 3], fill: METAL }
structures:
  toilet_unit:
    place: [{ prefab: toilet_foot, at: [1, 0, 3] }, { prefab: toilet_tank, at: [0, 3, 0] }, { prefab: toilet_bowl, at: [0, 1, 2] }, { prefab: toilet_seat, at: [0, 4, 2] }, { prefab: water_pool, at: [0, 0, 2] }, { prefab: grime_patch, at: [1, 2, 4] }, { prefab: grime_streak, at: [3, 3, 1] }]
  stall_unit:
    place: [{ prefab: floor_slab, at: [0, 0, 0] }, { prefab: stall_side, at: [0, 1, 0] }, { prefab: stall_side, at: [7, 1, 0] }, { prefab: stall_back, at: [0, 1, 0] }, { prefab: stall_door, at: [1, 3, 7] }, { prefab: toilet_tank, at: [2, 1, 1] }, { prefab: toilet_bowl, at: [2, 1, 3] }, { prefab: toilet_seat, at: [2, 4, 3] }, { prefab: water_pool, at: [1, 0, 4] }]
  sink_unit:
    place: [{ prefab: mirror_panel, at: [1, 8, 0] }, { prefab: sink_basin, at: [1, 4, 1] }, { prefab: faucet_stem, at: [3, 6, 1] }, { prefab: faucet_spout, at: [3, 6, 2] }, { prefab: water_pool, at: [2, 5, 1] }, { prefab: pipe_segment, at: [3, 0, 2] }, { prefab: grime_streak, at: [1, 1, 4] }]
  urinal_unit:
    place: [{ prefab: wall_slab, at: [0, 0, 0] }, { prefab: urinal_back, at: [2, 3, 1] }, { prefab: urinal_basin, at: [2, 3, 2] }, { prefab: urinal_lip, at: [2, 3, 3] }, { prefab: water_pool, at: [2, 4, 2] }, { prefab: pipe_short, at: [3, 0, 1] }, { prefab: grime_streak, at: [3, 1, 1] }]
  bin_full:
    place: [{ prefab: bin_body, at: [2, 0, 2] }, { prefab: paper_heap, at: [2, 5, 2] }, { prefab: paper_wad, at: [1, 0, 2] }, { prefab: paper_wad, at: [5, 0, 3] }, { prefab: paper_wad, at: [2, 0, 6] }, { prefab: paper_wad, at: [4, 1, 1] }, { prefab: paper_wad, at: [1, 0, 5] }, { prefab: paper_wad, at: [6, 1, 5] }]
  dispenser_empty:
    place: [{ prefab: dispenser_box, at: [2, 5, 0] }, { prefab: paper_wad, at: [3, 4, 0] }, { prefab: grime_streak, at: [3, 2, 0] }]
  light_fixture:
    place: [{ prefab: ceiling_slab, at: [0, 1, 0] }, { prefab: light_tube, at: [1, 0, 2] }, { prefab: light_tube_dead, at: [1, 0, 4] }]
  shower_unit:
    place: [{ prefab: wall_slab, at: [0, 0, 0] }, { prefab: shower_tray, at: [1, 0, 1] }, { prefab: shower_riser, at: [1, 1, 0] }, { prefab: shower_head, at: [1, 7, 1] }, { prefab: shower_rail, at: [1, 7, 5] }, { prefab: shower_curtain, at: [1, 2, 5] }, { prefab: water_pool, at: [2, 0, 2] }, { prefab: grime_streak, at: [1, 3, 1] }]
  dryer_unit:
    place: [{ prefab: wall_slab, at: [0, 0, 0] }, { prefab: dryer_body, at: [2, 3, 1] }, { prefab: dryer_hood, at: [3, 6, 1] }, { prefab: dryer_nozzle, at: [3, 2, 1] }, { prefab: grime_streak, at: [3, 0, 1] }]
  mop_bucket:
    place: [{ prefab: bucket_body, at: [1, 0, 1] }, { prefab: bucket_water, at: [1, 3, 1] }, { prefab: mop_seg, at: [4, 3, 2] }, { prefab: mop_seg, at: [4, 4, 2] }, { prefab: mop_seg, at: [5, 5, 2] }, { prefab: mop_seg, at: [5, 6, 2] }, { prefab: mop_seg, at: [6, 7, 2] }, { prefab: mop_head, at: [5, 7, 2] }, { prefab: water_puddle, at: [0, 0, 4] }]
  bench_unit:
    place: [{ prefab: bench_board, at: [0, 2, 0] }, { prefab: bench_leg, at: [1, 0, 0] }, { prefab: bench_leg, at: [8, 0, 0] }, { prefab: grime_patch, at: [4, 2, 0] }]
---

## Overview

**The Bathrooms** es un mundo liminal: una red de aseos públicos que no termina
nunca. No hay objetivos, no hay puntuación, no hay salida. Solo caminás por
pasillos de azulejo bajo tubos fluorescentes que zumban, algunos muertos, y todo
se ve como una cinta VHS de tercera generación: grano, sangrado de color, la
palabra `REC` temblando en una esquina.

Este documento es la fuente de verdad del **contenido** del juego (perfil `voxel`
del GAME Protocol): materiales, piezas voxel reutilizables (`prefabs`) y el
mobiliario del baño compuesto por referencia (`structures`). El motor 3D consume
el artefacto compilado `game-data.generated.js` (`window.GAME`), nunca este `.md`.
El trazado del laberinto infinito y el render son de otros contratos: acá no hay
lógica, solo datos.

Escala voxel: **8 voxeles = 1 celda = 2 m**, es decir **1 voxel = 0,25 m**. Las
estructuras se mantienen por debajo de 24 voxeles por eje (unas 3 celdas), lo
justo para una pieza de mobiliario.

**Orientación (convención v2):** TODAS las estructuras se diseñan mirando a **+z**
(su frente hacia +z, rotación 0): la pared va en `z = 0` y la pieza sobresale o se
abre hacia `+z`. El motor rota cada estructura para que ese frente mire al espacio
caminable. Así una sola definición sirve para las cuatro paredes.

Knobs de `platform`: mundo en chunks de 18 celdas, paso de jugador contenido
(3,4 m/s) y vista corta (2 chunks) para reforzar el encierro; audio con caída de
4 a 28 m para que el goteo y el zumbido se pierdan a la vuelta de cada esquina.

## Materials

Paleta deliberadamente **enferma y desaturada**. Nada alegre, nada saturado: es la
luz fluorescente amarillenta rebotando sobre superficies sucias. En v2 los
azulejos y el piso se **oscurecieron** y la `PORCELAIN` se **aclaró** a propósito:
así el mobiliario (retretes, urinarios, lavabos) resalta como manchas claras
contra paredes oscuras y se **reconoce a 4-6 m** bajo la luz muerta.

- `TILE_WALL` / `TILE_FLOOR`: azulejo apagado amarillento-verdoso, oscurecido para
  que la porcelana clara contraste.
- `GROUT`: la lechada entre azulejos, casi negra de mugre.
- `STALL`: la chapa/partición de los cubículos, verde institucional apagado, un
  valor claramente distinto de la pared (para que la puerta se lea como puerta).
- `PORCELAIN`: blanco roto, el material MÁS claro de la paleta; tazas, lavabos y
  urinarios se recortan contra el fondo.
- `MIRROR`: cristal turbio verdoso; refleja mal a propósito.
- `WATER`: agua estancada, turbia, ni azul ni limpia.
- `MOLD`: moho verde-negro que trepa por esquinas y juntas.
- `GRIME`: churretes marrón-grises que bajan de grifos, tazas y dispensadores.
- `CEILING`: plafón amarilleado por la nicotina de la luz.
- `LIGHT_ON` / `LIGHT_DEAD`: tubo encendido (amarillo enfermo) y tubo muerto (gris).
- `PAPER`: papel higiénico/toallas apelmazadas, blanco sucio.
- `PIPE` / `METAL` / `TRASH`: cañerías corroídas, chapa mate y desperdicio oscuro.
- `CURTAIN` (v3): la cortina de ducha, plástico pálido sucio a medio caer; más claro
  que la pared pero manchado (esquinas de `MOLD`/`GRIME`), nunca blanco limpio.
- `RUST` (v3): óxido marrón-naranja apagado que corroe el cubo de fregona y los metales;
  desaturado, enfermo, jamás vivo.

## Prefabs

Piezas voxel reutilizables, cada una con `size: [w, h, d]` entero y relleno `fill`
(o `cells` para detalles). Se combinan por referencia en `structures` para no
redibujar geometría:

- Superficies: `wall_slab`, `floor_slab`, `ceiling_slab`.
- Retrete (compartido por `toilet_unit` y `stall_unit`): `toilet_tank` (mochila
  alta atrás), `toilet_bowl` (taza baja que sobresale al frente), `toilet_seat`
  (asiento que vuela sobre la taza) y `toilet_foot` (pie al piso).
- Cubículo: `stall_side`, `stall_back`, `stall_door` (hoja parcial, entreabierta).
- Lavabo: `sink_basin` (pileta que sobresale), `faucet_stem` + `faucet_spout`
  (grifo `METAL`), `mirror_panel` (espejo grande con esquinas `MOLD` vía `cells`).
- Urinario: `urinal_back` (cuerpo vertical mural), `urinal_basin` (cuenco que
  sobresale), `urinal_lip` (borde que asoma).
- Suciedad y agua: `grime_patch`, `grime_streak` (churrete vertical), `water_puddle`,
  `water_pool`.
- Cesto y dispensador: `bin_body`, `paper_heap`, `paper_wad`, `dispenser_box`.
- Luz: `light_tube`, `light_tube_dead`.
- Ducha (v3): `shower_tray` (plato bajo `PORCELAIN` en el piso), `shower_riser` (columna
  mural), `shower_head` (regadera que asoma), `shower_rail` (barra superior) y
  `shower_curtain` (cortina `CURTAIN` a medio caer con esquinas de `MOLD`/`GRIME`).
- Secador de manos (v3): `dryer_body` (caja `METAL` mural), `dryer_hood` (remate más
  angosto que redondea la silueta) y `dryer_nozzle` (boca inferior que asoma abajo).
- Fregona (v3): `bucket_body` (cubo `METAL` con óxido `RUST` vía `cells`), `bucket_water`
  (agua turbia `WATER` al ras), `mop_seg` (segmento de palo `PIPE`, se escalona en
  diagonal para el palo inclinado) y `mop_head` (cabeza `GRIME` sucia).
- Banco de vestuario (v3): `bench_board` (tabla larga `STALL`) y `bench_leg` (pata `METAL`).

## Structures

Composiciones por referencia (`place`: prefab + offset `at`). El motor instancia
cada una por su nombre exacto. Todas miran a **+z** (pared en `z = 0`):

- `toilet_unit` (**nueva, exento**): silueta inequívoca de retrete — `toilet_tank`
  alto contra el fondo, `toilet_bowl` bajo que sobresale hacia el frente, `toilet_seat`
  volando encima y `toilet_foot` al piso; `PORCELAIN` clara con un `water_pool` turbio
  y manchas `GRIME`. Es la pieza que faltaba y por la que el usuario "no distinguía
  qué eran las cosas".
- `stall_unit`: cubículo legible — mamparas `stall_side` y fondo `stall_back` completos
  hasta ~2,2 m (9 voxeles), `stall_door` **parcial y entreabierta** en el frente
  dejando un **hueco inferior de 2 voxeles** (se ve piso/luz por debajo) y una rendija
  lateral; dentro, el retrete (`toilet_tank` + `toilet_bowl` + `toilet_seat`) **asoma**
  por la rendija y por el hueco, con `water_pool` en el piso.
- `sink_unit`: `sink_basin` `PORCELAIN` que **sobresale claramente** de la pared a
  altura de cintura, grifo `METAL` (`faucet_stem` + `faucet_spout`) encima, `mirror_panel`
  grande arriba con esquinas de `MOLD`, `water_pool` turbia en la pileta, `pipe_segment`
  de desagüe abajo y un churrete `grime_streak`.
- `urinal_unit`: cuenco mural a media altura — `urinal_back` vertical montado en la
  pared (`wall_slab` oscuro detrás para contraste), `urinal_basin` que sobresale con su
  `urinal_lip`, agua turbia, `pipe_short` de desagüe abajo y mugre bajando.
- `bin_full`: `bin_body` alto desbordado, `paper_heap` amontonado encima y `paper_wad`
  derramados por el piso alrededor.
- `dispenser_empty`: `dispenser_box` mural a la altura de la mano, con la última hoja
  `paper_wad` colgando y un churrete `grime_streak` seco debajo.
- `light_fixture`: plafón `ceiling_slab` con un `light_tube` encendido y otro
  `light_tube_dead` al lado — la mitad de la luz siempre está muerta.
- `shower_unit` (**v3**): plato de ducha `shower_tray` bajo en el piso, `shower_riser`
  mural con `shower_head` arriba, `shower_rail` cruzando el frente y una `shower_curtain`
  `CURTAIN` **a medio caer** colgando de la barra; agua turbia y churrete `grime_streak`.
  La cortina pálida y sucia recorta la silueta de ducha contra la pared oscura.
- `dryer_unit` (**v3**): secador de manos mural — `dryer_body` `METAL` compacto a media
  altura, `dryer_hood` más angosto que **redondea** la caja y `dryer_nozzle` como **boca
  inferior visible** debajo; churrete seco bajo la boca. Silueta de caja redondeada.
- `mop_bucket` (**v3**): `bucket_body` `METAL` oxidado (`RUST`) con `bucket_water` turbia
  al ras, el palo de fregona (`mop_seg` escalonados en diagonal) **inclinado y apoyado**
  saliendo del cubo hasta la `mop_head` sucia; charco `water_puddle` derramado al lado.
- `bench_unit` (**v3**): banco bajo de vestuario — `bench_board` `STALL` larga apoyada
  sobre dos `bench_leg` `METAL`, con una mancha `GRIME` encima. Contrasta contra el piso.

## Do's and Don'ts

- **DO** reusar prefabs dentro de `structures` por referencia: esa es la gracia del
  perfil voxel (el retrete se define una vez y se coloca en `toilet_unit` y en
  `stall_unit`).
- **DO** diseñar mirando a `+z` (pared en `z = 0`, la pieza sobresale/abre hacia `+z`):
  el motor rota cada estructura hacia el espacio caminable.
- **DO** mantener contraste de material: `PORCELAIN` clara contra pared/piso oscuros,
  `STALL` distinta de la pared. Si el mobiliario "se pierde" contra el fondo, está mal.
- **DO** mantener la dirección de arte liminal: superficies sucias, luz enferma, cero
  color alegre o saturado. Si un material se ve "limpio", está mal.
- **DO** respetar el subset YAML del protocolo: listas de flujo en una línea y comas
  dentro de texto siempre entre comillas (ver `texts.hint`).
- **DON'T** meter lógica en los datos: el laberinto infinito, la cámara, el filtro
  VHS y el `REC` parpadeante son código del motor, no de este `.md`.
- **DON'T** editar a mano `game-data.generated.js`: se regenera con
  `game-export.js` y el test lo valida.
- **DON'T** dar objetivos, premios ni salida: The Bathrooms no se gana, se recorre.
