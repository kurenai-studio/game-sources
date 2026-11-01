import '@babylonjs/core/Audio/audioSceneComponent';

import { Sound } from '@babylonjs/core/Audio/sound';
import type { Observer } from '@babylonjs/core/Misc/observable';
import type { Scene } from '@babylonjs/core/scene';

import { MUSIC_TRACKS } from '../config/game-constants';
import type { MusicTrackId } from '../types/music-track';

interface SequencedSound {
  sound: Sound;
  trackId: MusicTrackId;
}

/**
 * Manages background music playback and deterministic track sequencing.
 */
export class MusicManager {
  private readonly tracks = MUSIC_TRACKS.slice();
  private readonly sounds: SequencedSound[];
  private currentSound: Sound | null = null;
  private currentObserver: Observer<Sound> | null = null;
  private hasStarted = false;
  private trackIndex = 0;

  constructor(scene: Scene) {
    this.sounds = this.createTrackSounds(scene);
  }

  play() {
    if (this.hasStarted) {
      return;
    }

    this.hasStarted = true;
    this.playCurrentTrack();
  }

  pause() {
    if (this.currentSound?.isPlaying) {
      this.currentSound.pause();
    }
  }

  resume() {
    if (this.currentSound?.isPaused) {
      this.currentSound.play();
      return;
    }

    if (this.hasStarted && this.currentSound === null) {
      this.playCurrentTrack();
    }
  }

  stop() {
    this.hasStarted = false;
    this.trackIndex = 0;
    this.stopCurrentSound();
  }

  dispose() {
    this.stop();

    for (const { sound } of this.sounds) {
      sound.dispose();
    }
  }

  private createTrackSounds(scene: Scene): SequencedSound[] {
    return this.tracks.map((trackId, index) => ({
      trackId,
      sound: new Sound(
        `${trackId}-${String(index)}`,
        `music/${trackId}.mp3`,
        scene,
      ),
    }));
  }

  private playCurrentTrack() {
    const currentTrack = this.sounds[this.trackIndex];
    const sound = currentTrack.sound;

    this.stopInactiveSounds(sound);
    this.detachCurrentObserver();
    this.currentSound = sound;
    this.currentObserver = sound.onEndedObservable.addOnce(() => {
      this.currentObserver = null;
      this.currentSound = null;

      if (!this.hasStarted) {
        return;
      }

      this.trackIndex = (this.trackIndex + 1) % this.tracks.length;
      this.playCurrentTrack();
    });

    sound.stop();
    sound.play();
  }

  private stopCurrentSound() {
    this.detachCurrentObserver();

    if (this.currentSound) {
      this.currentSound.stop();
      this.currentSound = null;
    }
  }

  private stopInactiveSounds(activeSound: Sound) {
    for (const { sound } of this.sounds) {
      if (sound !== activeSound) {
        sound.stop();
      }
    }
  }

  private detachCurrentObserver() {
    if (this.currentSound && this.currentObserver) {
      this.currentSound.onEndedObservable.remove(this.currentObserver);
      this.currentObserver = null;
    }
  }
}
