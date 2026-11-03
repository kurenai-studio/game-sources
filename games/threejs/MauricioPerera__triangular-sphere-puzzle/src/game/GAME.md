---
version: "0.1"
name: Game Project
profile: monster-rpg
description: Escenario mínimo de arranque para el proyecto.
platform: { mode: demo, cols: 10, rows: 8, screenW: 160, screenH: 128 }
palettesCount: 2
tiles:
  16: { name: grass, solid: false }
  17: { name: wall, solid: true }
  18: { name: tall_grass, solid: false, encounter: true }
  46: { name: mat, solid: false }
types:
  NORMAL: { }
moves:
  TACKLE: { type: NORMAL, power: 5 }
species:
  STARTER: { type: NORMAL, maxhp: 20, moves: [TACKLE] }
  WILD: { type: NORMAL, maxhp: 14, moves: [TACKLE], wild: true }
encounters:
  field: [WILD]
overworld:
  field: { }
economy: { startMoney: 0 }
balance: { catchBase: 0.4, catchScale: 0.5, xpCurveMul: 1.5, encounterRate: 0.2 }
palettes:
  0: [[8,17,7],[12,22,10],[15,25,12],[18,28,14]]
  1: [[12,22,10],[6,6,8],[16,18,20],[24,26,28],[31,31,31]]
spritePalettes:
  0: [[0,0,0],[1,1,1],[6,20,8],[31,22,16]]
player: { starter: STARTER, level: 1, start: { x: 24, y: 24 } }
text:
  intro: "Escenario mínimo de arranque."
---

## Overview

Este archivo contiene únicamente los datos mínimos para comprobar el pipeline
`GAME.md` → linter → artefacto generado. El diseño definitivo se documentará aquí
cuando se definan género, mecánicas, mundo, entidades, economía, arte y textos.
