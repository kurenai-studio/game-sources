interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  r: number
  opacity: number
  phase: number
  life: number
  maxLife: number
}

export function addStarBurst() {
  const { x, y } = center()
  const particles: Particle[] = []

  for (let i = 0; i < 60; i++) {
    const angle = rand(0, Math.PI * 2)
    const speed = rand(600, 1200)
    const life = rand(1, 3)

    particles.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      r: rand(1, 2),
      opacity: 1,
      phase: rand(0, Math.PI * 2),
      life,
      maxLife: life,
    })
  }

  add([
    {
      update() {
        const d = dt()

        for (const p of particles) {
          p.x += p.vx * d
          p.y += p.vy * d
          p.vx *= 0.94
          p.vy *= 0.94
          p.vy += 80 * d
          p.phase += d * rand(1, 3)
          p.life -= d
          p.opacity = Math.max(0, p.life / p.maxLife)
        }
      },

      draw() {
        for (const p of particles) {
          if (p.opacity <= 0) {
            continue
          }

          const twinkle = Math.sin(p.phase) * 0.25
          drawCircle({
            pos: vec2(p.x, p.y),
            radius: p.r,
            color: rgb(210, 220, 255),
            opacity: Math.max(0, p.opacity + twinkle),
          })
        }
      },
    },
  ])
}
