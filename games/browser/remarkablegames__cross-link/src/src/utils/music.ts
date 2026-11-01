import type { AudioPlay } from 'kaplay'

import { SOUND, STORAGE } from '../constants'

const STORAGE_KEY = `${STORAGE.PREFIX}.muted`

let musicHandle: AudioPlay | null = null

export function startMusic() {
  if (musicHandle) {
    return
  }

  const muted = getData<boolean>(STORAGE_KEY) ?? false
  if (muted) {
    setVolume(0)
  }

  musicHandle = play(SOUND.MUSIC, {
    loop: true,
    paused: muted,
  })
}

export function toggleMute() {
  const muted = isMuted()
  const next = !muted
  setData(STORAGE_KEY, next)
  setVolume(next ? 0 : 1)

  if (musicHandle) {
    musicHandle.paused = next
  }
}

export function isMuted(): boolean {
  return getData<boolean>(STORAGE_KEY) ?? false
}
