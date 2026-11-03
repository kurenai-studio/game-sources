# Contrato 05 — Inicio mediante desorden legal

Prerrequisito: [Contrato 03](./CONTRACT-03-puzzle-moves.md) verificado.
Este contrato separa el tablero resuelto de la partida jugable.

## T1 — Mantener la referencia resuelta

FIX/OBJETIVO: la aplicación inicia mostrando el estado resuelto, con el hueco
visible, para demostrar la correspondencia entre cada esfera y su objetivo.

## T2 — Desordenar mediante movimientos válidos

FIX/OBJETIVO: `shufflePuzzle(state, steps, random)` genera un nuevo estado
alcanzable aplicando movimientos legales al estado recibido. No muta el estado
anterior, conserva un solo hueco y reinicia el contador de movimientos para la
partida.

## T3 — Iniciar desde la interfaz

FIX/OBJETIVO: el botón `Desordenar puzzle` inicia la partida, actualiza las
posiciones visuales y deja el contador en cero. Antes de pulsarlo, el estado se
ve resuelto y el usuario recibe una instrucción clara.

## Criterios de aceptación

- [ ] La carga inicial muestra `isSolved(state) === true` y cero movimientos.
- [ ] Desordenar produce un estado no resuelto mediante movimientos legales.
- [ ] Desordenar no muta el estado resuelto de referencia.
- [ ] El contador de la partida comienza en cero después de desordenar.
- [ ] Resolver el tablero después de comenzar muestra el estado resuelto.
- [ ] `npm test`, `npm run ui:check`, `npm run check` y
  `python scripts/preflight.py` terminan correctamente.

## Restricciones

- El desorden no intercambia esferas arbitrariamente: solo usa la regla de
  adyacencia existente.
- No se implementan todavía temporizador, puntuación ni solución mínima.
- No commitear.
