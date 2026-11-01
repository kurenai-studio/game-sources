import { UI } from '../constants'
import { isMuted, toggleMute } from '../utils/music'

export function addMuteButton() {
  const label = () => (isMuted() ? '🔇' : '🔊')

  const button = add([
    text(label(), { size: UI.TEXT_SIZE }),
    pos(width() - 20, 30),
    anchor('right'),
    area(),
    color(...UI.TEXT_COLOR),
    opacity(0.6),
  ])

  button.onHover(() => {
    setCursor('pointer')
    button.opacity = 1
  })

  button.onHoverEnd(() => {
    setCursor('default')
    button.opacity = 0.6
  })

  button.onClick(() => {
    toggleMute()
    button.text = label()
  })

  return button
}
