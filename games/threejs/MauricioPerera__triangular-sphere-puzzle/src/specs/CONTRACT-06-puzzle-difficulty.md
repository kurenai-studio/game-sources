# Contrato 06 — Niveles de dificultad

Prerrequisito: [Contrato 05](./CONTRACT-05-shuffle-start.md) verificado.

## T1 — Seleccionar profundidad de desorden

FIX/OBJETIVO: la interfaz ofrece cuatro niveles con una cantidad creciente de
movimientos legales de mezcla: fácil 10, medio 25, difícil 40 y experto 60.

## T2 — Bloquear la configuración durante la partida

FIX/OBJETIVO: el selector de dificultad y el botón de desordenar están
disponibles cuando el tablero está resuelto y se deshabilitan después de
iniciar la partida. Ambos vuelven a habilitarse al resolverla.

## Criterios de aceptación

- [ ] El nivel medio es la opción inicial.
- [ ] El selector usa exactamente las profundidades 10, 25, 40 y 60.
- [ ] Cambiar el nivel no altera el tablero hasta pulsar desordenar.
- [ ] Selector y botón quedan bloqueados durante una partida.
- [ ] Resolver el tablero los habilita de nuevo.
- [ ] `npm run ui:check`, `npm test`, `npm run check` y
  `python scripts/preflight.py` terminan correctamente.

## Restricciones

- La profundidad no implica todavía distancia óptima respecto del estado
  resuelto; el mezclado sigue siendo una secuencia legal no reversible de forma
  inmediata.
- No se implementan todavía temporizador, puntuación ni búsqueda mínima.
