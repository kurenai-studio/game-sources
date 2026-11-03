/**
 * Slowblue: what going wrong means, and why it now means the same thing everywhere.
 *
 * For two acts the answer used to be one word. A shoal that thinned out, fell
 * behind, or left a dashed ring behind was a run that *ended*, and the player went
 * back to the start of the campaign. Above the tropopause it was a different word:
 * acts III to VI put the station back and charged for it, and act VII's last water
 * could not be lost at all.
 *
 * Three answers to one question, and the seam between them was in the wrong place.
 * The sea and the sky are where a player is least likely to have learned anything
 * yet and most likely to be playing on a phone that is about to ring - so they were
 * the two acts that punished a mistake hardest, and the only two where twenty
 * minutes could go at once. Nothing in the design ever argued for that; it is
 * simply the order the acts were built in.
 *
 * So there is one rule now, and it is the one the upper acts already had - with a
 * count on it:
 *
 * | act        | what a failure does                                             |
 * | ---------- | --------------------------------------------------------------- |
 * | I - VII    | `restart` - back to the top of *this* station, for time and score |
 * | ...twice   | and then the third one ends the run, and the act begins again    |
 * | VII (late) | `none` - nothing ends; the last water cannot be lost             |
 *
 * ## Why the count, and why it is two
 *
 * An unlimited station restart is a station you cannot fail, only take longer
 * over - so an act stops being one performance and becomes six separate ones
 * ground out in any order over any number of attempts. That is a real loss: the
 * campaign's whole claim is that a journey was flown, and a journey assembled from
 * forty-two independently retried fragments is not one.
 *
 * The other end of the argument is worse. Ending the act on the *first* mistake
 * makes a slip on the sixth station delete fifteen to twenty-five minutes of
 * correct play, which is not difficulty - it is repetition of content the player
 * has already proved. The act does not get harder; it gets longer.
 *
 * Two restarts is the smallest budget that answers both: a station may be got
 * wrong and learned, an act may not be ground through, and the third failure
 * costs the attempt rather than the campaign. The budget belongs to the **act
 * attempt** and not to the run, which is why it is stored in `CampaignState`
 * rather than in `RunState` - see `meta/Campaign.ts`. Putting it in the run would
 * mean closing the app and reopening it refilled it, and an interruption must
 * never be worth anything.
 *
 * `none` stays, and it is not an exception to the rule so much as the end of it:
 * the last three stations of the homecoming have no failure state to unify,
 * and inventing one so that the table reads evenly would make the campaign end
 * on a threat. Where act VII *can* fail - its first half - it restarts like
 * everything else.
 *
 * `END_ON_FAILURE` is kept because one thing still uses it: the generated,
 * unauthored water the headless probes measure on (`World.campaign === false`),
 * which has no stations to restart into. No act in the campaign names it.
 *
 * ## Why a restart is a real cost and not a mercy
 *
 * A restart is not a checkpoint in the save-game sense and it is not free. The
 * station is rebuilt from its first section, the swarm goes back to the line it
 * entered on, and everything made since then - the ground, the rings, the streak -
 * is gone. What survives is the campaign: the carried mass, the score already
 * banked less `restartCost`, and the clock, which keeps running throughout. The
 * player loses exactly what the design says they should lose - *position and
 * time* - and never the journey.
 */

/**
 * How many times one act attempt may put a station back before the attempt is
 * over. See the note above for why it is a count, and why it is two.
 *
 * One constant, read by `World` (which spends it) and by `CampaignController`
 * (which remembers what is left). No act may set its own.
 */
export const RESTARTS_PER_ACT = 2;

/**
 * ...and the same argument once the acts stopped being the same length.
 *
 * Two was the smallest budget that answered both ends of the argument above, and
 * it was chosen when every act was about ten authored minutes and a station was
 * about 1.7. Act V is 26.5 minutes now with stations of 4.2 to 5.1, and the rest
 * of the campaign is going the same way - so **the budget per minute of content
 * had quietly halved**, without anybody deciding that it should. A count that does
 * not move while the thing it is counting doubles is not a decision, it is an
 * oversight with a constant in front of it.
 *
 * So it is a *rate* now, in the only unit that holds still: one more restart per
 * seven authored minutes past twelve, floored at the old two and capped at four.
 * Twelve because that is the top of the band the unrebuilt acts sit in, so none of
 * them moves by a single attempt; four because a fifth would make a long act
 * something to be ground out, which is exactly the failure the note above says two
 * was chosen to prevent.
 *
 * | act | authored | restarts |
 * | --- | ---: | ---: |
 * | any act as it was | 7.5 - 12.1 min | 2 |
 * | act V, rebuilt | 26.5 min | 4 |
 *
 * The budget still belongs to the act *attempt* and still lives in `CampaignState`
 * rather than in `RunState`, for the reason above: closing the app must never be
 * worth anything.
 */
export const RESTART_MINUTES = 7;
export const MAX_RESTARTS_PER_ACT = 4;

export function restartsForMinutes(minutes: number): number {
  const extra = Math.floor((minutes - 12) / RESTART_MINUTES);
  return Math.max(RESTARTS_PER_ACT, Math.min(MAX_RESTARTS_PER_ACT, RESTARTS_PER_ACT + extra));
}

/**
 * What a failure does in this act.
 *
 *   * `restart` - the current station begins again, for time and score, while the
 *                 act attempt still has a restart left. When it does not, the run
 *                 ends exactly as `end` does.
 *   * `none`    - nothing ends and nothing restarts. Act VII's last stations.
 *   * `end`     - the run is over. Generated water only; no campaign act uses it.
 */
export type FailureMode = 'end' | 'restart' | 'none';

export interface FailurePolicy {
  mode: FailureMode;
  /**
   * How far behind the frame the swarm may fall before it counts as left behind,
   * as a fraction from the leading edge. Act I's 0.94, and nothing has yet had a
   * reason to move it - the policy exists so that an act *could*.
   */
  strandLine: number;
  /** Seconds it has to stay there. Act I's 0.7. */
  strandGrace: number;
  /**
   * Fraction of the score banked so far that a restart takes. Zero where there is
   * nothing to charge.
   */
  restartCost: number;
}

/**
 * The campaign's one failure rule: a station begins again rather than a run ending.
 *
 * A sixth of the live score is the whole of the price, and it is deliberately a
 * fraction rather than a flat number - a player who has banked very little has
 * very little to lose, and a player twenty minutes in feels it. One constant, one
 * code path (`World.restartStation`), every act: an act that wanted its own price
 * would have to say so out loud, and none of them do.
 */
export const RESTART_ON_FAILURE: FailurePolicy = {
  mode: 'restart',
  strandLine: 0.94,
  strandGrace: 0.7,
  restartCost: 1 / 6,
};

/**
 * Generated water: there is no authored station to go back to, so a failure is
 * the end of the run. Not reachable from the campaign - see the note above.
 */
export const END_ON_FAILURE: FailurePolicy = {
  mode: 'end',
  strandLine: 0.94,
  strandGrace: 0.7,
  restartCost: 0,
};

/** The last water in the campaign. Nothing here can be lost. */
export const NEVER_FAILS: FailurePolicy = {
  mode: 'none',
  strandLine: 0.94,
  strandGrace: 0.7,
  restartCost: 0,
};
