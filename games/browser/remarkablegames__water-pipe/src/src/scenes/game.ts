import {
  Background,
  EmptyToFilledPipe,
  Scene,
  Sound,
  StorageKey,
  Tag,
} from '../constants'
import {
  checkSolution,
  getDeviceScale,
  rotatePipe,
  setRandomBackgroundColor,
} from '../helpers'
import { getLevel, hasLevel } from '../levels'

scene(Scene.game, (levelNumber: number) => {
  if (!hasLevel(levelNumber)) {
    levelNumber = 0
  }

  setData(StorageKey.level, levelNumber)

  const music = play(Sound.waves, { loop: true, volume: 0.7 })
  music.seek(1)

  add([
    text(String(levelNumber), {
      align: 'center',
      size: Math.max(64 * getDeviceScale(), 42),
    }),
    pos(center().x, 24),
    color(15, 16, 53),
  ])

  setRandomBackgroundColor()
  add([
    sprite(Background.brick),
    pos(width() / 2, height() / 2),
    anchor('center'),
    opacity(0.2),
  ])

  const level = addLevel(...getLevel(levelNumber))

  level.get(Tag.pipe).forEach((pipe) => {
    Array(randi(4))
      .fill(undefined)
      .forEach(() => rotatePipe(pipe))
  })

  onClick(Tag.pipe, (pipe) => {
    if (!checkSolution(level)) {
      play(Sound.click)
      rotatePipe(pipe)
    }

    if (checkSolution(level)) {
      music.stop()
      play(Sound.splash, { volume: 0.5 })

      level.get(Tag.pipe).forEach((pipe) => {
        pipe.use(
          sprite(
            EmptyToFilledPipe[pipe.solution as keyof typeof EmptyToFilledPipe],
          ),
        )
      })

      wait(1, () => {
        go(Scene.game, levelNumber + 1)
      })
    }
  })
})
