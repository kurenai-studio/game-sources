/**
 * Slowblue: the game is still almost wordless - the water teaches the water. These are
 * the strings around it: the shell, the settings and the two failure sentences.
 * The game ships in English only, so this is one table, not one per language.
 */
export interface StringTable {
  /**
   * The wordmark, and the game's name.
   *
   * It read `BEYOND CURRENTS` for a long time while `<title>`, the manifest's
   * `name` and `short_name`, `apple-mobile-web-app-title` and the icon's own
   * label all said `TIDE` - so an installed build sat on the home screen under
   * one name and opened on another, and a store listing would have had to pick
   * one of them without being told which. §7.4 asked, and the answer at the time
   * was TIDE; the game was renamed Slowblue not long after. What mattered on both
   * occasions is the same thing: this string and the five store-facing ones say
   * one name between them.
   *
   * A name rather than a sentence, so it is the one string here that is not
   * copy to be tuned.
   */
  title: string;
  /**
   * The one line under the wordmark.
   *
   * There were two, and the other one was the pitch - "you do not control the
   * fish, you control the ocean". The water says that for itself inside ten
   * seconds of the first drag, so on the title screen it was a sentence standing
   * between the player and the button. It survives as the page's `<meta
   * description>`, which is the place a pitch is actually read.
   */
  mission: string;
  missionComplete: string;
  play: string;
  playAgain: string;
  newWater: string;
  sameWater: string;
  resume: string;
  restart: string;
  quit: string;
  paused: string;
  /**
   * What the two buttons under it actually cost, and what a failure costs.
   *
   * The only rules text in the build, and it is here because this is the one
   * screen where a player is deciding whether to risk something. RESTART and QUIT
   * both read as "lose what I have done" to anybody who has not been told
   * otherwise, and the honest answer has two halves that must not be confused: an
   * interruption costs the current station, and a third failure costs the act.
   * It is not a help screen and it is not on the way in; see the note at the top
   * of `ui/Shell.ts`.
   */
  saveNote: string;
  close: string;
  back: string;
  best: string;
  newRecord: string;
  depth: string;
  ascent: string;
  shoal: string;
  score: string;
  gates: string;
  rescued: string;
  lost: string;
  reforms: string;
  runs: string;
  failDepleted: string;
  failSwept: string;
  failRing: string;
  failDepletedHint: string;
  failSweptHint: string;
  failRingHint: string;
  /** Act I's own wording, and the fallback for an act with nothing to say. */
  completeTitle: string;
  completeHint: string;
  /** The circuit closing, which is a different event from an act finishing. */
  circuitComplete: string;
  circuitHint: string;
  campaignScore: string;
  carried: string;
  actLabel: string;
  /**
   * The map screen, and the button that opens it.
   *
   * Named for what it draws rather than for what it lists. It was `ACTS` while it
   * was seven rows in a column; it is now the whole journey as one ring, and the
   * title screen already promises a circuit two lines above the button.
   */
  circuit: string;
  /** "acts", lower case, for the `3/7` line under the ring. */
  actsLabel: string;
  actLocked: string;
  /** Marks the act and the station the saved circuit is sitting on. */
  hereLabel: string;
  /** An act with all six stations behind it. */
  actCleared: string;
  /** The disclosure under the ring: the selected act's stations, named. */
  stationList: string;
  /**
   * The title screen's journey card, under the count.
   *
   * The card is the door to the map, and a number with a ring around it does not
   * say that by itself. Three words that do.
   */
  openMap: string;
  continueRun: string;
  cycleLabel: string;
  levelLabel: string;
  levelsCleared: string;
  ringsHeld: string;
  /** The master switch above the mixer. */
  allSound: string;
  /**
   * The six bed labels below are *fallbacks*.
   *
   * Every act names its own layers - rain in the rain, a heartbeat in orbit - and
   * both mixers ask `audio/Beds.ts` first. These are what a slot is called when
   * the bed in play does not fill it, and they are therefore deliberately role
   * names rather than descriptions of any one act's sound.
   */
  audioOcean: string;
  audioMotion: string;
  audioDrone: string;
  audioShimmer: string;
  audioAmbience: string;
  audioWhale: string;
  audioMovement: string;
  audioObjectives: string;
  audioDanger: string;
  audioInterface: string;
  volume: string;
  /**
   * The button on the glass during a run, and the drawer it opens.
   *
   * The settings mixer is four taps and a pause away from the water, which is the
   * wrong distance for the one control in the game that has to be adjusted *while
   * listening*. This one does not pause: the bed goes on playing underneath it, so
   * a slider can be heard rather than guessed at.
   */
  mixer: string;
  /** The drawer's first heading: the layers this act is actually made of. */
  stationLayers: string;
  /** ...and its second: the sounds the game makes at the player, in every act. */
  gameSounds: string;
  /**
   * Continuous circuit mode, in the settings list. Only appears once the player
   * has closed a circuit, because until then the sentence means nothing.
   */
  circuitMode: string;
  /** ...and its own line on the title screen, where a mode has to announce itself. */
  circuitModeHint: string;
  /**
   * The wipe, at the foot of the map that draws what it destroys.
   *
   * It said RESET PROGRESS / SURE? under a column of volume sliders, which is a
   * confirm about a word. Named for the forty-two now, because they are on the
   * screen directly above it.
   */
  eraseStations: string;
  eraseConfirm: string;
  /**
   * Putting the circuit down and setting off again, directly above the wipe.
   *
   * Worded to be told apart from the button under it at a glance, because the two
   * are one press away from each other and only one of them destroys anything.
   * This one says *start* and *new*; the wipe says *erase* and *every station*.
   * Nothing a player earned is at stake here - the record, the unlocked acts and
   * the forty-two all survive - so the confirm names where they are going rather
   * than what they are losing.
   *
   * Both are short enough to hold one line at the width the map's buttons are, and
   * that is a requirement rather than a preference: these two sit directly above
   * each other, and a control that wraps beside one that does not reads as the
   * more important of the two.
   */
  restartJourney: string;
  restartJourneyConfirm: string;
  on: string;
  off: string;
  seedLabel: string;
  zonePrefix: string;
  comboLabel: string;
  installHint: string;
}

export const STRINGS: StringTable = {
  title: 'SLOWBLUE',
  mission: 'A quiet place beneath the noise',
  missionComplete: 'MISSION COMPLETE',
  play: 'BEGIN',
  playAgain: 'AGAIN',
  newWater: 'NEW WATER',
  sameWater: 'SAME WATER',
  resume: 'RESUME',
  restart: 'RESTART',
  quit: 'QUIT',
  paused: 'PAUSED',
  saveNote:
    'The game saves after every station you clear, and an interruption puts you back at ' +
    'the start of the current one. You have two restarts inside an act; the third loss ' +
    'returns you to the act’s beginning.',
  close: 'CLOSE',
  back: 'BACK',
  best: 'Best',
  newRecord: 'NEW RECORD',
  depth: 'Ascent',
  ascent: 'climbed',
  shoal: 'Shoal',
  score: 'Score',
  gates: 'gates',
  rescued: 'rescued',
  lost: 'lost',
  reforms: 're-forms',
  runs: 'Runs',
  failDepleted: 'THE SHOAL FELL APART',
  failSwept: 'THE SHOAL WAS LEFT BEHIND',
  failRing: 'THE RING WAS LEFT EMPTY',
  failDepletedHint: 'Rock and panic wore it down. Steer cleaner.',
  failSweptHint: 'The current pulled away from you. Commit earlier.',
  failRingHint: 'A dashed ring has to be filled. Hold most of the shoal inside it.',
  completeTitle: 'YOU REACHED THE SURFACE',
  completeHint: 'After six stations, you broke through the waterline. The shoal held together.',
  circuitComplete: 'THE CIRCLE IS CLOSED',
  circuitHint:
    'Seven acts, one journey. You did not go up — you went round. You started on the floor of the trench, and that is where you arrived.',
  campaignScore: 'For the whole journey',
  carried: 'carried',
  actLabel: 'Act',
  circuit: 'THE CIRCUIT',
  actsLabel: 'acts',
  actLocked: 'LOCKED',
  hereLabel: 'YOU ARE HERE',
  actCleared: 'CLEARED',
  stationList: 'Stations',
  openMap: 'Open the map',
  continueRun: 'CONTINUE',
  cycleLabel: 'circuit',
  levelLabel: 'Station',
  levelsCleared: 'stations',
  ringsHeld: 'rings',
  allSound: 'All sound',
  audioOcean: 'The medium',
  audioMotion: 'Motion',
  audioDrone: 'Deep drone',
  audioShimmer: 'Shimmer',
  audioAmbience: 'Distant bells',
  audioWhale: 'Distant voices',
  audioMovement: 'Your hand',
  audioObjectives: 'Objective cues',
  audioDanger: 'Danger',
  audioInterface: 'Interface',
  volume: 'Volume',
  mixer: 'Sound layers',
  stationLayers: "This station's layers",
  gameSounds: 'Game sounds',
  circuitMode: 'Continuous circuit',
  circuitModeHint: 'Continuous circuit: the trench floor is not the end of it.',
  eraseStations: 'ERASE EVERY STATION',
  eraseConfirm: 'THE WHOLE JOURNEY?',
  restartJourney: 'START A NEW JOURNEY',
  restartJourneyConfirm: 'BACK TO ACT I?',
  on: 'ON',
  off: 'OFF',
  seedLabel: 'Water',
  zonePrefix: '',
  comboLabel: 'streak',
  installHint: 'Add to home screen for a full-screen game.',
};

/**
 * Slowblue: how each act ends, in its own words.
 *
 * There were two of these - the water's and the air's - selected by a boolean,
 * and five acts arrived after them. So the shipped build told a player who had
 * just turned the camera at four hundred and sixty thousand metres that they had
 * broken through the waterline, and told a player whose droplets scattered in a
 * rain cloud that the current had pulled away from them. Every ending in acts
 * III to VII was the sea's.
 *
 * Keyed by act, because that is what actually differs. Two endings each: the one
 * the act is for, and the one that means the medium got away from you - which is
 * a different sentence in every medium, and is the only place the game ever says
 * out loud what the act was about.
 *
 * Act II's copy is also corrected here rather than carried over. It claimed
 * eighty-two kilometres and the last noctilucent cloud, which was true of the act
 * that used to run to the mesopause; the anvil is at eleven, and §6 is explicit
 * that where the act ends is load-bearing.
 */
export interface ActEndings {
  complete: string;
  completeHint: string;
  /** "The medium got away from you", in this medium's terms. */
  swept: string;
  sweptHint: string;
}

const ENDINGS: Record<string, ActEndings> = {
  water: {
    complete: 'YOU REACHED THE SURFACE',
    completeHint: 'After six stations, you broke through the waterline. The shoal held together.',
    swept: 'THE SHOAL WAS LEFT BEHIND',
    sweptHint: 'The current pulled away from you. Commit earlier.',
  },
  air: {
    complete: 'YOU REACHED THE TOP OF THE ANVIL',
    completeHint:
      'Eleven kilometres: where the weather stops. Nothing with wings goes higher — but what the flock carried this far keeps rising without it.',
    swept: 'THE FLOCK WAS LEFT BEHIND',
    sweptHint: 'The wind goes on without you. Lay the air earlier.',
  },
  thin: {
    complete: 'YOU CROSSED THE LINE',
    completeHint:
      'A hundred kilometres. From here the air carries nothing further — momentum does.',
    swept: 'YOU STAYED IN THE WRONG LAYER',
    sweptHint: 'Up here, choosing a layer is worth more than any stroke. Wait, and choose.',
  },
  orbit: {
    complete: 'THE OVERVIEW',
    completeHint:
      'From here the whole of it shows: everything that has happened, one thin bright line above the limb. From here the way is down.',
    swept: 'THE ORBIT LEFT YOU',
    sweptHint: 'A well acts late. Aim where they are going, not where they are.',
  },
  reentry: {
    complete: 'YOU CAME THROUGH',
    completeHint:
      'The dust cooled and became a nucleus. Every drop that falls after this is built on one.',
    swept: 'YOU CAME IN AT THE WRONG ANGLE',
    sweptHint: 'Brake earlier. The air thickens with every kilometre, and it will not wait.',
  },
  rain: {
    complete: 'YOU REACHED THE SEA',
    completeHint:
      'Cloud to drop, drop to brook, brook to river. Where fresh water turns salt, the light becomes alive again.',
    swept: 'THE CURRENT LEFT YOU',
    sweptHint: 'Everything is faster on the way down. Gather them before they scatter.',
  },
  home: {
    complete: 'YOU CAME HOME',
    completeHint: 'To the floor of the trench, where the first frame was shot.',
    swept: 'THE SWARM WAS LEFT BEHIND',
    sweptHint: 'Nothing hurries you down here. Let them settle.',
  },
};

/** How this act ends. Falls back to act I for an unknown key. */
export function endingsFor(actKey: string): ActEndings {
  return ENDINGS[actKey] ?? ENDINGS.water!;
}
