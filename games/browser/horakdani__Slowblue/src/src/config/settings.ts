import { readJson, writeJson } from '../core/storage';

/**
 * The six layers every bed is built out of.
 *
 * These are *roles*, not sounds. Each act fills them with its own medium's
 * voices - the body of act I is a stream of bubbles and the body of act VI is
 * rain - and `audio/Beds.ts` is the table that says which, and what each one is
 * called in the mixer the player opens mid-station. A slot an act has nothing to
 * put in is simply absent from that act's bed and never drawn.
 *
 * They are shared slots rather than per-act tracks on purpose: somebody who has
 * turned the far voice down wants it down in every act, not in the one they
 * happened to be standing in when they reached for the slider.
 */
export const BED_TRACK_KEYS = [
  /** The body: whatever this medium is continuously made of. */
  'ocean',
  /** The medium in motion: gusts, shocks, showers, currents. Episodic. */
  'motion',
  /** The chord. The one layer every bed has, voiced differently in each. */
  'drone',
  /** Whatever is above the body: surface light, high wind, halo, silence. */
  'shimmer',
  /** The bell. */
  'ambience',
  /** The far voice: rare, large, and always a long way off. */
  'whale',
] as const;

export type BedTrackKey = (typeof BED_TRACK_KEYS)[number];

export const AUDIO_TRACK_KEYS = [
  ...BED_TRACK_KEYS,
  'movement',
  'objectives',
  'danger',
  'interface',
] as const;

export type AudioTrackKey = (typeof AUDIO_TRACK_KEYS)[number];

export function isBedTrack(key: AudioTrackKey): key is BedTrackKey {
  return (BED_TRACK_KEYS as readonly string[]).includes(key);
}

export interface AudioTrackSettings {
  enabled: boolean;
  /** Linear gain, stored as 0..1 and presented as a percentage. */
  volume: number;
}

export type AudioSettings = Record<AudioTrackKey, AudioTrackSettings>;

export interface Settings {
  /**
   * Which schema this blob was written at, so a default can change without
   * changing it only for people who have never played.
   *
   * A stored setting beats a default by design - that is what storing it is for -
   * which means a default that changes is a default nobody already on a device
   * ever sees. This is the one number that lets a *deliberate* change reach them:
   * `sanitizeSettings` replays the steps between the stored revision and
   * `SETTINGS_REV`, once, and writes the new number back.
   *
   * It is not a licence to overwrite choices. A step here has to be worth taking
   * a switch out of a player's hand, it runs exactly once, and everything it does
   * is one press away in the drawer.
   */
  rev: number;
  /** Every synthesised layer has an independent mute and level. */
  audio: AudioSettings;
  /**
   * The master switch: silence, without touching a single track.
   *
   * Ten sliders are the right answer for somebody shaping a mix and the wrong
   * one for somebody whose room just went quiet. This is one press, it is
   * reversible, and because it sits beside the mixer rather than inside it, the
   * mix a player built is exactly what comes back when they press it again.
   */
  muted: boolean;
  /**
   * Continuous circuit mode: the seventh act hands back to the first instead of
   * to the title.
   *
   * §11 unlocks it after a full campaign, and the shell only offers it once the
   * player has closed one - because until they have, the sentence it is making
   * has no referent. What it does is take the one screen out of a journey that
   * is otherwise unbroken: `render/Circle.ts` already dissolves the trench floor
   * into act I's first frame, and with this on that dissolve is not a metaphor.
   */
  circuit: boolean;
}

const KEY = 'settings';

/**
 * The two slots the game opens with switched off, in every act.
 *
 * They are the bed's two *held* layers - the chord and whatever is above it -
 * and they are the only two that never stop. Everything else in a bed is an
 * event: a bubble, a wingbeat, a drop, a bell, an animal a long way off. A held
 * layer is the one thing in the mix that a player cannot stop noticing, and the
 * two of them together are what makes a station sound like a pad with a game
 * over it rather than like water with something living in it.
 *
 * Off by default rather than quiet by default, because a drone at 20% is still a
 * drone. Both are one press away in the drawer, named after whatever the act
 * calls them - `Deep drone` in the trench, `Thin drone` in the stratosphere,
 * `Nacreous halo` above it - and a player who turns one on has it on everywhere,
 * because these are shared slots (see `BED_TRACK_KEYS`) rather than per-act
 * tracks. That is what makes "every act" true here without a table: there is one
 * drone switch in the game and one shimmer switch, and this is where they start.
 */
export const QUIET_BY_DEFAULT = ['drone', 'shimmer'] as const satisfies readonly BedTrackKey[];

export function defaultAudioSettings(): AudioSettings {
  return {
    ocean: { enabled: true, volume: 1 },
    motion: { enabled: true, volume: 1 },
    drone: { enabled: false, volume: 1 },
    shimmer: { enabled: false, volume: 1 },
    ambience: { enabled: true, volume: 1 },
    whale: { enabled: true, volume: 1 },
    movement: { enabled: true, volume: 1 },
    objectives: { enabled: true, volume: 1 },
    danger: { enabled: true, volume: 1 },
    interface: { enabled: true, volume: 1 },
  };
}

/**
 * The current schema revision. See `Settings.rev`.
 *
 * 1. The bed's two held layers - the chord and the layer above it - start off.
 *    See `QUIET_BY_DEFAULT`.
 */
export const SETTINGS_REV = 1;

export function defaultSettings(): Settings {
  return {
    rev: SETTINGS_REV,
    audio: defaultAudioSettings(),
    muted: false,
    circuit: false,
  };
}

const BOOL_KEYS = ['circuit', 'muted'] as const satisfies readonly (keyof Settings)[];

/** Merges a possibly stale or hostile stored blob onto the defaults. */
export function sanitizeSettings(input: unknown, base = defaultSettings()): Settings {
  const out: Settings = {
    ...base,
    audio: Object.fromEntries(
      AUDIO_TRACK_KEYS.map((key) => [key, { ...base.audio[key] }]),
    ) as AudioSettings,
  };
  if (typeof input !== 'object' || input === null) return out;
  const rec = input as Record<string, unknown>;
  for (const key of BOOL_KEYS) {
    if (typeof rec[key] === 'boolean') out[key] = rec[key];
  }
  if (typeof rec.audio === 'object' && rec.audio !== null) {
    const storedAudio = rec.audio as Record<string, unknown>;
    for (const key of AUDIO_TRACK_KEYS) {
      const storedTrack = storedAudio[key];
      if (typeof storedTrack !== 'object' || storedTrack === null) continue;
      const values = storedTrack as Record<string, unknown>;
      if (typeof values.enabled === 'boolean') out.audio[key].enabled = values.enabled;
      if (typeof values.volume === 'number' && Number.isFinite(values.volume)) {
        out.audio[key].volume = Math.max(0, Math.min(1, values.volume));
      }
    }
  } else {
    // Settings written before the mixer existed had one switch for the ambient
    // bed and one for every event. Preserve those choices on the first new load.
    //
    // Only the *off* half of the ambient switch is replayed. `music: true` was a
    // player leaving a default alone, not a player asking for a drone, so it is
    // answered with today's default rather than with all six slots on - which
    // would be the one path into the game that reaches a station with the chord
    // up, from a blob written before either of these was a switch you could see.
    if (rec.music === false) {
      for (const key of BED_TRACK_KEYS) out.audio[key].enabled = false;
    }
    if (typeof rec.sound === 'boolean') {
      for (const key of ['movement', 'objectives', 'danger', 'interface'] as const) {
        out.audio[key].enabled = rec.sound;
      }
    }
  }
  // `lang`, `quality`, `haptics`, `showHud`, `calm`, `reducedMotion` and `highContrast`
  // are read from nothing now and are simply dropped from any blob that still
  // carries them - they are not in `BOOL_KEYS`, so the loop above never looks for
  // them. The picture budget moved to `main.adaptQuality`, which measures instead
  // of asking; of the rest, one was a switch nobody could feel, one hid the
  // stranding warning, one was a whole second mode, and the last two were COMFORT,
  // a screen that is gone. A save from before any of them left loads as an
  // ordinary run.
  //
  // ...and last, the steps between the revision this blob was written at and
  // today's, applied over the top of everything it did say. Last because a step
  // is a decision about the merged result: `rev 1` has to be able to see the
  // drone the stored blob just switched on in order to switch it back off.
  const rev = typeof rec.rev === 'number' && Number.isFinite(rec.rev) ? rec.rev : 0;
  // Every blob written before `Settings.rev` existed is a blob written when the
  // chord and the layer above it were on, because that was the default and
  // nothing else in the game turned them off. Taking them back is the change
  // being made; leaving them for the players who already have a save would make
  // the game two games, and the one nobody would ever hear is the new one.
  if (rev < 1) for (const key of QUIET_BY_DEFAULT) out.audio[key].enabled = false;
  out.rev = SETTINGS_REV;
  return out;
}

export function loadSettings(): Settings {
  return sanitizeSettings(readJson<unknown>(KEY, null));
}

export function saveSettings(s: Settings): void {
  writeJson(KEY, s);
}
