# Contrato 02 — Vista 3D de la esfera triangular

Prerrequisito: [Contrato 01](./CONTRACT-01-triangular-sphere-core.md) verificado.
Este contrato conecta la topología pura con una escena Three.js sin introducir
reglas de movimiento todavía.

## T1 — Renderizar la esfera subdividida

Falta una superficie visible que permita inspeccionar la topología y sus colores.

FIX/OBJETIVO: la aplicación web renderiza una esfera triangular basada en la
topología `n=2`, con 80 caras, un color estable por hueco, esferas visibles y una
posición vacía identificable.

## T2 — Permitir inspección espacial

El jugador necesita poder buscar posiciones desde distintos ángulos.

FIX/OBJETIVO: la escena permite rotación orbital mediante arrastre, zoom mediante
rueda y selección de una cara mediante clic, mostrando la cara seleccionada en
la interfaz.

## Criterios de aceptación

- [ ] `npm run ui:check` termina con exit 0.
- [ ] `npm run dev` sirve `public/index.html` y los módulos locales sin errores HTTP.
- [ ] La página contiene una escena Three.js con una cámara, iluminación, control
  orbital y exactamente 80 caras triangulares renderizadas.
- [ ] Se muestran 79 esferas y una cara vacía.
- [ ] Arrastrar rota la cámara alrededor de la esfera y la rueda cambia el zoom.
- [ ] Hacer clic sobre una cara actualiza el identificador de cara visible en la UI.
- [ ] La escena no depende de una CDN ni de un backend.
- [ ] `npm test`, `npm run check` y `python scripts/preflight.py` siguen verdes.

## Restricciones

- Tocar SOLO: `public/index.html`, `src/ui/app.mjs`, `scripts/serve.mjs`,
  `package.json`, `package-lock.json` y este contrato.
- Reutilizar `createTriangularSphere` de `src/core/triangular-sphere.mjs`; no
  duplicar la generación de caras ni sus adyacencias.
- No implementar todavía movimientos, mezclado, temporizador, puntuación ni
  resolución.
- No commitear. Si algo no se puede sin romper otro criterio, PARAR y reportar.
- ABORTAR SI: Three.js exige red durante la ejecución, la escena no puede cargar
  los módulos locales, o la topología visual no coincide con el núcleo verificado;
  documentar la evidencia y marcar BLOQUEADO.

## Checklist antes de delegar

- [x] RECON corrido: Three.js instalado localmente, contrato anterior verificado,
  Node disponible y entregables comprobados como libres.
- [x] Cada criterio de aceptación tiene comando o interacción observable.
- [x] Red-team hecho: servir HTML no basta; el smoke check y la inspección visual
  deben confirmar que la escena contiene la topología real.
- [x] Perímetro declarado y disjunto del núcleo anterior.
- [x] Condiciones de aborto explícitas.
