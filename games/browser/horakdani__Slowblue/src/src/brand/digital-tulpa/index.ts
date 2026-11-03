import './ident.css';

/**
 * digitalTULPA — studio ident.
 *
 * Deliberately free of every dependency on the project it happens to be sitting
 * in. It imports nothing but its own stylesheet, reads no shared settings, brings
 * its own background and its own colour, and talks to the host in exactly two
 * ways: an `onComplete` callback and a `digitaltulpa:introcomplete` event on
 * `window`. Copy the folder into another project and it plays there unchanged.
 *
 * A tulpa is a thought-form that is imagined so completely it starts acting on its
 * own. Both variants are that sentence, told from opposite ends:
 *
 *   summon  the form is *built* — brackets close in, quotes drop, the rings are
 *           drawn stroke by stroke, and only then does something arrive inside
 *           them and look around. You watch it being made.
 *
 *   reveal  the form is already there, vast and out of focus, looking past you.
 *           The camera walks backwards until it resolves — and the last thing it
 *           does is find you. You discover it was always looking.
 *
 * Same lockup, same 6.6 seconds, opposite claim.
 */

export type IdentVariant = 'summon' | 'reveal';

/** Changing this line changes which ident a project plays. */
export const DEFAULT_IDENT_VARIANT: IdentVariant = 'summon';

export const DIGITAL_TULPA_IDENT_DURATION_MS = 6600;
export const DIGITAL_TULPA_REDUCED_DURATION_MS = 1200;

/** Kept under its old name because the host game imports the ident by it. */
export const DIGITAL_TULPA_INTRO_DURATION_MS = DIGITAL_TULPA_IDENT_DURATION_MS;

/** How long a skipped ident takes to get off the screen. */
const DISMISS_FADE_MS = 300;

const BLINK_MS = 320;
const SLOW_BLINK_MS = 560;

/**
 * The cutout goes where the eye is looking, and this is not the physics answer.
 *
 * A specular highlight is a reflection: it stays where the light is and barely
 * moves as the eye turns. That is true, it is what I built, and on this mark it
 * looks wrong — because this cutout is not a highlight. At r=10.5 offset 17 on a
 * pupil of r=24, it reaches 27.5 from centre and *breaks the pupil's silhouette*.
 * A shape that opens the pupil into a crescent is not read as light on a sphere;
 * it is read as the pupil's own form, and the direction the crescent opens is the
 * direction the eye appears to be looking.
 *
 * Pinning it up-left therefore pinned the gaze up-left, no matter where the pupil
 * actually went. The original mark had this right and I broke it. It follows the
 * look again.
 */
const CUTOUT_DISTANCE = 17;

/*
 * A fixating eye does not hold its mark. It lands, slips off it within about half
 * a second, and is pulled back — a microsaccade, and it is the reason a real gaze
 * never reads as *aimed*. The continuous drift already stops the pupil being
 * frozen; this is the discrete version, and it is what makes the eye look like it
 * is considering something rather than pointing at it.
 *
 * The roll is the other half, and it is the one that took three passes to get
 * right. Every gaze step has always carried a tilt, but at the 0.2-0.36 degrees it
 * shipped with, the rotation was below the threshold where anything is visible at
 * all — the number was there and the effect was not. Rotating the gaze layer turns
 * the pupil disc, which is a circle and so shows nothing; the entire visible effect
 * is the *cutout* swinging around the pupil's centre, and it sits at radius 17, so
 * the arc it travels is 17·sin(θ). At 3° that is 0.9 units, under two pixels, still
 * not enough. These are the numbers that read:
 *
 *   saccade roll    3-7.5°   →  0.9-2.2 units of crescent travel
 *   micro roll      ±9°      →  2.7 units on top of it
 *   micro offset    3.2/2.4  →  4 units, about nine pixels at full size
 *
 * Turn MICRO_TILT for more or less of the roll; it is the only dial that matters.
 */
const MICRO_AT = 750;
const MICRO_BACK = 1300;
const MICRO_X = 3.2;
const MICRO_Y = 2.4;
const MICRO_TILT = 9;
/** How long the slip off the mark takes, and how long the pull back does. */
const MICRO_OUT_MS = 380;
const MICRO_BACK_MS = 440;

/** One settled position of the pupil, at an absolute time. */
export interface GazeMark {
  at: number;
  x: number;
  y: number;
  tilt: number;
  /** How long the move onto this position takes. */
  ms: number;
  /** True for a real saccade, which overshoots; false for the micro moves. */
  saccade: boolean;
}

/**
 * The gaze list with its microsaccades written out.
 *
 * Exported because `brand.html` scrubs the performance and has to be able to ask
 * where the pupil is at time t. Deriving it in one place is the only way the
 * scrubber and the ident can be made to agree — the bench has lied about a beat it
 * did not know existed once already.
 *
 * The final step gets no micro. It is the one where the ident stops looking around
 * and settles, and a wander laid over that is a wander over the point of it.
 */
export function expandGaze(beats: Choreography): GazeMark[] {
  const marks: GazeMark[] = [];
  beats.gaze.forEach((step, index) => {
    marks.push({ at: step.at, x: step.x, y: step.y, tilt: step.tilt, ms: 340, saccade: true });
    if (index === beats.gaze.length - 1) return;
    // Alternating, so the eye never slips the same way twice running.
    const sign = index % 2 === 0 ? 1 : -1;
    marks.push({
      at: step.at + MICRO_AT,
      x: step.x + MICRO_X * sign,
      y: step.y - MICRO_Y * sign,
      tilt: step.tilt + MICRO_TILT * sign,
      ms: MICRO_OUT_MS,
      saccade: false,
    });
    marks.push({
      at: step.at + MICRO_BACK,
      x: step.x,
      y: step.y,
      tilt: step.tilt,
      ms: MICRO_BACK_MS,
      saccade: false,
    });
  });
  return marks;
}

interface GazeStep {
  /** Milliseconds from the first frame of the ident. */
  at: number;
  x: number;
  y: number;
  tilt: number;
}

interface BlinkStep {
  at: number;
  /** The closing blink is heavier, so that it reads as a decision and not a tic. */
  slow?: boolean;
}

interface Choreography {
  /** When each eye's arrival ping fires, in the order the eyes are in the DOM. */
  pings: readonly [number, number];
  gaze: readonly GazeStep[];
  blinks: readonly BlinkStep[];
  wordmarkStart: number;
  wordmarkInterval: number;
  /** When TULPA lands, as one word, after the lowercase has finished. */
  accentAt: number;
}

/** `digital` is seven letters; everything after it is the accent. */
const ACCENT_FROM = 7;

/**
 * The whole performance, as numbers.
 *
 * Every beat is an absolute offset from the first frame rather than a delay from
 * the previous one, because the thing that actually goes wrong in an ident is two
 * events landing on the same 100ms — and that is obvious in a column of absolute
 * times and invisible in a chain of relative ones. The entrance beats live in
 * `ident.css`; these are the ones the script owns.
 *
 * Both variants finish their performance by 5.8s and the frame holds empty-handed
 * until 6.1s, where `dt-lifecycle` starts the fade. Nothing may be scheduled after
 * 5.8s: a gesture that begins under a fade reads as a dropped frame.
 */
export const CHOREOGRAPHY: Record<IdentVariant, Choreography> = {
  /*
   * Built, outside-in. The construction runs to 2.4s in CSS; the script picks it
   * up at the moment the pupils land and something is finally there to look.
   */
  summon: {
    pings: [1980, 2070],
    /*
     * Small, and all of them down and to the left.
     *
     * The first pass swung ±9 units and crossed the midline — up-right, then
     * down-left, then dead centre — and it read as a mechanism being demonstrated
     * rather than as something looking around. Eyes at rest do not sweep; they sit
     * slightly below the horizon and drift within a narrow cone, and they almost
     * never travel far without the head going too. Nothing here moves more than 7
     * units on a 49.5 eye, and nothing crosses the centre line.
     *
     * The last beat is not quite zero on purpose. The cutout takes its direction
     * from the gaze vector, so a gaze of exactly (0,0) has no direction to give it;
     * (-2, 1.4) is optically centre — two pixels on a hundred-pixel eye — and still
     * tells the crescent which way to face.
     */
    gaze: [
      { at: 2900, x: -5, y: 3.2, tilt: 5 },
      { at: 4900, x: -2, y: 1.4, tilt: 3 },
    ],
    /*
     * Two blinks, not three, and 2.7 seconds between them.
     *
     * A resting eye blinks every three to five seconds; three blinks in three
     * seconds is a face that is nervous. The middle one used to sit 40ms ahead of
     * a saccade to hide it, which is what real eyes do — but that saccade is gone
     * now, and a blink kept only for a trick it is no longer playing is just one
     * more thing twitching.
     */
    blinks: [{ at: 2540 }, { at: 5200, slow: true }],
    wordmarkStart: 3560,
    wordmarkInterval: 88,
    accentAt: 4400,
  },
  /*
   * Revealed. `dt-reveal-pull` and `dt-reveal-pupil` own the first 2.4s outright —
   * the pupil drifts off-axis under CSS and only centres as the focus lands — so
   * the scripted gaze deliberately starts after them and never fights for the same
   * element.
   */
  reveal: {
    // Both at once: this is one revelation rather than two eyes waking up in turn,
    // and it lands on `dt-reveal-pupil`'s 82% — the frame the pupil finds you.
    pings: [2350, 2350],
    gaze: [
      { at: 3300, x: -5, y: 3.2, tilt: 5 },
      { at: 4850, x: -2, y: 1.4, tilt: 3 },
    ],
    blinks: [{ at: 2900 }, { at: 5250, slow: true }],
    wordmarkStart: 3560,
    wordmarkInterval: 88,
    accentAt: 4400,
  },
};

export interface IdentOptions {
  /**
   * Which of the two performances to play. Defaults to
   * {@link DEFAULT_IDENT_VARIANT}.
   */
  variant?: IdentVariant;
  /**
   * Plays the still, 1.2-second variant instead of the performance.
   *
   * Deliberately *not* wired to a host project's "reduced motion" setting — see
   * {@link IdentOptions.respectReducedMotionMedia}.
   */
  reducedMotion?: boolean;
  /**
   * Honour `prefers-reduced-motion: reduce` from the OS. **Off by default, and
   * that is a considered position rather than an oversight.**
   *
   * The ident used to consult it. The result was that most phones never saw it:
   * iOS puts Reduce Motion one tap into Accessibility and plenty of people leave
   * it on for reasons that have nothing to do with a logo. What they got was a
   * lockup that appeared and vanished in 1.2 seconds — which reads as a bug, and
   * got reported as one.
   *
   * The setting is not being ignored, it is being scoped. It exists for things
   * that move a screenful at a time; this is a fixed lockup with a two-pixel eye
   * performance inside it, with no vestibular load in it to suppress. A project
   * that disagrees can flip this to `true` and get the still instead.
   */
  respectReducedMotionMedia?: boolean;
  /**
   * Lets an automated browser see the ident, which by default it does not.
   *
   * A seven-second ident on every navigation turns a test suite into a test of a
   * clock, so `navigator.webdriver` skips it unless something opts back in.
   */
  force?: boolean;
  /** A development door straight to whatever is behind the ident. */
  skip?: boolean;
  /**
   * Plays and stays — the ident never takes itself off the screen.
   *
   * For `brand.html`, which freezes the whole performance and scrubs it. Nothing
   * in a shipping path should set this.
   */
  hold?: boolean;
  /** Stacking order, if the host has something above 1000. */
  zIndex?: number;
  /**
   * Fires once, after the ident has left the screen — on natural end, on skip, and
   * on the paths where it declines to play at all. The element is already detached
   * when it runs, so a host can hand straight over without waiting for anything.
   */
  onComplete?: () => void;
}

/** Parses `?intro=…` into options. Exported so other projects can reuse the door. */
export function identOptionsFromSearch(search: string): Partial<IdentOptions> {
  const params = new URLSearchParams(search);
  const value = params.get('intro');
  return {
    variant: value === 'reveal' || value === 'summon' ? value : DEFAULT_IDENT_VARIANT,
    reducedMotion: value === 'reduced',
    force: value !== null,
    skip: params.has('skipIntro'),
  };
}

function eyeMarkup(side: 'left' | 'right', x: number): string {
  return `
          <g class="eye eye-${side}" transform="translate(${x} 79)">
            <!--
              The ring gets a wrapper, and the wrapper is not decoration.

              Two separate things move this ring: the entrance draws it, once, by
              animating stroke-dashoffset; the performance blinks it, repeatedly,
              by animating transform and opacity. They touch disjoint properties
              and could have shared one element — except that CSS resolves the
              animation property as a whole list, so the blink rule did not *add*
              to the draw, it replaced it. Every blink therefore cancelled the
              draw, and removing the class 320ms later created it afresh: 880ms of
              delay with a backwards "both" fill, which is stroke-dashoffset at
              full length. The measured result was an eye ring that vanished at
              2.9s and was still gone at 3.6s, three times per ident.

              One animation per element is the fix that cannot come back. The draw
              stays on the path; blink and focus move to the wrapper.
            -->
            <g class="ring-layer">
              <!--
                Two semicircles rather than a <circle>, and only so that the ring
                starts at the top: SVG puts a circle's path origin at three
                o'clock, and a ring that closes from the side reads as an accident
                where one that closes from twelve reads as a decision. Two arcs and
                not one — a single 360° arc has coincident endpoints, which the
                spec says to drop entirely, and dropping it is exactly what
                browsers do. Same geometry, same 311.02 of length, clockwise from
                the top.
              -->
              <path
                class="eye-ring"
                d="M 0 -49.5 A 49.5 49.5 0 0 1 0 49.5 A 49.5 49.5 0 0 1 0 -49.5"
              />
            </g>
            <circle class="eye-ping" r="49.5" aria-hidden="true" />
            <g class="blink-lines" aria-hidden="true">
              <line x1="-31" y1="-4" x2="31" y2="-4" />
              <line x1="-31" y1="4" x2="31" y2="4" />
            </g>
            <g class="blink-layer">
              <g class="eye-core">
                <!--
                  Ocular drift, and it is the one thing that separates a drawing
                  with an animation on it from something alive. A real eye never
                  holds still: even fixated on one point it wanders about a degree,
                  continuously, and the wander is what the viewer reads as
                  attention rather than as a paused file. Barely two pixels, and the
                  two eyes run out of phase so the pair never drifts as a unit.
                -->
                <g class="drift-layer">
                  <g class="gaze-layer">
                    <g class="pupil-arrive">
                      <circle class="pupil-dot" r="24" />
                      <circle class="pupil-cutout" r="10.5" />
                    </g>
                  </g>
                </g>
              </g>
            </g>
          </g>`;
}

/**
 * A bracket, with two echoes of itself trailing behind it.
 *
 * The echoes are `<use>` of the real path, so there is one shape on the page and
 * the trail can never drift out of register with it. They compound: a `<use>`
 * carries its own transform *on top of* whatever the referenced element is doing,
 * so an echo that runs its own 30-unit travel while the source runs its 70 sits
 * 100 out at the start and lands on zero at the same moment. That is a trail, and
 * it is drawn rather than blurred — the mark stays a hard flat vector, and the
 * speed is expressed by the number of copies rather than by softening the one.
 */
function bracketMarkup(id: string, kind: 'open' | 'close', trail: boolean, d: string): string {
  const echoes = trail
    ? `
          <use class="bracket-echo echo-far echo-${kind}" href="#${id}" aria-hidden="true" />
          <use class="bracket-echo echo-near echo-${kind}" href="#${id}" aria-hidden="true" />`
    : '';
  return `${echoes}
          <path id="${id}" class="bracket bracket-${kind}" d="${d}" />`;
}

const WORDMARK = 'digitalTULPA';

function markup(): string {
  const letters = [...WORDMARK]
    .map((character, index) => {
      // Seven lowercase, five capitals: the capitals are the accent, and the split
      // is the wordmark's whole idea rather than a styling detail.
      const accent = index >= 7 ? ' wordmark-accent' : '';
      return `<span class="dt-letter${accent}" style="--dt-letter-index:${index}">${character}</span>`;
    })
    .join('');

  return `
    <div class="brand-lockup">
      <!--
        158 tall until the mark had a mouth, and the number was load-bearing: it
        put the eye line at exactly half the frame. It cannot stay. A mouth needs
        air under the nose to read as a mouth rather than as a rule under it, and
        158 had eight units left below the nostrils — every version drawn inside
        that box hung off the nose no matter what shape it was.

        251 is the ink centred again: 29.5 at the top of the rings, 221 at the
        bottom of the mouth, 30 of margin at both ends. The eye line lands at 31%
        of the frame instead of 50%, and that is not a compromise — a portrait puts
        the eyes above centre, and this drawing is a portrait now.

        The width is untouched, so every horizontal figure in this file still
        holds. The reveal pull's origin does not: it is a percentage of the
        viewBox, and it moved with this. See .is-reveal .tulpa-logo in the CSS.

        (No backticks in here. This whole return value is one template literal,
        and a stray backtick in a comment ends the string 60 lines early.)
      -->
      <svg
        class="tulpa-logo"
        viewBox="0 0 858 251"
        role="img"
        aria-label="digitalTULPA"
      >
        <g class="mark mark-left">
${bracketMarkup('dt-bkt-l-open', 'open', true, 'M 105 41 L 105 53 L 43 78 L 105 104 L 105 116 L 28 84 L 28 73 Z')}
          <text class="quote" x="117" y="94" aria-hidden="true">“</text>
${eyeMarkup('left', 222)}
${bracketMarkup('dt-bkt-l-close', 'close', false, 'M 286 41 L 286 53 L 348 78 L 286 104 L 286 116 L 363 84 L 363 73 Z')}
        </g>

        <g class="separator" aria-hidden="true">
          <rect x="402" y="117" width="17" height="15" />
          <rect x="449" y="117" width="17" height="15" />
        </g>

        <!--
          The lockup was always a face. This is the part that admits it.

          Two eyes, and between them a pair of low dots that the file has been
          calling a colon since it was written — except a colon is stacked and
          these two sit side by side, below the eye line, in the middle of the
          drawing. They are nostrils, and once you have seen that you cannot see
          the punctuation again. The mouth is the piece that was missing, not a
          decoration added underneath a mark that was finished.

          Flat, level and closed, and that is the tone rather than a shortcut. A
          curve up is a smiley and a curve down is a frown, and both turn a
          thought-form that watches you into a character with a mood. This one is
          composed: the mark's claim is attention, not friendliness.

          The ends are round, and both alternatives were built and looked at
          first. Tapered to a point at each end — drawn the way the brackets are
          drawn, on the argument that the mark has no curves in it — reads as a
          quill stroke or a stretched diamond, and the two thin tips are the first
          thing to disappear at phone size. Square ends read as a censor bar laid
          over the face. A full semicircular cap is the terminal the mark already
          owns: the quotes end that way and .blink-lines are drawn with
          stroke-linecap: round, so it is the eye's own vocabulary rather than a
          softening imported for this one shape.

          The numbers, and what each one is measured against:

            centre x 434   the nose's, not the eyes'. The eyes' midpoint is 459
                           and the drawing's is 432.5; nose and mouth share one
                           midline or the face has two.
            width 66       1.4x the nostrils' 46, which is the ratio a mouth has
                           to a nose. Every wider version — 136, 124, 112 — was
                           measured against the 139 units of air between the two
                           marks instead, and filling that gap is the wrong job:
                           it makes the mouth a rule spanning the negative space
                           rather than a feature belonging to the nose above it.
            height 6       the eye ring's stroke width, exactly. That is the
                           mark's line weight, and the mouth is a line. Matching
                           the nostrils' 10.8 instead was the first try and it
                           came out as a bar: the nostrils are *shapes*, small
                           enough to be solid, and copying their mass onto
                           something 112 long makes a slab.
            centre y 218   85 units of air under the nostrils, against the 45 the
                           nose sits below the eyes. It went 13, 36, 57 and each
                           one still read as hung off the nose. The nostrils are
                           the thing that makes this counter-intuitive: they sit
                           high, right under the eye line, so the mouth is not
                           placed relative to them — it goes where a mouth goes in
                           the frame, and the gap is whatever is left over.
        -->
        <path
          class="mouth"
          aria-hidden="true"
          d="M 404 215 L 464 215 A 3 3 0 0 1 464 221 L 404 221 A 3 3 0 0 1 404 215 Z"
        />

        <g class="mark mark-right">
${bracketMarkup('dt-bkt-r-open', 'open', false, 'M 579 41 L 579 53 L 517 78 L 579 104 L 579 116 L 502 84 L 502 73 Z')}
          <text class="quote" x="591" y="94" aria-hidden="true">“</text>
${eyeMarkup('right', 696)}
${bracketMarkup('dt-bkt-r-close', 'close', true, 'M 760 41 L 760 53 L 822 78 L 760 104 L 760 116 L 837 84 L 837 73 Z')}
        </g>
      </svg>
    </div>

    <!--
      The rule is not a decoration under the name, it is the thing that puts the
      name there. A short bright head runs the width of the rail and the hairline
      is drawn in behind it, and the letters resolve as it passes over them — so
      one gesture does the ruling and the revealing, instead of a line appearing
      for no reason and a typewriter starting for no reason.
    -->
    <div class="wordmark-rail" aria-hidden="true">
      <span class="wordmark-rule"></span>
      <span class="wordmark-sweep"></span>
    </div>
    <!--
      Hidden from the accessibility tree, not labelled.

      It carried an aria-label on a plain div, which is invalid — aria-label needs
      a role to attach to — and it left the twelve per-letter spans exposed as
      twelve separate text nodes underneath it. The typewriter needs those spans; a
      screen reader does not need to read the studio's name one letter at a time,
      and it has already had it once from the SVG above.
    -->
    <div class="wordmark" aria-hidden="true">${letters}</div>
  `;
}

/**
 * Plays the ident over whatever is already on the page.
 *
 * Nothing behind it is torn down or deferred: the host boots normally and the
 * ident covers it, making every sibling `inert` for its lifetime. That keeps the
 * host's startup path honest while preventing a tap aimed at the animation from
 * reaching a control underneath it — which is exactly how a press of Space once
 * both skipped this ident and started a run in the game behind it.
 *
 * Returns a function that ends the ident immediately.
 */
export function playDigitalTulpaIdent(options: IdentOptions = {}): () => void {
  const variant = options.variant ?? DEFAULT_IDENT_VARIANT;

  /*
   * Declining to play still has to signal that it is done.
   *
   * This used to return a bare no-op, which is fine for a host that decides for
   * itself whether the ident is playing — and a trap for the one in the README,
   * `playDigitalTulpaIdent({ onComplete: () => showTitleScreen() })`, which under
   * `?skipIntro` or an automated browser would sit on a blank page forever waiting
   * for a callback that was never going to come.
   *
   * Deferred rather than synchronous, because a host that listens on `window`
   * registers its listener after this call returns.
   */
  if (options.skip || (options.force !== true && navigator.webdriver)) {
    let settled = false;
    const settle = (): void => {
      if (settled) return;
      settled = true;
      options.onComplete?.();
      window.dispatchEvent(
        new CustomEvent('digitaltulpa:introcomplete', { detail: { duration: 0, variant } }),
      );
    };
    window.setTimeout(settle, 0);
    return settle;
  }

  /*
   * One flag decides both the stylesheet's lifetime and the script's, or they
   * disagree.
   *
   * `respectReducedMotionMedia` used to reach only the CSS: the media query set
   * `--dt-duration: 1200ms` and the element faded out on schedule, while the
   * script went on believing in 6600ms — so it left the host's siblings `inert`
   * and its keydown capture installed for five and a half seconds after the ident
   * had visually gone, and reported the wrong duration on the way out.
   */
  const reduced =
    options.reducedMotion === true ||
    (options.respectReducedMotionMedia === true &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches);
  const beats = CHOREOGRAPHY[variant];

  /*
   * A `div`, not a `main`.
   *
   * The host almost certainly has a `<main>` of its own — Slowblue does — and two of
   * them is an invalid document with two competing main landmarks. It carries no
   * `aria-label` either: the SVG inside is `role="img"` with the studio's name on
   * it, so the name is already announced once, and an unlabelled generic wrapper
   * adds nothing for a screen reader to say twice.
   */
  const ident = document.createElement('div');
  ident.id = 'digitaltulpa-intro';
  ident.className = [
    'dt-ident',
    'is-playing',
    `is-${variant}`,
    reduced ? 'is-reduced' : '',
    options.respectReducedMotionMedia === true ? 'respects-motion-preference' : '',
  ]
    .filter(Boolean)
    .join(' ');
  if (options.zIndex !== undefined) ident.style.setProperty('--dt-z', String(options.zIndex));
  ident.innerHTML = markup();
  document.body.append(ident);

  const blocked = [...document.body.children]
    .filter((child): child is HTMLElement => child instanceof HTMLElement && child !== ident)
    .map((element) => ({ element, inert: element.inert }));
  for (const { element } of blocked) element.inert = true;
  if (document.activeElement instanceof HTMLElement) document.activeElement.blur();

  const eyes = [...ident.querySelectorAll<SVGGElement>('.eye')];
  const letters = [...ident.querySelectorAll<HTMLSpanElement>('.wordmark span')];
  const duration = reduced ? DIGITAL_TULPA_REDUCED_DURATION_MS : DIGITAL_TULPA_IDENT_DURATION_MS;

  let finished = false;
  let timers: number[] = [];
  let typewriterFrame: number | null = null;

  const later = (callback: () => void, delay: number): void => {
    timers.push(window.setTimeout(callback, delay));
  };

  const clearTimers = (): void => {
    for (const timer of timers) window.clearTimeout(timer);
    timers = [];
  };

  /** Restarts a CSS animation that may already be mid-flight on this element. */
  const replay = (element: Element, className: string, forMs: number): void => {
    element.classList.remove(className);
    void element.getBoundingClientRect();
    element.classList.add(className);
    later(() => element.classList.remove(className), forMs);
  };

  const cutoutFor = (x: number, y: number): { x: number; y: number } => {
    const distance = Math.hypot(x, y) || 1;
    return { x: (x / distance) * CUTOUT_DISTANCE, y: (y / distance) * CUTOUT_DISTANCE };
  };

  /**
   * A saccade, which is not a pan.
   *
   * Eyes do not glide between targets — they snap, overshoot slightly and settle.
   * So this is two moves: 90ms of ballistic overshoot past the target, then 210ms
   * of correction back onto it. The two eyes are given a hair of divergence so the
   * pair never looks like one symmetrical graphic doing a symmetrical thing.
   */
  const lookAt = (mark: GazeMark): void => {
    eyes.forEach((eye, index) => {
      const gaze = eye.querySelector<SVGGElement>('.gaze-layer');
      if (gaze === null) return;

      const divergence = index === 0 ? -0.15 : 0.15;
      const apply = (x: number, y: number, tilt: number, ms: number): void => {
        const cutout = cutoutFor(x, y);
        gaze.style.setProperty('--dt-gaze-duration', `${ms}ms`);
        gaze.style.setProperty('--dt-gaze-x', `${x.toFixed(2)}px`);
        gaze.style.setProperty('--dt-gaze-y', `${y.toFixed(2)}px`);
        gaze.style.setProperty('--dt-gaze-tilt', `${tilt.toFixed(3)}deg`);
        gaze.style.setProperty('--dt-cutout-x', `${cutout.x.toFixed(2)}px`);
        gaze.style.setProperty('--dt-cutout-y', `${cutout.y.toFixed(2)}px`);
      };

      if (!mark.saccade) {
        // A microsaccade is not ballistic. It is a slip and a correction, so it
        // goes straight to where it is going and does not announce itself with an
        // overshoot the way a real look does.
        apply(mark.x + divergence * 0.5, mark.y, mark.tilt, mark.ms);
        return;
      }

      // Barely an overshoot at all now. At 1.14 the correction was a visible
      // second move, at 1.05 it still snapped; on travels this small a ballistic
      // error reads as a twitch rather than as muscle, and the whole eye is meant
      // to be slower than that.
      apply(mark.x * 1.03 + divergence, mark.y * 1.03, mark.tilt * 1.05, 150);
      replay(eye, 'is-focusing', 320);
      later(() => apply(mark.x + divergence * 0.5, mark.y, mark.tilt, mark.ms), 152);
    });
  };

  const blink = (slow = false): void => {
    const className = slow ? 'is-blinking-slow' : 'is-blinking';
    const held = slow ? SLOW_BLINK_MS : BLINK_MS;
    // A few milliseconds apart, because two eyes that shut on the same frame are
    // a shutter and not a face.
    eyes.forEach((eye, index) => later(() => replay(eye, className, held), index * 7));
  };

  const startTypewriter = (): void => {
    const swept = letters.slice(0, ACCENT_FROM);
    const accents = letters.slice(ACCENT_FROM);
    const startedAt = performance.now() + beats.wordmarkStart;

    // `digital` resolves letter by letter, under the sweep's head.
    const render = (now: number): void => {
      const visible = Math.max(
        0,
        Math.min(swept.length, Math.floor((now - startedAt) / beats.wordmarkInterval) + 1),
      );
      swept.forEach((letter, index) => letter.classList.toggle('is-typed', index < visible));
      typewriterFrame = visible < swept.length ? window.requestAnimationFrame(render) : null;
    };
    typewriterFrame = window.requestAnimationFrame(render);

    // TULPA arrives all at once, after a gap. One class, five letters, one word.
    later(() => {
      for (const letter of accents) letter.classList.add('is-typed');
    }, beats.accentAt);
  };

  const stopPerformance = (): void => {
    clearTimers();
    if (typewriterFrame !== null) window.cancelAnimationFrame(typewriterFrame);
    typewriterFrame = null;
  };

  const finish = (): void => {
    if (finished) return;
    finished = true;
    stopPerformance();
    window.removeEventListener('keydown', onKey, true);
    for (const { element, inert } of blocked) {
      if (element.isConnected) element.inert = inert;
    }
    ident.remove();
    options.onComplete?.();
    window.dispatchEvent(
      new CustomEvent('digitaltulpa:introcomplete', { detail: { duration, variant } }),
    );
  };

  /**
   * The player's way out.
   *
   * It goes as a fade rather than a cut, because a cut at 900ms in reads as a
   * crash rather than as a choice.
   */
  const dismiss = (): void => {
    if (finished || ident.classList.contains('is-dismissing')) return;
    stopPerformance();
    // Hand the fade the opacity the ident is actually at. `dt-dismiss` replaces
    // `dt-lifecycle` rather than joining it, so without this the element springs
    // back to fully opaque first - which is invisible for most of its life and
    // very visible during the closing fade, when someone is reaching for the mouse.
    ident.style.setProperty('--dt-dismiss-from', window.getComputedStyle(ident).opacity);
    ident.classList.add('is-dismissing');
    later(finish, DISMISS_FADE_MS);
  };

  /**
   * The keystroke that skips has to be *eaten*.
   *
   * Whatever is prepared underneath the ident is still listening. Without
   * capturing the event and stopping it here, one press of Space both dismissed
   * the ident and started a run in the game behind it, and the title screen the
   * ident exists to introduce was never seen at all.
   */
  function onKey(event: KeyboardEvent): void {
    // Nothing reaches the host while the ident is up - including the chords and
    // bare modifiers that do not skip it. Stopping propagation is not the same as
    // preventing the default, so Cmd+R and Ctrl+Shift+I still belong to the
    // browser; they simply stop being the host's business on the way past.
    event.stopPropagation();
    if (event.key === 'Shift' || event.key === 'Control' || event.key === 'Alt') return;
    if (event.key === 'Meta' || event.metaKey || event.ctrlKey) return;
    event.preventDefault();
    dismiss();
  }

  ident.addEventListener('pointerdown', (event) => {
    event.preventDefault();
    dismiss();
  });
  window.addEventListener('keydown', onKey, true);

  if (reduced) {
    for (const letter of letters) letter.classList.add('is-typed');
  } else {
    // Tells the stylesheet its CSS-only fallbacks are not needed. It is only ever
    // added once the script is certainly about to schedule the real thing.
    ident.classList.add('eyes-scripted');
    eyes.forEach((eye, index) => {
      const at = beats.pings[index === 0 ? 0 : 1];
      later(() => replay(eye, 'is-pinging', 640), at);
    });
    for (const mark of expandGaze(beats)) later(() => lookAt(mark), mark.at);
    for (const step of beats.blinks) later(() => blink(step.slow === true), step.at);
    startTypewriter();
  }

  if (options.hold !== true) later(finish, duration);
  return finish;
}

/** The name the ident shipped under before it became its own module. */
export const playDigitalTulpaIntro = playDigitalTulpaIdent;
