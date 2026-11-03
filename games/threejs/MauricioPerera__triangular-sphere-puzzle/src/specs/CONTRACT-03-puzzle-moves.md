# Contrato 03 — Estado y movimientos del rompecabezas

Prerrequisito: [Contrato 02](./CONTRACT-02-threejs-sphere-view.md) verificado.
Este contrato convierte la topología en un tablero jugable sin mezclar reglas
con Three.js.

## T1 — Representar el estado resuelto

Falta una representación de las esferas, el hueco vacío y el contador de
movimientos.

FIX/OBJETIVO: `createPuzzleState(topology, emptyFaceId)` crea un estado
determinista con una esfera por cada cara ocupada, identidad de esfera igual al
color de su cara en el estado resuelto, una cara vacía y cero movimientos.

## T2 — Aplicar movimientos adyacentes

Falta hacer cumplir la regla de que una esfera solo puede desplazarse al hueco
si su cara comparte una arista con la cara vacía.

FIX/OBJETIVO: `applyMove(state, fromFaceId)` devuelve un nuevo estado cuando el
movimiento es legal y devuelve el mismo estado cuando es ilegal; nunca muta el
estado recibido.

## T3 — Detectar resolución

Falta una consulta independiente de la interfaz para saber cuándo las esferas
coinciden con sus colores.

FIX/OBJETIVO: `isSolved(state)` devuelve `true` cuando cada esfera ocupada está
en la cara cuyo identificador coincide con el suyo y `false` después de un
movimiento que altera esa correspondencia.

## Criterios de aceptación

- [ ] `npm test` termina con exit 0 y todos los tests del núcleo pasan.
- [ ] El estado inicial tiene exactamente una cara vacía, cero movimientos y
  `isSolved(state) === true`.
- [ ] Un movimiento hacia una cara vecina intercambia esfera y hueco, incrementa
  el contador y no muta el estado anterior.
- [ ] Un movimiento hacia una cara no vecina no cambia el estado ni el contador.
- [ ] Un movimiento con identificador de cara inexistente lanza `RangeError`.
- [ ] Aplicar un movimiento legal y deshacerlo devuelve al estado resuelto.
- [ ] `npm run ui:check`, `npm run check` y `python scripts/preflight.py` siguen
  verdes.

## Restricciones

- Tocar SOLO: `src/core/puzzle-state.mjs`, `tests/puzzle-state.test.mjs`,
  `src/ui/app.mjs`, `public/index.html`, `package.json`, `package-lock.json` y
  este contrato.
- El núcleo no puede importar Three.js ni acceder al DOM.
- Los estados son inmutables desde la perspectiva del consumidor.
- No implementar todavía mezclado aleatorio, temporizador, puntuación ni
  búsqueda de solución mínima.
- No commitear. Si algo no se puede sin romper otro criterio, PARAR y reportar.
- ABORTAR SI: el movimiento requiere conocer coordenadas de pantalla, el núcleo
  necesita mutar el estado anterior, o la regla de adyacencia no puede derivarse
  de la topología verificada; documentar evidencia y marcar BLOQUEADO.

## Checklist antes de delegar

- [x] RECON corrido: contratos 01/02, suite Node, UI local y gates KDD fueron
  comprobados.
- [x] Entregables comprobados como libres antes de asignarlos.
- [x] Criterios con comandos o propiedades verificables.
- [x] Red-team hecho: se comprueban no-mutación, movimientos ilegales y undo,
  no solamente que el contador incremente.
- [x] Perímetro declarado.
- [x] Condiciones de aborto explícitas.
