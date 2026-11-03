import { ACT_AIR } from './ascent';
import { ACT_WATER, type Act } from './levels';
import { ACT_ORBIT } from './orbit';
import { ACT_HOME } from './homecoming';
import { ACT_RAIN } from './rain';
import { ACT_REENTRY } from './reentry';
import { ACT_THIN } from './thinning';

/**
 * Slowblue: the whole campaign, in order.
 *
 * Seven acts, and the shape of the list is the point of the game: it is not a
 * climb, it is a circuit. The first four go up - sea, sky, the top of the sky,
 * and then nothing at all - and the last three come back down through rain and
 * river to the floor of the same trench the first frame was shot in. The player
 * is not told this. They find out when the last act's water starts looking
 * familiar.
 *
 * Everything else in the codebase reads acts one at a time; this file is the only
 * place that knows there is an order, which is what lets an act be played on its
 * own from the admin surface or the act-select screen without any of it knowing
 * it is part of a sequence.
 *
 * ## The one rule the list has to obey
 *
 * Consecutive acts must agree at the seam. Act N's last station and act N+1's
 * first are the two halves of a handover: the same altitude, the same palette
 * family, and a carrier that visibly comes out of the previous one. That is
 * checked - `tests/campaignspine.test.ts` walks this list and asserts the
 * altitudes are continuous and monotone through the turn, because "the campaign
 * is one journey" is a claim about numbers and can be tested instead of believed.
 */

export interface ActInfo {
  act: Act;
  /** 1-based. The roman numeral the shell and the admin surface print. */
  number: number;
  name: string;
  /**
   * The player's verb for this act, in one or two words.
   *
   * The only piece of writing the campaign screen shows, and deliberately a
   * *verb* rather than a description: the acts differ in what your hand is doing,
   * and naming that is the shortest true thing that can be said about any of them.
   */
  verb: string;
  /**
   * One line of narrative: what this act *is*, as opposed to what it asks of the
   * player's hand.
   *
   * The map draws seven stretches of one journey and the verb says how each of
   * them is flown, which between them leave out the only thing a journey is made
   * of - that something changes on the way, and it changes because of where you
   * are. Six thousand metres of dark has one way out of it; four hundred
   * kilometres up, nothing pulls back. That is the campaign, and until the map
   * had somewhere to put it, nothing in the shipped build ever said it.
   *
   * One sentence, present tense, about the world rather than about the player.
   */
  arc: string;
}

export const CAMPAIGN: ActInfo[] = [
  {
    act: ACT_WATER,
    number: 1,
    name: 'The Deep',
    verb: 'herd them',
    arc: 'Six thousand metres of dark, and one way out of it: up.',
  },
  {
    act: ACT_AIR,
    number: 2,
    name: 'Flight',
    verb: 'use the wind',
    arc: 'The water runs out beneath them. What is left is the wind.',
  },
  {
    act: ACT_THIN,
    number: 3,
    name: 'The Thinning',
    verb: 'wait, and choose a layer',
    arc: 'Less air at every station, and more patience.',
  },
  {
    act: ACT_ORBIT,
    number: 4,
    name: 'Orbit',
    verb: 'aim ahead of them',
    arc: 'Nothing pulls back any more. From here the whole of it shows.',
  },
  {
    act: ACT_REENTRY,
    number: 5,
    name: 'The Fallback',
    verb: 'brake, and accept the medium',
    arc: 'The orbit becomes a fall, and the air comes up to meet it.',
  },
  {
    act: ACT_RAIN,
    number: 6,
    name: 'The Rain',
    verb: 'gather them',
    arc: 'What went up as water comes back as water.',
  },
  {
    act: ACT_HOME,
    number: 7,
    name: 'The Homecoming',
    verb: 'let them settle, together',
    arc: 'The same trench, the same dark — and it is familiar now.',
  },
];

/** Every act, in play order. */
export const CAMPAIGN_ACTS: Act[] = CAMPAIGN.map((a) => a.act);

/** How many acts the campaign has. One place, so nothing hardcodes seven. */
export const ACT_COUNT = CAMPAIGN.length;

/** Every authored station in the campaign, across every act. */
export const TOTAL_STATIONS = CAMPAIGN.reduce((n, a) => n + a.act.levels.length, 0);

export function actIndexOf(key: string): number {
  return CAMPAIGN.findIndex((a) => a.act.key === key);
}

export function actInfoAt(index: number): ActInfo {
  return CAMPAIGN[Math.max(0, Math.min(CAMPAIGN.length - 1, index))]!;
}

export function actAt(index: number): Act {
  return actInfoAt(index).act;
}

/** The act a key names, or act I if the key is unknown (a stale save, say). */
export function actByKey(key: string): Act {
  const i = actIndexOf(key);
  return i < 0 ? ACT_WATER : CAMPAIGN[i]!.act;
}
