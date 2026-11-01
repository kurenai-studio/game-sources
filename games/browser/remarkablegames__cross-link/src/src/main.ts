import kaplay from 'kaplay'

import { addStars } from './utils/stars'

kaplay({
  width: 600,
  height: 800,
  stretch: true,
  letterbox: true,
  background: [0, 0, 0, 0],
  scale: 4,
  font: 'Inter',
})

addStars(150)

const { start } = await import('./scenes')

start()

// press F1
// debug.inspect = true
