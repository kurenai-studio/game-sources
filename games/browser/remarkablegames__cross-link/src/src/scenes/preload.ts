import { SCENE, SOUND } from '../constants'
import { LEVELS } from '../levels'

scene(SCENE.PRELOAD, () => {
  loadFont('Inter', 'fonts/InterVariable.woff2')

  loadSound(SOUND.MUSIC, 'sounds/music.mp3')
  loadSound(SOUND.SELECT, 'sounds/select.mp3')
  loadSound(SOUND.CONNECT, 'sounds/connect.mp3')
  loadSound(SOUND.CLEAR, 'sounds/clear.mp3')
  loadSound(SOUND.CLEAR_MULTIPLE, 'sounds/clear-multiple.mp3')
  loadSound(SOUND.WIN, 'sounds/win.mp3')
  loadSound(SOUND.DOT_HOVER, 'sounds/dot-hover.mp3')
  loadSound(SOUND.BUTTON_HOVER, 'sounds/button-hover.mp3')
  loadSound(SOUND.ERROR, 'sounds/error.mp3')
  loadSound(SOUND.CLICK, 'sounds/click.mp3')

  const params = new URLSearchParams(window.location.search)

  if (params.has('cover')) {
    go(SCENE.COVER)
    return
  }

  const levelParam = params.get('level')
  if (levelParam) {
    const levelIndex = Math.min(
      Math.max(parseInt(levelParam, 10) - 1, 0),
      LEVELS.length - 1,
    )
    go(SCENE.GAME, levelIndex)
    return
  }

  go(SCENE.TITLE)
})
