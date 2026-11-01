import { SOUND, UI } from '../constants'

const BUTTON_BG: [number, number, number] = [60, 60, 80]
const BUTTON_BG_HOVER: [number, number, number] = [80, 80, 110]

const PADDING_X = 40
const CHAR_WIDTH_RATIO = 0.5

export function addButton(
  label: string,
  position: ReturnType<typeof vec2>,
  onClick: () => void,
) {
  const width = label.length * UI.TEXT_SIZE * CHAR_WIDTH_RATIO + PADDING_X

  const button = add([
    rect(width, 50, { radius: 8 }),
    pos(position),
    anchor('center'),
    color(...BUTTON_BG),
    area(),
    opacity(0.5),
    scale(1),
  ])

  button.add([
    text(label, { size: UI.TEXT_SIZE }),
    anchor('center'),
    color(...UI.TEXT_COLOR),
  ])

  button.onHover(() => {
    setCursor('pointer')
    play(SOUND.BUTTON_HOVER, { volume: 0.5 })
    button.color = rgb(...BUTTON_BG_HOVER)

    tween(
      button.scale.x,
      1.1,
      0.1,
      (v) => {
        button.scaleTo(v)
      },
      easings.easeOutQuad,
    )
  })

  button.onHoverEnd(() => {
    setCursor('default')
    button.color = rgb(...BUTTON_BG)

    tween(
      button.scale.x,
      1,
      0.1,
      (v) => {
        button.scaleTo(v)
      },
      easings.easeOutQuad,
    )
  })

  button.onClick(() => {
    play(SOUND.CLICK)
    onClick()
  })

  return button
}
