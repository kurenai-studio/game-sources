import './cover'
import './game'
import './level-complete'
import './preload'
import './title'

import { SCENE } from '../constants'

export function start() {
  go(SCENE.PRELOAD)
}
