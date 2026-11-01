import { TILE_SIZE } from '../constants'
import { getDeviceScale } from '../helpers'
import { levels } from './levels'
import { getTiles } from './tiles'

/**
 * Gets level data.
 *
 * @param level - Level number.
 * @returns - Level data.
 */
export function getLevel(level: number) {
  const { map, scale } = levels[level]
  const tileScale = scale * getDeviceScale()

  const tileWidth = TILE_SIZE * tileScale
  const tileHeight = TILE_SIZE * tileScale

  const width = tileWidth * map[0].length
  const height = tileHeight * map.length

  const options = {
    tileWidth,
    tileHeight,
    tiles: getTiles(tileScale),

    pos: vec2(
      center().x + tileWidth / 2 - width / 2,
      center().y + tileHeight / 2 - height / 2,
    ),
  }

  return [map, options] as const
}

/**
 * Checks if level exists.
 *
 * @param level - Level number.
 * @returns - Whether level exists.
 */
export function hasLevel(level: number): boolean {
  return Boolean(levels[level])
}
