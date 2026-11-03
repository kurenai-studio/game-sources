# Contrato 07 — Interfaz táctil y responsive

Prerrequisito: [Contrato 06](./CONTRACT-06-puzzle-difficulty.md) verificado.

## Objetivo

La interfaz debe ser jugable en teléfonos sin perder el acceso a la esfera, el
panel de objetivos ni los controles de selección.

## Criterios de aceptación

- [ ] En pantallas estrechas el panel no excede el ancho disponible ni tapa toda
  la esfera.
- [ ] El panel respeta las áreas seguras de dispositivos con notch.
- [ ] Botones y selector tienen un área táctil cómoda.
- [ ] El canvas permite gestos táctiles para rotar y no produce scroll de página.
- [ ] La escena mantiene selección, movimientos y desordenado en viewport móvil.
- [ ] `npm run ui:check`, `npm test`, `npm run check` y
  `python scripts/preflight.py` terminan correctamente.

## Restricciones

- No introducir una segunda interfaz ni duplicar las reglas del núcleo.
- Mantener el comportamiento de escritorio y los módulos Three.js locales.
