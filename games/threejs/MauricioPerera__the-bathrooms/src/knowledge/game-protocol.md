---
type: 'Concept'
title: 'GAME Protocol (toolchain vendoreado)'
description: 'Integración del GAME Protocol v2.18.0 en este proyecto: dónde vive el toolchain vendoreado, comandos de lint/export/test verificados, y cómo lo referencian los contratos KDD del juego.'
tags: ['game-protocol', 'toolchain', 'reference']
---

# GAME Protocol — toolchain vendoreado

Este proyecto crea un juego usando el [GAME Protocol](https://mauricioperera.github.io/game-protocol/) ("Gameplay as Data"): el contenido y balance del juego se declara como datos en un único `GAME.md` (YAML front-matter + Markdown), validado y compilado por CLI. La lógica/render del motor sigue en código.

## Dónde vive

El repo completo del protocolo (release `v2.18.0`) está vendoreado en [`vendor/game-protocol/`](../vendor/game-protocol/), sin historial git. Piezas clave:

- `vendor/game-protocol/SPEC.md` — especificación core normativa (formato de archivo, gramática YAML soportada, pipeline lint→export→consume, perfiles de dominio).
- `vendor/game-protocol/README.md` — visión general y comandos.
- `vendor/game-protocol/profiles/` — perfiles de dominio (qué géneros de juego soporta el protocolo de fábrica).
- `vendor/game-protocol/examples/` — juegos de ejemplo completos (`*.GAME.md` + motor `engine-core.js` + HTML standalone).
- `vendor/game-protocol/tools/game-lint.js` — validador (136 reglas + cruces opcionales con el motor vía `GAME_ENGINE=...`).
- `vendor/game-protocol/tools/game-export.js` — compilador `GAME.md` → `game-data.generated.js` (`window.GAME`).
- `vendor/game-protocol/schemas/`, `vendor/game-protocol/adapters/`, `vendor/game-protocol/skills/` — schemas, adaptadores de render y skills del protocolo.

## Comandos verificados (Node >= 18, sin npm install)

Desde `vendor/game-protocol/`:

```bash
node tools/game-lint.js <ruta/GAME.md>                 # validar (exit 0 y "ok": true)
node tools/game-export.js <ruta/GAME.md> <salida.js>   # compilar a window.GAME
npm test                                                # suite propia del protocolo
```

Verificado en esta máquina (Node v24.16.0): lint del ejemplo con 0 errores / 0 warnings, export generado, y `npm test` en verde (incluye mutation audit 20/20).

## Cómo lo usan los contratos KDD del juego

- El `GAME.md` del juego vive fuera de `vendor/` (p. ej. `src/` o raíz del proyecto — se decide al definir el juego); `vendor/game-protocol/` es solo herramienta de referencia, NO se modifica.
- Los task contracts en `knowledge/contracts/` que toquen contenido del juego deben incluir en su `test_command` el lint del protocolo (p. ej. `node vendor/game-protocol/tools/game-lint.js <GAME.md>`) además de los tests congelados propios.
- Regla de frontera del protocolo (SPEC §0 y §7): datos (criaturas, ítems, mapas, balance, arte, textos) van en `GAME.md`; lógica/render (fórmulas, máquinas de estado, cámara, UI) va en código del motor.
