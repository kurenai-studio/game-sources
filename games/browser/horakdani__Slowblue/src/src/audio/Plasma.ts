/**
 * Slowblue: act V, the fallback - the one act allowed to be loud, and how it cools.
 *
 * §13 gives act V a permission nothing else in the campaign has, and the act's
 * own file (`config/reentry.ts`) is a description of a transformation: it starts
 * in vacuum and ends in cloud, and the air arrives in between at eight kilometres
 * a second and sets fire to what the player is carrying. So this is the only
 * place in the game with a continuous broadband layer in it, and the engine's
 * standing rule against exactly that (see `AudioEngine`'s header - a hiss is a
 * hiss at any level) is not being broken so much as spent, once, on the act it
 * was saved for.
 *
 * Two things keep it from being the rumble the water's noise layer was.
 *
 *   1. **It breathes.** The sheath's filter corner runs off the game's own breath
 *      clock: it opens on the in-breath and closes on the out-breath, over five
 *      and a half seconds each way. A roar that moves with your own chest is the
 *      one kind of broadband noise people find restful - it is why a hair dryer
 *      in the next room puts a baby to sleep - and it is doing entrainment work at
 *      the same time.
 *   2. **It goes out.** `sheathLevel` peaks at the plasma station and falls to
 *      nothing by the nucleus. The last two stations of act V have almost no
 *      sheath left in them at all, which is the fire being replaced by the cloud
 *      it seeded, and it means the loud layer is loud for about a quarter of the
 *      act rather than for all of it.
 *
 * ## The sparks
 *
 * Ablation: the heat shield is not resisting the heat, it is *leaving*, a layer
 * at a time, and each departing grain flares. As grains they are extremely short
 * and extremely high, and if they were noise they would be a crackle, which is a
 * transient and this engine does not do transients. So each one is a filtered
 * sine grain with a 6 ms swell - what is left of a crackle when the click is
 * taken out of it, which turns out to sound like a fire heard through a wall.
 *
 * ## The shocks
 *
 * A body going hypersonic drags a bow shock, and the shock is not a bang from
 * inside it: it is a long low roll that arrives, passes and leaves, and the
 * standoff distance oscillates, so they come every ten to twenty seconds. They
 * are the act's `motion` layer and they are what the arc actually rides on -
 * they start as pressure and end as wind.
 */

function clamp01(v: number): number {
  return v < 0 ? 0 : v > 1 ? 1 : v;
}

/**
 * Where the fire is, across the act. `arc01` is 0 at the deorbit burn and 1 at
 * the nucleus.
 *
 * Zero for the first two stations (still orbit, still nothing out there), full
 * at the plasma station, and gone by the last two. The shape is a lopsided hump:
 * the air arrives faster than it leaves, because that is what happening to you
 * and then being over feels like.
 */
export function sheathLevel(arc01: number): number {
  const t = clamp01(arc01);
  // Nothing before the aurora: the night side is the last quiet station and must
  // stay quiet, or the loud act has no silence to be loud against.
  if (t < 0.28) return 0;
  if (t < 0.58) {
    // Up over two stations, and the curve is squared so the arrival is felt as an
    // arrival rather than as a fader move.
    const u = (t - 0.28) / 0.3;
    return u * u;
  }
  // ...and down over three, more slowly. Cooling takes longer than catching.
  return Math.max(0, 1 - (t - 0.58) / 0.42) ** 1.4;
}

/**
 * The sheath's lowpass corner, in Hz. `breath01` is 1 fully inhaled.
 *
 * The band is deliberately narrow - 180 to 900 Hz - because the whole voice is
 * the *bottom* of a roar. Everything above a kilohertz in a real re-entry is the
 * part that would be a hiss, and the part this game will not have.
 */
export function sheathCorner(arc01: number, breath01: number): number {
  const heat = sheathLevel(arc01);
  const b = clamp01(breath01);
  return 180 + 420 * heat + 300 * b;
}

export interface Spark {
  /** Where the grain sits, in Hz. High: this is what is left of a crackle. */
  hz: number;
  /** Seconds. Very short, but never short enough to click. */
  duration: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. Ablation happens all round the body. */
  pan: number;
}

/**
 * One grain of shield, leaving.
 *
 * Higher and shorter while the fire is at its worst, and as the act cools they
 * drop into the register where they stop being sparks and start being the last
 * of the heat ticking - which is the same physical event described by the same
 * three numbers, and needs no separate voice.
 */
export function spark(rand: () => number, arc01: number): Spark {
  const heat = sheathLevel(arc01);
  const hz = 2200 + rand() * 3600 + heat * 1800;
  return {
    hz,
    duration: 0.05 + rand() * 0.09 - heat * 0.02,
    gain: (0.45 + rand() * 0.55) * (0.35 + 0.65 * heat),
    pan: (rand() * 2 - 1) * 0.85,
  };
}

/** Sparks per second. Dense in the fire, and a slow tick after it. */
export function sparkRate(arc01: number): number {
  const heat = sheathLevel(arc01);
  // Never zero: the cooling stations still have dust in them, and a layer that
  // stops outright is a layer the player notices stopping.
  return 0.9 + heat * 7;
}

export interface ShockSwell {
  /** The band's centre, in Hz. */
  hz: number;
  /** ...and where it sweeps to. Always downward: a roll loses its top first. */
  sweepTo: number;
  /** Seconds. */
  duration: number;
  /** Seconds after the shock begins. */
  delay: number;
  /** 0..1, relative to the track's own level. */
  gain: number;
  /** -1..1. */
  pan: number;
}

/**
 * One passage of the bow shock: three swells from slightly different places.
 *
 * The same construction as the thunder in act II, and for the same reason - a
 * roll is one sound reflected off several things, so the later swells have to
 * arrive from somewhere else or it reads as one filter closing.
 */
export function shockRoll(rand: () => number, arc01: number): ShockSwell[] {
  const heat = sheathLevel(arc01);
  const pan = (rand() * 2 - 1) * 0.7;
  // Late in the act the shock has become weather: higher, softer, and much more
  // like a gust than a pressure wave.
  const wind = 1 - heat;
  // The three swells are derived from the first rather than drawn independently,
  // because a roll has to get longer, lower and quieter *every* time. Drawn
  // separately they sometimes did not, and a middle swell that outlasts the one
  // after it is not a roll dying away, it is three sounds.
  const first = 2.6 + rand() * 1.2;
  return [
    {
      hz: 160 + wind * 220,
      sweepTo: 70 + wind * 90,
      duration: first,
      delay: 0,
      gain: 0.85 + rand() * 0.15,
      pan,
    },
    {
      hz: 115 + wind * 180,
      sweepTo: 55 + wind * 70,
      duration: first * (1.3 + rand() * 0.15),
      delay: 0.6 + rand() * 0.4,
      gain: 0.6 + rand() * 0.15,
      pan: pan * 0.35,
    },
    {
      hz: 88 + wind * 150,
      sweepTo: 46 + wind * 60,
      duration: first * (1.6 + rand() * 0.2),
      delay: 1.5 + rand() * 0.7,
      gain: 0.35 + rand() * 0.15,
      pan: -pan * 0.5,
    },
  ];
}

/** Seconds to the next shock. Tightest while the air is arriving. */
export function shockGap(rand: () => number, arc01: number): number {
  const heat = sheathLevel(arc01);
  return (16 + rand() * 22) * (1.25 - 0.75 * heat);
}
