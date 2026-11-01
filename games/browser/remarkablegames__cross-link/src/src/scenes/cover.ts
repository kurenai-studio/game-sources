import { COLOR, SCENE } from '../constants'

// Canvas is 600x800, cover art area is 512x512 centered
const COVER_SIZE = 512
const COVER_X = (600 - COVER_SIZE) / 2
const COVER_Y = (800 - COVER_SIZE) / 2
const CENTER = vec2(600 / 2, 800 / 2)

const TEXT_SIZE = 102
const ORBIT_RADIUS = 250
const DOT_SIZE = 25
const LINE_WIDTH = 8

const ORBITAL_COLORS: [number, number, number][] = [
  COLOR.GOLD_RGB,
  COLOR.CYAN_RGB,
  COLOR.ROSE_RGB,
]

function drawStaticStars(count: number) {
  const stars: { x: number; y: number; r: number; o: number }[] = []

  // Generate stars only within cover area
  for (let i = 0; i < count; i++) {
    stars.push({
      x: COVER_X + rand(0, COVER_SIZE),
      y: COVER_Y + rand(0, COVER_SIZE),
      r: rand(1, 2),
      o: rand(0.15, 0.55),
    })
  }

  add([
    {
      draw() {
        for (const star of stars) {
          drawCircle({
            pos: vec2(star.x, star.y),
            radius: star.r,
            color: rgb(210, 220, 255),
            opacity: star.o,
          })
        }
      },
    },
  ])
}

scene(SCENE.COVER, () => {
  drawStaticStars(200)

  add([
    text('CROSS-LINK', { size: TEXT_SIZE }),
    pos(CENTER),
    anchor('center'),
    color([255, 255, 255]),
  ])

  // Fixed orbital positions at 120° intervals
  const orbitals: {
    color: [number, number, number]
    radiusX: number
    radiusY: number
    angle: number
    x: number
    y: number
  }[] = []

  // Triangle positions: gold bottom right, cyan top, rose bottom left
  const TRIANGLE_ANGLES = [Math.PI / 3, -Math.PI / 2, (2 * Math.PI) / 3]

  for (let i = 0; i < ORBITAL_COLORS.length; i++) {
    const [r, g, b] = ORBITAL_COLORS[i]
    const angle = TRIANGLE_ANGLES[i]

    const x = CENTER.x + Math.cos(angle) * ORBIT_RADIUS
    const y = CENTER.y + Math.sin(angle) * ORBIT_RADIUS

    add([pos(x, y), anchor('center'), circle(DOT_SIZE), color(r, g, b)])

    orbitals.push({
      color: ORBITAL_COLORS[i],
      radiusX: ORBIT_RADIUS,
      radiusY: ORBIT_RADIUS,
      angle,
      x,
      y,
    })
  }

  onDraw(() => {
    for (const orbital of orbitals) {
      const [r, g, b] = orbital.color
      drawLine({
        p1: CENTER,
        p2: vec2(orbital.x, orbital.y),
        width: LINE_WIDTH,
        color: rgb(r, g, b),
        opacity: 0.15,
      })
    }
  })
})
