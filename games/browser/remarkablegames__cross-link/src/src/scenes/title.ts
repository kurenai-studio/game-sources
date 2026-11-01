import type { GameObj, PosComp, ScaleComp } from 'kaplay'

import { COLOR, SCENE } from '../constants'
import { addButton } from '../gameobjects/button'
import { addMuteButton } from '../gameobjects/mute-button'
import { startMusic } from '../utils/music'
import { loadLevel } from '../utils/progress'

const ORBITAL_COLORS: [number, number, number][] = [
  COLOR.GOLD_RGB,
  COLOR.CYAN_RGB,
  COLOR.ROSE_RGB,
]

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

scene(SCENE.TITLE, () => {
  drawBgStars(150)

  const titleCenter = vec2(width() / 2, height() / 2 - 90)

  const titleText = add([
    text('CROSS-LINK', { size: 48 }),
    pos(titleCenter),
    anchor('center'),
    color([255, 255, 255]),
    opacity(0),
    scale(0.5),
  ])

  tween(
    0,
    1,
    0.5,
    (v) => {
      titleText.opacity = v
    },
    easings.easeOutQuad,
  )
  tween(
    0.5,
    1,
    0.5,
    (v) => {
      titleText.scaleTo(v)
    },
    easings.easeOutBack,
  )

  const orbitals: {
    color: [number, number, number]
    radiusX: number
    radiusY: number
    speed: number
    angle: number
    phase: number
    dot: GameObj<PosComp & ScaleComp>
  }[] = []

  for (let i = 0; i < ORBITAL_COLORS.length; i++) {
    const [r, g, b] = ORBITAL_COLORS[i]
    const dot = add([
      pos(titleCenter.x, titleCenter.y),
      anchor('center'),
      circle(12),
      color(r, g, b),
      opacity(0),
      scale(1),
    ])

    dot.opacity = 0
    tween(
      0,
      1,
      0.6 + i * 0.1,
      (v) => {
        dot.opacity = v
      },
      easings.easeOutQuad,
    )

    orbitals.push({
      color: ORBITAL_COLORS[i],
      radiusX: 140 + i * 25,
      radiusY: 80 + i * 15,
      speed: 0.8 + i * 0.3,
      angle: (i * Math.PI * 2) / 3,
      phase: i * 1.5,
      dot,
    })
  }

  onUpdate(() => {
    const t = time()
    for (const orbital of orbitals) {
      const angle = orbital.angle + t * orbital.speed * 0.5
      const x = titleCenter.x + Math.cos(angle) * orbital.radiusX
      const y =
        titleCenter.y + Math.sin(angle + orbital.phase) * orbital.radiusY
      orbital.dot.pos = vec2(x, y)

      const pulse = 1 + Math.sin(t * 2 + orbital.phase) * 0.15
      orbital.dot.scaleTo(pulse)
    }
  })

  onDraw(() => {
    for (const orbital of orbitals) {
      const [r, g, b] = orbital.color
      drawLine({
        p1: titleCenter,
        p2: orbital.dot.pos,
        width: 3,
        color: rgb(r, g, b),
        opacity: 0.15,
      })
    }
  })

  const level = loadLevel()

  addButton(
    !level ? 'Start' : 'Continue',
    vec2(width() / 2, height() / 2 + 90),
    () => {
      startMusic()
      go(SCENE.GAME, level)
    },
  )

  if (level > 0) {
    addButton('Restart', vec2(width() / 2, height() / 2 + 160), () => {
      startMusic()
      go(SCENE.GAME, 0)
    })
  }

  addMuteButton()
})
