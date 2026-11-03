# Contrato 04 — Objetivos globales de color y número

Prerrequisito: [Contrato 03](./CONTRACT-03-puzzle-moves.md) verificado.
Este contrato añade una referencia visual inequívoca para las posiciones que
el jugador debe resolver.

## T1 — Numerar todas las caras

FIX/OBJETIVO: `createTargetLabels(topology)` devuelve una etiqueta para cada
cara del icosaedro base. Cada etiqueta contiene `faceId`, un número del 1 al 5,
un nombre de color legible y su valor de renderizado, asignados de forma
independiente. En cada vértice, las cinco caras incidentes tienen todos los
números exactamente una vez.

## T2 — Mostrar identidad de las esferas

FIX/OBJETIVO: todas las esferas muestran el color de su posición y su número
correspondiente. Las caras usan la misma paleta que sus esferas.

## T3 — Indicar posiciones correctas

FIX/OBJETIVO: una esfera objetivo emite un brillo verde cuando ocupa la cara
con el mismo identificador que su esfera; al moverla fuera de su posición el
brillo desaparece.

## Criterios de aceptación

- [ ] Cada cara tiene una etiqueta y los números usados son `1, 2, 3, 4, 5`.
- [ ] En cada vértice, los números incidentes son exactamente `1, 2, 3, 4, 5`.
- [ ] Los colores de cada cara y esfera coinciden.
- [ ] Un mismo color aparece con al menos dos números diferentes.
- [ ] El modo inicial usa `n=1`, con 20 caras y 19 esferas.
- [ ] `npm test`, `npm run ui:check`, `npm run check` y
  `python scripts/preflight.py` terminan correctamente.

## Restricciones

- El cálculo de etiquetas no depende de Three.js ni del DOM.
- La regla global se limita a `n=1`; no se cambia todavía la generación de
  niveles subdivididos, el mezclado, el temporizador ni la búsqueda óptima.
- No commitear.

## Checklist antes de delegar

- [x] La topología existente ya verifica vértices de grado 5.
- [x] El estado de movimientos permanece independiente de la representación.
- [x] Los criterios tienen verificaciones automáticas o visuales explícitas.
