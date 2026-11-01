/**
 * @see https://colorhunt.co/palettes/sea
 */
const backgrounds: [number, number, number][] = [
  [106, 212, 221],
  [122, 162, 227],
  [134, 182, 246],
  [151, 231, 225],
  [172, 226, 225],
  [179, 200, 207],
  [180, 212, 255],
  [190, 215, 220],
  [201, 215, 221],
  [205, 232, 229],
  [220, 242, 241],
  [224, 251, 226],
  [227, 254, 247],
  [229, 221, 197],
  [238, 247, 255],
  [241, 238, 220],
  [248, 246, 227],
  [255, 243, 207],
]

export function setRandomBackgroundColor() {
  const color = backgrounds[randi(backgrounds.length)]
  setBackground(...color, 1)
}
