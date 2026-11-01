import type { GameObj } from 'kaplay'

import { EmptyPipe } from '../constants'

/**
 * Rotates pipe 90 degrees.
 *
 * @param pipe - Pipe sprite.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function rotatePipe(pipe: GameObj<any>) {
  switch (pipe.type) {
    case EmptyPipe['═']:
      pipe.type = EmptyPipe['║']
      break

    case EmptyPipe['║']:
      pipe.type = EmptyPipe['═']
      break

    case EmptyPipe['╔']:
      pipe.type = EmptyPipe['╗']
      break

    case EmptyPipe['╗']:
      pipe.type = EmptyPipe['╝']
      break

    case EmptyPipe['╚']:
      pipe.type = EmptyPipe['╔']
      break

    case EmptyPipe['╝']:
      pipe.type = EmptyPipe['╚']
      break

    case EmptyPipe['╠']:
      pipe.type = EmptyPipe['╦']
      break

    case EmptyPipe['╣']:
      pipe.type = EmptyPipe['╩']
      break

    case EmptyPipe['╦']:
      pipe.type = EmptyPipe['╣']
      break

    case EmptyPipe['╩']:
      pipe.type = EmptyPipe['╠']
      break
  }

  pipe.angle += 90

  if (pipe.angle >= 360) {
    pipe.angle -= 360
  }
}
