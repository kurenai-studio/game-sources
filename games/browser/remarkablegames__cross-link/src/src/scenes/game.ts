import { SCENE, SOUND, TAG, UI } from '../constants'
import { addButton } from '../gameobjects/button'
import {
  addDot,
  animateDotSelect,
  cancelDotSelectPulse,
  type Dot,
  type DotColor,
} from '../gameobjects/dot'
import {
  addLine,
  clearLines,
  findIntersectingLines,
  type Line,
} from '../gameobjects/line'
import { addMuteButton } from '../gameobjects/mute-button'
import { LEVELS } from '../levels'
import { saveLevel } from '../utils/progress'

const HEADER_H = 100
const FOOTER_H = 100
const GRID_OFFSET_Y = HEADER_H

const SYMBOL_COLOR: Partial<Record<string, DotColor>> = {
  g: 'gold',
  c: 'cyan',
  r: 'rose',
  v: 'green',
  w: 'white',
}

const COLOR_MAP: Record<DotColor, [number, number, number]> = {
  gold: [245, 197, 66],
  cyan: [79, 195, 247],
  rose: [244, 143, 177],
  green: [168, 224, 99],
  white: [232, 232, 240],
}

function drawBgStars(count: number) {
  const stars: {
    x: number
    y: number
    r: number
    o: number
    phase: number
    speed: number
  }[] = []

  for (let i = 0; i < count; i++) {
    stars.push({
      x: rand(0, width()),
      y: rand(0, height()),
      r: rand(0.5, 1.8),
      o: rand(0.15, 0.55),
      phase: rand(0, Math.PI * 2),
      speed: rand(0.2, 0.7),
    })
  }

  add([
    {
      update() {
        for (const star of stars) {
          star.phase += dt() * star.speed
        }
      },
      draw() {
        for (const star of stars) {
          const glow = Math.sin(star.phase) * 0.25
          drawCircle({
            pos: vec2(star.x, star.y),
            radius: star.r,
            color: rgb(210, 220, 255),
            opacity: Math.max(0, star.o + glow),
          })
        }
      },
    },
  ])
}

scene(SCENE.GAME, (rawIndex = 0) => {
  const levelIndex = Number(rawIndex)
  const level = LEVELS.at(levelIndex)

  if (!level) {
    return
  }

  saveLevel(levelIndex)

  drawBgStars(150)

  const dots: Dot[] = []
  const lines: Line[] = []
  let selectedDot: Dot | null = null
  let moveCount = 0
  let hintStep = 0
  let clearing = false

  add([
    text(`Level ${String(levelIndex + 1)}`, { size: UI.TEXT_SIZE }),
    pos(20, 30),
    anchor('left'),
    color(...UI.TEXT_COLOR),
  ])

  addMuteButton()

  const moveText = add([
    text('Moves: 0', { size: UI.TEXT_SIZE }),
    pos(width() - 65, 30),
    anchor('right'),
    color(...UI.TEXT_COLOR),
    scale(1),
  ])

  const hintText = add([
    text('', { size: UI.TEXT_SIZE - 6, width: width() - 40 }),
    pos(width() / 2, 72),
    anchor('center'),
    color(160, 180, 255),
    opacity(0),
  ])

  function showHint(msg: string) {
    hintText.text = msg
    tween(
      0,
      1,
      0.3,
      (v) => {
        hintText.opacity = v
      },
      easings.easeOutQuad,
    )
  }

  if (level.hints && level.hints.length > 0) {
    showHint(level.hints[0])
    hintStep = 0
  }

  function advanceHint(step: number) {
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    if (!level!.hints) return
    hintStep = step
    // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
    if (step < level!.hints.length) {
      // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
      showHint(level!.hints[step])
    } else {
      tween(
        hintText.opacity,
        0,
        0.3,
        (v) => {
          hintText.opacity = v
        },
        easings.easeOutQuad,
      )
    }
  }

  const restartButton = addButton(
    '↺ Restart',
    vec2(width() / 2, height() - FOOTER_H / 2),
    () => {
      go(SCENE.GAME, levelIndex)
    },
  )

  const { map, tileWidth, tileHeight } = level
  for (let row = 0; row < map.length; row++) {
    const symbols = map[row].split(' ')
    for (let col = 0; col < symbols.length; col++) {
      const sym = symbols[col]
      if (sym === '.') continue
      const dotColor = SYMBOL_COLOR[sym]
      if (!dotColor) continue
      const x = col * tileWidth + tileWidth / 2
      const y = row * tileHeight + tileHeight / 2 + GRID_OFFSET_Y
      const dot = addDot(x, y, dotColor)
      dots.push(dot)
    }
  }

  function updateMoveText() {
    moveText.text = `Moves: ${String(moveCount)}`
    tween(
      1,
      1.25,
      0.08,
      (v) => {
        moveText.scaleTo(v)
      },
      easings.easeOutQuad,
    ).then(() => {
      tween(
        1.25,
        1,
        0.1,
        (v) => {
          moveText.scaleTo(v)
        },
        easings.easeOutQuad,
      )
    })
  }

  function checkWin() {
    if (!get(TAG.DOT).length) {
      restartButton.destroy()
      wait(0.4, () => {
        go(SCENE.LEVEL_COMPLETE, levelIndex)
      })
    }
  }

  onMousePress(() => {
    if (clearing) return
    const mp = mousePos()

    for (const dot of dots) {
      if (!dot.exists()) continue
      const d = mp.dist(dot.pos)
      if (d > 44) continue

      if (dot.connected) continue

      if (!selectedDot) {
        selectedDot = dot
        dot.connected = true
        animateDotSelect(dot)
        play(SOUND.SELECT)
        advanceHint(hintStep + 1)
        return
      }

      if (selectedDot === dot) {
        cancelDotSelectPulse(selectedDot)
        selectedDot.connected = false
        selectedDot = null
        return
      }

      if (selectedDot.dotColor !== dot.dotColor) {
        play(SOUND.ERROR, { volume: 0.5 })
        cancelDotSelectPulse(selectedDot)
        selectedDot.connected = false
        selectedDot = null
        return
      }

      dot.connected = true
      cancelDotSelectPulse(selectedDot)
      const newLine = addLine(selectedDot, dot, dot.dotColor)
      lines.push(newLine)
      moveCount++
      play(SOUND.CONNECT, { volume: 0.5 })
      updateMoveText()
      advanceHint(hintStep + 1)

      const hits = findIntersectingLines(newLine, lines)
      if (hits.length > 0) {
        clearing = true
        const toClear = [newLine, ...hits]
        for (const l of toClear) {
          const idx = lines.indexOf(l)
          if (idx !== -1) lines.splice(idx, 1)
          dots.splice(dots.indexOf(l.dotA), 1)
          dots.splice(dots.indexOf(l.dotB), 1)
        }
        advanceHint(hintStep + 1)
        play(hits.length > 1 ? SOUND.CLEAR_MULTIPLE : SOUND.CLEAR)
        clearLines(toClear, () => {
          clearing = false
          checkWin()
        })
      }

      selectedDot = null
      return
    }

    if (selectedDot) {
      play(SOUND.ERROR, { volume: 0.5 })
      cancelDotSelectPulse(selectedDot)
      selectedDot.connected = false
      selectedDot = null
    }
  })

  onDraw(() => {
    if (selectedDot?.exists()) {
      const [r, g, b] = COLOR_MAP[selectedDot.dotColor]
      const pulse = 0.7 + Math.sin(time() * 6) * 0.3

      drawLine({
        p1: selectedDot.pos,
        p2: mousePos(),
        width: 8,
        color: rgb(r, g, b),
        opacity: 0.04 + pulse * 0.1,
      })

      drawLine({
        p1: selectedDot.pos,
        p2: mousePos(),
        width: 2.5,
        color: rgb(r, g, b),
        opacity: 0.35 + pulse * 0.35,
      })
    }
  })
})
