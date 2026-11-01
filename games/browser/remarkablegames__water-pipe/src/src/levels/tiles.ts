import { DirectionPipe, EmptyPipe, pipes, Tag } from '../constants'

/**
 * Gets level map tile object.
 *
 * @param tileScale - Tile scale.
 * @returns - Tile object.
 */
export function getTiles(tileScale: number) {
  const tileComps = [anchor('center'), scale(tileScale)]

  const staticComps = [...tileComps, color(135, 206, 235)]

  return pipes.reduce(
    (accumulator: Record<string, () => unknown[]>, value) => {
      accumulator[value] = () => [
        ...tileComps,
        sprite(value),
        area(),
        rotate(0),
        { type: value, solution: value },
        Tag.pipe,
      ]

      return accumulator
    },
    {
      [DirectionPipe['△']]: () => [
        ...staticComps,
        sprite(EmptyPipe['║']),
        { type: DirectionPipe['△'] },
      ],

      [DirectionPipe['▷']]: () => [
        ...staticComps,
        sprite(EmptyPipe['═']),
        { type: DirectionPipe['▷'] },
      ],

      [DirectionPipe['▽']]: () => [
        ...staticComps,
        sprite(EmptyPipe['║']),
        { type: DirectionPipe['▽'] },
      ],

      [DirectionPipe['◁']]: () => [
        ...staticComps,
        sprite(EmptyPipe['═']),
        { type: DirectionPipe['◁'] },
      ],
    },
  )
}
