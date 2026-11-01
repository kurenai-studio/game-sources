import { SCENE, SOUND } from '../constants'
import { addButton } from '../gameobjects/button'
import { addMuteButton } from '../gameobjects/mute-button'
import { addStarBurst } from '../gameobjects/star-burst'
import { LEVELS } from '../levels'

scene(SCENE.LEVEL_COMPLETE, (rawIndex = 0) => {
  const levelIndex = Number(rawIndex)

  play(SOUND.WIN, { volume: 0.5 })
  addStarBurst()

  const titleText = add([
    text('✦ Level Complete ✦', { size: 36 }),
    pos(width() / 2, height() / 2 - 80),
    anchor('center'),
    color(245, 197, 66),
    opacity(0),
    scale(0.5),
  ])

  tween(
    titleText.pos.y + 40,
    titleText.pos.y,
    0.45,
    (v) => {
      titleText.pos.y = v
    },
    easings.easeOutBack,
  )
  tween(
    0,
    1,
    0.4,
    (v) => {
      titleText.opacity = v
    },
    easings.easeOutQuad,
  )
  tween(
    0.5,
    1,
    0.4,
    (v) => {
      titleText.scaleTo(v)
    },
    easings.easeOutBack,
  )

  const nextLevelIndex = levelIndex + 1
  const hasNextLevel = nextLevelIndex < LEVELS.length

  const btnLabel = hasNextLevel ? 'Next Level →' : 'Play Again'

  addButton(btnLabel, vec2(width() / 2, height() / 2 + 20), () => {
    go(SCENE.GAME, hasNextLevel ? nextLevelIndex : 0)
  })

  addMuteButton()
})
