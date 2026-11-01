import { STORAGE } from '../constants'

const STORAGE_KEY = `${STORAGE.PREFIX}.level`

export function saveLevel(index: number) {
  setData(STORAGE_KEY, index)
}

export function loadLevel(): number {
  return getData<number>(STORAGE_KEY) ?? 0
}
