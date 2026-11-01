import { Background, pipes, Scene, Sound, StorageKey } from '../constants'

scene(Scene.preload, () => {
  pipes.map((pipe) => loadSprite(pipe, `sprites/pipes/${pipe}.png`))

  loadSprite(Background.brick, 'sprites/backgrounds/brick.png')

  Object.values(Sound).map((sound) => {
    loadSound(sound, `sounds/${sound}.mp3`)
  })

  const queryLevel = new URLSearchParams(location.search).get('level')
  const savedLevel = getData<number>(StorageKey.level, 0) ?? 0
  const levelNumber = queryLevel !== null ? Number(queryLevel) : savedLevel

  go(Scene.game, levelNumber)
})
