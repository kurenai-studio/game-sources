import { Game } from './game/game'
import { readTestOptions } from './game/testHooks'

new Game(readTestOptions()).start()
