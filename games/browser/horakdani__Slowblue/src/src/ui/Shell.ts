import {
  AUDIO_TRACK_KEYS,
  isBedTrack,
  type AudioTrackKey,
  type AudioTrackSettings,
  type Settings,
} from '../config/settings';
import { bedSpec, type BedKey } from '../audio/Beds';
import type { Profile } from '../meta/Profile';
import type { RecordDelta, RunResult } from '../meta/Profile';
import { stationDepthLabel } from '../config/levels';
import { STRINGS, endingsFor, type StringTable } from '../i18n/strings';
import { CAMPAIGN, ACT_COUNT, TOTAL_STATIONS, type ActInfo } from '../config/campaign';
import {
  ATLAS_LINKS,
  CIRCUIT_ACTS,
  CIRCUIT_ATLAS,
  MAP_H,
  MAP_W,
  ROUTE_LENGTH,
  SEA_Y,
  SPACE_Y,
  actFlownTo,
  actsCleared,
  clearedIn,
  entryOf,
  linkArrow,
  linkFlown,
  routeCurve,
  routePoint,
  worldBandPath,
  worldFacePath,
  worldLayerPath,
  stationCleared,
  stationsCleared,
  type StationRecord,
  type WorldFrame,
} from '../meta/Circuit';
import { FLOOR_Y, HABITAT, HABITAT_SHAPES, placeHabitat } from '../meta/Habitat';
import type { CampaignPosition } from '../meta/Campaign';
import type { FailReason } from '../sim/RunState';

/**
 * There is no `help` here, and that is deliberate.
 *
 * It existed: a screen with four sentences on it about dragging, rings, rocks and
 * the pressure of the medium, reached from a button on the title. Nothing else in
 * this game teaches with words - the first zone is the tutorial, the first `arc`
 * teaches by failing to work, act III's picture is its own explanation, and one
 * idle hint is what replaces the rest. A screen of instructions on the way in was
 * the only thing in the build that disagreed with all of that.
 */
export type ShellScreen = 'title' | 'playing' | 'paused' | 'over' | 'circuit';

export interface ShellHooks {
  onStart: () => void;
  /**
   * Start a fresh circuit at an act the player has already reached.
   *
   * The one call an act-select screen needs; everything it takes to honour it -
   * the act order, the unlock, the carried life - already existed in
   * `CampaignController` and the profile, and nothing drew it.
   */
  onStartAct: (actIndex: number) => void;
  onResume: () => void;
  onPause: () => void;
  /** `sameSeed` replays the water the player just lost on. */
  onRestart: (sameSeed: boolean) => void;
  onQuit: () => void;
  onSettingsChange: (next: Settings) => void;
  onResetProgress: () => void;
  /**
   * The in-game mixer drawer opened or closed.
   *
   * Not `onPause`, and the difference is the whole feature. Pausing parks the
   * audio graph (`AudioEngine.suspend`), which would silence the exact thing the
   * drawer exists to let somebody set. This holds the *water* - the simulation
   * stops stepping - and leaves the bed playing, so the player can take as long
   * as they like over a slider without a hunter arriving while they do.
   */
  onMixer: (open: boolean) => void;
  /** Any press anywhere in the shell: unlocks audio and plays the UI tick. */
  onPress: (bright: boolean) => void;
}

export interface ResultView {
  result: RunResult;
  records: RecordDelta;
  reason: FailReason;
  seed: number;
  /**
   * Which act this was, so the ending speaks that act's language.
   *
   * It used to be a boolean - water or air - and then five more acts arrived
   * behind it, all of them falling through to the sea's wording. See
   * `i18n/strings.ts`.
   */
  act: string;
  /**
   * Set when this run closed the whole circuit. Then the screen is not an act's
   * ending at all: it is the campaign's, and it reports the journey rather than
   * the leg.
   */
  circuit?: { score: number; carried: number; cycles: number };
}

/**
 * Slowblue: the shell is DOM, not canvas.
 *
 * Everything in the *game* is drawn, because the game is one continuous picture of
 * water. Everything around it is a button, because a canvas button is a fake button:
 * no focus ring, no screen reader, no keyboard, no text scaling, and a hit test the
 * player cannot verify. The two live in the same viewport and never overlap - the
 * shell is hidden outright while a run is in progress.
 */
export class Shell {
  private root: HTMLDivElement;
  private panel: HTMLDivElement;
  private pauseBtn: HTMLButtonElement;
  /**
   * The mixer, on the glass.
   *
   * Two pieces of chrome rather than one, and both live outside `.ui` for the same
   * reason the pause button does: `.ui` is `display: none` during a run so it can
   * never eat a gesture, and these have to be reachable while the water is
   * running. The drawer is deliberately **not** the pause screen - `mode` stays
   * `playing`, the HUD stays up, and the bed goes on playing - because the whole
   * point of it is that a slider can be heard while it moves. What it does stop
   * is the simulation (`ShellHooks.onMixer`), so nobody has to choose between
   * levelling the rain and keeping their shoal.
   */
  private mixBtn: HTMLButtonElement;
  private mixPanel: HTMLDivElement;
  /**
   * The title screen's own water.
   *
   * `#stage.quiet-screen` hides the game canvas - not one fish from the world
   * behind the menu belongs on the opening screen - and for a long time what was
   * left was a flat field of blue with three pills in the middle of it. This is
   * what fills it instead: two rings, three shafts of surface light and fourteen
   * motes, none of which is the simulation and none of which costs anything,
   * because the renderer is idle while it is up.
   *
   * It lives outside `.ui-panel` and is built once, because `render` replaces the
   * panel's children wholesale and an animation that restarts every time a screen
   * is drawn is a flicker rather than a drift.
   */
  private veil: HTMLDivElement;
  /**
   * The world the circuit is drawn on: three media, the floor under them, the
   * two horizons between them, and everything that lives in any of it.
   *
   * A screen of its own behind the map rather than a set of shapes inside it,
   * for the reason `layoutWorld` sets out - a world with a frame round it is a
   * diagram of a world. Built once and only ever moved, like the veil: these are
   * six `d` attributes and sixty transforms, and there is no reason to make
   * garbage out of any of them every time an act is picked.
   */
  private world: SVGSVGElement;
  private worldParts: {
    space: SVGPathElement;
    air: SVGPathElement;
    water: SVGPathElement;
    bed: SVGPathElement;
    karman: SVGPathElement;
    sea: SVGPathElement;
  };
  /**
   * ...and one node per inhabitant, in `HABITAT`'s own order.
   *
   * The order is the contract: `placeHabitat` hands back the same list at the
   * same length whatever the frame is - a mark the route has landed on comes back
   * with no ink rather than being left out - so this array is built once from the
   * authored population and afterwards indexed straight into. Nothing here is
   * ever created, removed or re-ordered by a layout.
   */
  private worldLife: SVGPathElement[];
  /** The last frame the world was laid out for. A scroll that moves nothing skips. */
  private worldFrame: string | null = null;
  private mixOpen = false;
  /** Which bed is playing, so the drawer can name the station's own layers. */
  private bedKey: BedKey = 'deep';
  private screen: ShellScreen = 'title';
  private lastResult: ResultView | null = null;
  private confirmingReset = false;
  /**
   * ...and the same for the restart above it. Two flags rather than one shared
   * "something is armed", because the two questions are different questions and a
   * player who armed one and then pressed the other would be answering neither.
   */
  private confirmingRestart = false;
  /**
   * Which act the circuit map is showing, or `null` for "wherever the player is".
   *
   * Set only by pressing a marker on the ring. Nothing else on the screen moves
   * it, and leaving the screen forgets it, so the map always opens on the act the
   * player would actually play next rather than on the last one they poked at.
   */
  private pickedAct: number | null = null;
  /** Whether the selected act's station list is unfolded. */
  private stationsOpen = false;
  /** `data-focus` of the control the next render should hand focus back to. */
  private focusKey: string | null = null;
  /**
   * True while a control that owns its own DOM is pushing a change outward.
   *
   * `patch` sets it around the hook call so that the settings coming straight
   * back through `setSettings` are recognised as our own echo and do not redraw
   * the control that sent them. See both.
   */
  private selfPatching = false;
  /** Set by `hideChrome`, cleared by the next `show`. Governs both corner buttons. */
  private chromeHidden = false;
  /**
   * True while the browser has never let the audio context open. See `silent`.
   *
   * Pushed every frame from `main` (`AudioEngine.unlocked`) and true until the
   * first gesture, because no browser will start a sound on a page nobody has
   * touched. It starts true rather than false so that the corner tells the truth
   * on the frame the title screen is first drawn, which is the frame this whole
   * distinction exists for.
   */
  private soundLocked = true;
  private readonly t: StringTable = STRINGS;

  constructor(
    private readonly host: HTMLElement,
    private settings: Settings,
    private profile: Profile,
    private readonly hooks: ShellHooks,
  ) {
    this.root = document.createElement('div');
    this.root.className = 'ui';

    this.panel = document.createElement('div');
    this.panel.className = 'ui-panel';
    this.panel.setAttribute('role', 'dialog');
    this.panel.setAttribute('aria-modal', 'true');

    this.pauseBtn = document.createElement('button');
    this.pauseBtn.className = 'ui-corner ui-corner-pause';
    this.pauseBtn.type = 'button';
    this.pauseBtn.textContent = '❙❙';
    this.pauseBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.hooks.onPress(false);
      this.hooks.onPause();
    });

    this.mixBtn = document.createElement('button');
    this.mixBtn.className = 'ui-corner ui-corner-mix';
    this.mixBtn.type = 'button';
    this.mixBtn.append(mixerIcon());
    /**
     * One button, two jobs, and the split is the screen it is on.
     *
     * In the water it opens the drawer, because that is where a level can be
     * heard while it is being set. Everywhere else it is a mute, because
     * everywhere else the ten faders are the wrong question: the bed is playing
     * on the title screen, over the map and behind the results (`pushBed` runs
     * before the mode check in `main`), and until this button existed off-run
     * there was no way at all to make that stop without starting a run first.
     *
     * The alternative was a second control somewhere, which is two buttons that
     * both mean sound, in a game that has just finished deleting a screen for
     * exactly that kind of duplication.
     */
    this.mixBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.hooks.onPress(false);
      if (this.screen === 'playing') this.setMixOpen(!this.mixOpen);
      // Off-run the press answers what the corner is currently *showing*: silence
      // is answered with sound and sound with silence.
      //
      // `silent` rather than `settings.muted`, and that is the bug this line was
      // written for. A launch the browser has not let make a sound yet is silent
      // with `muted` still false - so a toggle spent the player's first press
      // muting a game they could not hear, and only the second press, which
      // unmuted it, appeared to do anything. The gesture that press carries is
      // what opens the context (`onPress` above), so the press that means "sound,
      // please" now both asks for it and gets it.
      else this.patch({ muted: !this.silent });
    });

    this.mixPanel = document.createElement('div');
    this.mixPanel.className = 'ui-mix hidden';
    this.mixPanel.setAttribute('role', 'group');

    this.veil = buildVeil();
    this.worldParts = {
      space: svgEl('path', { class: 'ui-world-band space', d: '' }),
      air: svgEl('path', { class: 'ui-world-band air', d: '' }),
      water: svgEl('path', { class: 'ui-world-band water', d: '' }),
      bed: svgEl('path', { class: 'ui-world-band bed', d: '' }),
      karman: svgEl('path', { class: 'ui-world-face karman', d: '' }),
      sea: svgEl('path', { class: 'ui-world-face sea', d: '' }),
    };
    this.worldLife = HABITAT.map((life) =>
      svgEl('path', {
        class: `ui-world-life ${life.kind}`,
        d: HABITAT_SHAPES[life.kind][life.shape] ?? HABITAT_SHAPES[life.kind][0]!,
        opacity: 0,
      }),
    );
    this.world = svgEl('svg', { class: 'ui-world hidden', 'aria-hidden': 'true' });
    /*
     * Deepest first, and the order is the whole of the depth in this picture.
     *
     * The three media, because they are what everything else is in; then the
     * floor of the trench, which is a fourth and deeper one; then everything that
     * *lives* in a medium, over its own bed and under its own ceiling - a cloud
     * beneath the top of the air, a fish beneath the sea. The two horizons go
     * last and nothing is drawn over them, because a horizon with something in
     * front of it is not a horizon.
     */
    this.world.append(
      this.worldParts.space,
      this.worldParts.air,
      this.worldParts.water,
      this.worldParts.bed,
      ...this.worldLife,
      this.worldParts.karman,
      this.worldParts.sea,
    );
    this.root.append(this.veil, this.world, this.panel);
    this.host.append(this.root, this.pauseBtn, this.mixBtn, this.mixPanel);
    // The world is pinned to a box CSS decides the size of, so it is re-laid out
    // whenever that box moves: on a resize, on a rotation, and on a scroll - the
    // map screen scrolls on a short phone, and a horizon that stays behind while
    // the route slides up it is worse than no horizon.
    new ResizeObserver(() => this.layoutWorld()).observe(this.root);
    this.root.addEventListener('scroll', () => this.layoutWorld(), { passive: true });
    this.render();
  }

  get current(): ShellScreen {
    return this.screen;
  }

  setSettings(settings: Settings): void {
    this.settings = settings;
    // Our own echo. The control that started this is mid-gesture and owns its
    // node; redrawing here is what tore the range input out from under a drag.
    //
    // This used to be a screen-name test in `main.ts` - "unless the settings
    // screen is open" - which protected the one mixer that happened to exist when
    // it was written and left the drawer on the glass broken, because during a run
    // the screen is `playing` and the guard let the redraw straight through. The
    // question was never which screen is open; it is whether this shell is being
    // told something it does not already know.
    if (this.selfPatching) return;
    if (this.screen !== 'playing') this.render();
    else this.renderMix();
  }

  /**
   * Which bed the station is in, pushed every frame from `main.pushBed`.
   *
   * Cheap on purpose: it is called sixty times a second and does nothing at all
   * unless the act has actually changed, in which case it relabels an open drawer
   * in place. A drawer that still says "wingbeats" two stations into the
   * stratosphere is worse than no drawer.
   */
  setBed(key: BedKey): void {
    if (key === this.bedKey) return;
    this.bedKey = key;
    if (this.mixOpen) this.renderMix();
  }

  /**
   * Whether the audio context has been opened yet, pushed every frame from `main`
   * beside the bed and just as cheap: it changes once in a session, under the
   * player's first gesture, and there is no other moment the shell would hear
   * about it - no screen is drawn for a browser deciding to allow sound.
   */
  setSoundLocked(locked: boolean): void {
    if (locked === this.soundLocked) return;
    this.soundLocked = locked;
    this.renderMix();
  }

  /**
   * Whether the game is making no sound *now*, for either of the two reasons it
   * can: the player asked for silence, or the browser has not granted it yet.
   *
   * What a press on the corner *does*, and only that - the button goes on drawing
   * `Settings.muted`, because the second reason is not a setting and a control
   * that shows it as one says the game shipped with its sound off. What the two
   * reasons do share is the answer to being pressed: from silence, whichever kind,
   * the press means "let me hear it".
   */
  private get silent(): boolean {
    return this.settings.muted || this.soundLocked;
  }

  setProfile(profile: Profile): void {
    this.profile = profile;
    if (this.screen === 'title' || this.screen === 'over') this.render();
  }

  show(screen: ShellScreen, result?: ResultView): void {
    // The drawer belongs to the run. Anything that opens a screen closes it, so
    // there is never a second mixer floating over the settings mixer - and the
    // hold it was keeping on the water is released with it, or a player who
    // paused with the drawer up would resume into a frozen sim.
    if (screen !== 'playing' && this.mixOpen) this.setMixOpen(false);
    if (result !== undefined) this.lastResult = result;
    // Both armed questions are disarmed by leaving the screen they were asked on.
    // An answer that outlives the question is a button that fires on the next
    // press, and both of these throw a circuit away.
    this.confirmingReset = false;
    this.confirmingRestart = false;
    // Any screen at all puts the corner buttons back. See `hideChrome`.
    this.chromeHidden = false;
    if (screen !== 'circuit') {
      this.pickedAct = null;
      this.stationsOpen = false;
    }
    this.screen = screen;
    this.render();
  }

  /**
   * Takes both corner buttons away without opening a screen.
   *
   * A run that has ended still has the shell on `playing`, because the ending is
   * given its own beat before any dialog arrives - and for those seconds the
   * chrome left on the glass is two buttons that no longer do anything, sitting
   * over a closing film. The next `show` of any screen puts them back.
   *
   * It sets a flag rather than reaching for `.hidden` itself. It used to do the
   * latter, and got away with it only because `render` happened to agree: the
   * mixer button was drawn from `!playing`, and during a film the screen is still
   * `playing`, so any render that landed in between would have put back what this
   * had just taken away. Now that the button is drawn on nearly every screen the
   * two would disagree constantly, and the one that ran last would win.
   */
  hideChrome(): void {
    this.chromeHidden = true;
    if (this.mixOpen) this.setMixOpen(false);
    this.render();
  }

  /** Esc / the hardware back gesture: one step out of wherever we are. */
  escape(): void {
    // The drawer is the innermost thing open, so it is the first thing to close.
    if (this.mixOpen) {
      this.setMixOpen(false);
      return;
    }
    // This used to be a `returnTo` field: whatever screen was showing when the
    // door was opened. The field is gone, and nothing is worse for it, because the
    // map now has exactly one door - it opens from the title and nowhere else.
    // Remembering where you came from is only worth doing when there is more than
    // one place you could have come from.
    if (this.screen === 'circuit') {
      this.show('title');
      return;
    }
    if (this.screen === 'playing') this.hooks.onPause();
    else if (this.screen === 'paused') this.hooks.onResume();
  }

  private render(): void {
    const playing = this.screen === 'playing';
    const title = this.screen === 'title';
    const mapped = this.screen === 'circuit';
    // Which screens the world is not allowed behind.
    //
    // The title always hid it - not one fish from the world behind the menu
    // belongs on the opening screen - and the map, which is a drawing of the
    // whole journey, inherited the opposite by accident and was shown over a live
    // shoal swimming through it. A screen that is about the game rather than in
    // it gets a field of its own.
    //
    // Pause and results are the exception on purpose: those are about the water
    // the player is standing in, and it stays behind them.
    this.host.classList.toggle('quiet-screen', title || mapped);
    this.root.classList.toggle('hidden', playing);
    this.root.classList.toggle('mapped', mapped);
    // The title screen is the one screen with a layout of its own rather than a
    // stack of controls in the middle of the viewport, so it gets a class rather
    // than sharing `.ui-panel`'s defaults.
    this.root.classList.toggle('titled', title);
    // The water stays behind the pause screen on purpose, but not *through* its
    // buttons: a shoal swimming across the middle of RESTART reads as a rendering
    // fault. The class turns the pill backgrounds opaque; the field around them
    // is still live.
    this.root.classList.toggle('halted', this.screen === 'paused');
    this.veil.classList.toggle('hidden', !title);
    this.root.classList.toggle(
      'surfaced',
      this.screen === 'over' && this.lastResult?.result.completed === true,
    );
    this.root.setAttribute('aria-hidden', playing ? 'true' : 'false');
    /*
     * ...and its name, for the one screen that does not write its own.
     *
     * A dialog is not named by what is inside it, so every other screen here gets
     * its name from the `h2` it opens with. The map has no `h2` - `circuitScreen`
     * sets out why - and a modal with no name is announced as "dialog", which is
     * the one thing about this screen a player using a reader cannot see for
     * themselves. The label carries what the heading carried and nothing else;
     * how much of the circuit has been flown is on the picture's own `aria-label`,
     * which is where a count belongs.
     */
    if (this.screen === 'circuit') this.panel.setAttribute('aria-label', this.t.circuit);
    else this.panel.removeAttribute('aria-label');
    this.pauseBtn.classList.toggle('hidden', !playing || this.chromeHidden);
    this.pauseBtn.setAttribute('aria-label', this.t.paused);
    this.renderMix();
    if (playing) {
      this.panel.replaceChildren();
      this.layoutWorld();
      this.applyFocus(false);
      return;
    }

    const nodes: Node[] = [];
    switch (this.screen) {
      case 'title':
        nodes.push(...this.titleScreen());
        break;
      case 'paused':
        nodes.push(...this.pauseScreen());
        break;
      case 'over':
        nodes.push(...this.overScreen());
        break;
      case 'circuit':
        nodes.push(...this.circuitScreen());
        break;
    }
    this.panel.replaceChildren(...nodes);
    this.layoutWorld();
    this.applyFocus(true);
  }

  /**
   * Focus the primary action so a keyboard or switch user is never stranded -
   * unless this render was a control acting on itself, in which case the control
   * is where the player already is. A disclosure that answers being pressed by
   * moving focus to the top of the screen is a disclosure a keyboard user cannot
   * close.
   *
   * `fallback` is false while a run is in progress: there is no screen to be
   * stranded on, and stealing focus onto the pause button every time a slider
   * moves would take the keyboard out of the drawer the player is using.
   */
  private applyFocus(fallback: boolean): void {
    const key = this.focusKey;
    this.focusKey = null;
    if (key !== null) {
      const wanted =
        this.panel.querySelector<HTMLElement>(`[data-focus="${key}"]`) ??
        this.mixPanel.querySelector<HTMLElement>(`[data-focus="${key}"]`);
      if (wanted !== null) {
        wanted.focus({ preventScroll: true });
        return;
      }
    }
    if (!fallback) return;
    // Two queries rather than one selector list: `querySelector('a, b')` returns
    // whichever matches *first in the document*, not the first selector that
    // matches - so the one-liner this replaces handed the keyboard to whatever
    // button happened to be highest on the screen. On the circuit screen that is
    // an act on the map; on the title screen it is the journey card.
    const primary = this.panel.querySelector<HTMLButtonElement>('button.primary');
    (primary ?? this.panel.querySelector<HTMLButtonElement>('button'))?.focus({
      preventScroll: true,
    });
  }

  /**
   * The drawer, redrawn.
   *
   * Called from every render and from `setBed`, and it draws two groups: the
   * layers of the bed the player is standing in, named for what they actually
   * are in this act, and then the four tracks that are the game talking rather
   * than the world - which are the same in all eight acts and are grouped
   * separately for exactly that reason.
   *
   * A bed only lists the slots it fills (`Beds.ts`), so act I shows five rows and
   * act III shows six. An empty slider for a layer this act does not have would be
   * a control that does nothing, which is worse than a shorter list.
   */
  private renderMix(): void {
    const playing = this.screen === 'playing';
    // Everywhere except the films.
    const shown = !this.chromeHidden;
    this.mixBtn.classList.toggle('hidden', !shown);
    this.mixBtn.classList.toggle('solo', !playing);
    this.mixBtn.classList.toggle('on', playing && this.mixOpen);
    // Silence has to be visible from the water: a player who muted two stations
    // ago and forgot should be able to see why nothing is playing without opening
    // anything. The slash is drawn on the icon rather than swapped for a second
    // one, so the button never changes shape under a thumb.
    //
    // The player's own switch and nothing else, which is a correction. It briefly
    // also drew the slash for a context the browser had not opened yet, on the
    // grounds that the game was silent and the corner should say so - and what
    // that produced was a game whose opening screen appears to ship with the
    // sound switched off. It does not: sound is on, and the wait for a gesture is
    // the browser's, measured in one tap and over before the player has read the
    // title. A control may not report a setting the player never made.
    this.mixBtn.classList.toggle('muted', this.settings.muted);
    // Two jobs, two sets of semantics. A drawer is a thing that opens; a mute is
    // a thing that is on or off, and calling it "expanded" tells a screen reader
    // to wait for a panel that is never coming.
    if (playing) {
      this.mixBtn.removeAttribute('role');
      this.mixBtn.removeAttribute('aria-checked');
      this.mixBtn.setAttribute('aria-label', this.t.mixer);
      this.mixBtn.setAttribute('aria-expanded', this.mixOpen ? 'true' : 'false');
    } else {
      this.mixBtn.removeAttribute('aria-expanded');
      this.mixBtn.setAttribute('role', 'switch');
      this.mixBtn.setAttribute('aria-checked', this.settings.muted ? 'false' : 'true');
      this.mixBtn.setAttribute('aria-label', this.t.allSound);
    }
    this.mixPanel.classList.toggle('hidden', !this.mixOpen || !playing);
    if (!this.mixOpen || !playing) {
      this.mixPanel.replaceChildren();
      return;
    }
    const t = this.t;
    const spec = bedSpec(this.bedKey);
    const list = el('div', 'ui-mix-list');

    // The station's name, and the way out of the panel it names. The kicker that
    // used to sit under the title said "this station's layers" over a list that
    // then ran straight into a second, unheaded one - so it moved down and became
    // the first of two group headings, and the header got the close in its place.
    const head = el('div', 'ui-mix-head');
    const close = document.createElement('button');
    close.type = 'button';
    close.className = 'ui-mix-close';
    close.setAttribute('aria-label', t.close);
    close.append(closeMark());
    close.dataset.focus = 'mix-close';
    close.addEventListener('click', () => {
      this.hooks.onPress(false);
      this.setMixOpen(false);
    });
    head.append(el('h2', 'ui-mix-title', spec.name), close);
    // The masthead: what this is, the way out, and the one switch that answers
    // "not now" without touching the mix underneath it. It is a plane of its own
    // rather than the first two rows of the list, and it is outside the
    // scrollport, so the name of the station and the way out of the panel cannot
    // be scrolled off a short screen by a bed that happens to have six layers.
    const top = el('div', 'ui-mix-top');
    top.append(head, this.masterSwitch());

    list.append(el('h3', 'ui-section-title', t.stationLayers));
    for (const layer of spec.layers) {
      list.append(this.audioTrack(layer.track, layer.name, this.settings.audio[layer.track]));
    }

    list.append(el('h3', 'ui-section-title', t.gameSounds));
    for (const track of AUDIO_TRACK_KEYS) {
      if (isBedTrack(track)) continue;
      list.append(this.audioTrack(track, this.trackLabel(track), this.settings.audio[track]));
    }

    this.mixPanel.replaceChildren(top, list);
  }

  private setMixOpen(open: boolean): void {
    // The drawer holds the simulation while it is up (`onMixer`), which is only a
    // coherent thing to do to a running one. Off-run the button is a mute and
    // never asks for this, but the guard is here rather than at the call site so
    // that a future third caller cannot freeze the title screen.
    if (open && this.screen !== 'playing') return;
    this.mixOpen = open;
    this.hooks.onMixer(open);
    this.renderMix();
    // Opening puts the keyboard inside the drawer; closing hands it back to the
    // button that opened it, which is where the player's attention already is.
    //
    // Named rather than "the first button in the panel": the close moved into the
    // header, so first-in-the-document is now the way *out*, and a drawer that
    // opens with the keyboard on its own dismiss is a drawer that shuts on the
    // next press of Enter.
    if (open) {
      const first =
        this.mixPanel.querySelector<HTMLElement>('[data-focus="audio-master"]') ??
        this.mixPanel.querySelector<HTMLElement>('button');
      first?.focus({ preventScroll: true });
    } else this.mixBtn.focus({ preventScroll: true });
  }

  /**
   * What a mixer slot is called right now.
   *
   * The bed in play gets first say - a slot is "Raindrops" in act VI and "Ice
   * crystals" in act III - and the generic role name in `i18n/strings.ts` is the
   * fallback for a slot this act does not fill. Both mixers go through here, so
   * the settings screen and the in-game drawer can never disagree about what a
   * slider does.
   */
  private trackLabel(track: AudioTrackKey): string {
    const named = bedSpec(this.bedKey).layers.find((l) => l.track === track);
    if (named !== undefined) return named.name;
    const t = this.t;
    const fallback: Record<AudioTrackKey, string> = {
      ocean: t.audioOcean,
      motion: t.audioMotion,
      drone: t.audioDrone,
      shimmer: t.audioShimmer,
      ambience: t.audioAmbience,
      whale: t.audioWhale,
      movement: t.audioMovement,
      objectives: t.audioObjectives,
      danger: t.audioDanger,
      interface: t.audioInterface,
    };
    return fallback[track];
  }

  // --- screens ------------------------------------------------------------

  /**
   * Slowblue: the opening screen, in three bands.
   *
   * This used to be one column of eight things, all of them the same size and
   * all of them centred: a wordmark, three sentences, a filled pill, two ghost
   * pills and two lines of small print. Everything the game knows about the
   * player was in the small print, and the one button that mattered looked like
   * the two that did not.
   *
   * It is now a screen with a shape, and the shape answers three questions in
   * the order they actually get asked:
   *
   *   - **What is this?** The mark, the wordmark and the promise, floating in
   *     the upper half with nothing else near them. This is the only band a
   *     first-time player has to read.
   *   - **What happens if I press the big one?** The primary carries its own
   *     answer on a second line - the act, its name and the station it opens on
   *     - because BEGIN and CONTINUE are different games and a player two hours
   *     into a seven-act circuit should never have to guess which one they are
   *     about to get.
   *   - **Where am I?** The journey card: the circuit drawn as the same ring the
   *     map draws it as, the tally beside it, and the whole thing is the door to
   *     the map. It appears as soon as there is any journey to look at and not
   *     one moment before - the shape of a game nobody has played yet is a
   *     spoiler rather than an orientation.
   *
   * Everything below that is quieter than all three: how to play, settings, and
   * one line of record. The screen is still one column, because a phone held in
   * one hand is one column - but it is a column with a top, a middle and a
   * bottom instead of eight equal rows.
   */
  private titleScreen(): Node[] {
    const t = this.t;
    const saved = this.profile.saved;
    const out: Node[] = [];

    const hero = el('div', 'ui-hero');
    const rule = el('div', 'ui-rule');
    rule.setAttribute('aria-hidden', 'true');
    // One line under the wordmark, not two. The pitch that used to sit here -
    // "you do not control the fish, you control the ocean" - is a thing the
    // water says for itself within ten seconds of the first drag, and saying it
    // in advance put a sentence between the player and the button. It is still
    // the page's `<meta description>`, which is where a pitch belongs.
    hero.append(titleMark(), el('h1', 'ui-title', t.title), rule, el('p', 'ui-mission', t.mission));
    out.push(hero);

    const actions = el('div', 'ui-title-actions');
    // A mode that changes what the game *is* is announced next to the button
    // that starts it, not left buried in settings. This one does.
    if (this.settings.circuit && this.profile.cycles > 0) {
      actions.append(modeNote(t.circuitModeHint));
    }

    // Where BEGIN would drop them: the saved circuit if there is one, act I if
    // there is not. `onStart` resolves exactly the same thing in `main.ts`, so
    // this line is a description of what is about to happen rather than a guess.
    const act = CAMPAIGN[Math.min(ACT_COUNT - 1, saved?.position.act ?? 0)]!;
    const station = saved?.position.level ?? 0;
    actions.append(
      this.cta(
        saved === null ? t.play : t.continueRun,
        `${t.actLabel} ${ROMAN[act.number - 1]} · ${act.name} · ` +
          `${t.levelLabel} ${Math.min(act.act.levels.length, station + 1)}/${act.act.levels.length}`,
        () => this.hooks.onStart(),
      ),
    );

    // The map, from the first launch.
    //
    // It used to wait for a journey to exist - the argument being that the shape
    // of a game nobody has played yet is a spoiler rather than an orientation.
    // It is not much of a spoiler: the ring draws seven bands whether or not you
    // have been to them, an act nobody has reached is drawn as an absence and its
    // stations are left unnamed, and the line directly above this card already
    // promises seven acts and one circuit in words. Hiding the one screen that
    // shows what that sentence means did not protect anybody from anything; it
    // just meant the game's own shape was the last thing it showed you.
    //
    // On a fresh profile the card is honest about it: an unlit ring and 0/42.
    //
    // It is also the only door under the primary now. There was a SETTINGS button
    // below it, and the screen behind that button no longer exists: the sound is
    // mixed on the glass, and the one mode left is on the map this card opens.
    // What is left is a title screen that offers to start the game and to show
    // you the game, which between them is everything it was ever for.
    actions.append(this.journeyCard(stationsCleared(this.profile.stations), saved?.cargo ?? null));
    out.push(actions);

    // The record. One line, in the corner the eye reaches last.
    const foot = el('div', 'ui-title-foot');
    const stats = el('div', 'ui-stat-row');
    const parts: HTMLElement[] = [];
    if (this.profile.bestScore > 0) {
      parts.push(el('span', 'ui-best', `${t.best} ${this.profile.bestScore}`));
    }
    // Label first, value second: "Runs 23" reads as a stat, where "23 Runs" reads
    // as a count of something that happened.
    if (this.profile.runs > 0) parts.push(el('span', '', `${t.runs} ${this.profile.runs}`));
    if (this.profile.cycles > 0) {
      parts.push(el('span', '', `${this.profile.cycles} ${t.cycleLabel}`));
    }
    parts.forEach((part, i) => {
      if (i > 0) {
        const dot = el('span', 'ui-stat-dot', '·');
        dot.setAttribute('aria-hidden', 'true');
        stats.append(dot);
      }
      stats.append(part);
    });
    if (parts.length > 0) foot.append(stats);
    out.push(foot);
    return out;
  }

  /**
   * The one button on the screen that starts something, and the only one with a
   * second line.
   *
   * The label is the verb and the sub-line is the destination, which is the
   * shortest arrangement that lets CONTINUE mean something. A screen reader gets
   * both in one string rather than two, because "CONTINUE, Act IV, Orbit,
   * Station 3 of 6" is one thought.
   */
  private cta(label: string, sub: string, onClick: () => void): HTMLButtonElement {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'ui-btn primary ui-cta';
    b.append(el('span', 'ui-cta-label', label), el('span', 'ui-cta-sub', sub));
    b.setAttribute('aria-label', `${label} — ${sub}`);
    b.addEventListener('click', () => {
      this.hooks.onPress(true);
      onClick();
    });
    return b;
  }

  /**
   * The journey card: the circuit at a glance, and the door to the map.
   *
   * The tally used to ride on a ghost pill - `THE CIRCUIT · 24/42` - which is
   * the whole of what the title screen knows about a seven-act journey rendered
   * as a line of text on a button. Here it is the same route the map draws, as a
   * gauge down the right-hand edge, with the flown part lit and the saved
   * circuit's position on it, so "how far round am I" is answered before
   * anything is read.
   *
   * It is a button and not a panel with a button in it: the entire card opens
   * the map, which is the only thing anybody would want from it.
   */
  private journeyCard(walked: number, cargo: number | null): HTMLButtonElement {
    const t = this.t;
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'ui-journey';
    b.setAttribute('aria-label', `${t.circuit} · ${walked}/${TOTAL_STATIONS} ${t.levelsCleared}`);

    const text = el('span', 'ui-journey-text');
    const count = el('span', 'ui-journey-count');
    count.append(
      el('b', '', `${walked}/${TOTAL_STATIONS}`),
      el('span', 'ui-journey-unit', ` ${t.levelsCleared}`),
    );
    const sub =
      `${actsCleared(this.profile.stations)}/${ACT_COUNT} ${t.actsLabel}` +
      (cargo === null ? ` · ${t.openMap}` : ` · ${cargo} ${t.carried}`);
    text.append(
      el('span', 'ui-journey-eyebrow', t.circuit),
      count,
      el('span', 'ui-journey-sub', sub),
    );

    const go = el('span', 'ui-journey-go', '›');
    go.setAttribute('aria-hidden', 'true');
    // Writing first, picture second. The gauge used to lead, which is the usual
    // arrangement for a card with a thumbnail on it - and it cost the one thing
    // this band has going for it: with a rail down the left, the card's first
    // word started thirty-seven pixels right of the button's first word, and two
    // controls the same width with their type on two different margins read as a
    // mistake rather than as a stack. Everything that is read now starts on one
    // line, and both controls answer on the right - an arrow on the button, the
    // journey and its chevron on the card.
    b.append(text, this.journeyDial(), go);
    b.addEventListener('click', () => {
      this.hooks.onPress(false);
      this.show('circuit');
    });
    return b;
  }

  /**
   * The journey, at a sixteenth of the map's attention.
   *
   * The same route the map draws, at the one size where nothing else survives:
   * the loop, and how much of it is behind you. Forty-two stops at this size are
   * forty-two half-pixels, which is texture rather than information. What is
   * left is the shape, which is the one thing the card is for - it is the map's
   * own silhouette, so pressing it opens something already seen.
   *
   * Two things it used to get wrong, and both of them made it look like a slip
   * rather than a drawing:
   *
   *   - **It was fitted to the map's box, not to the route.** The box is a wide
   *     frame around a narrow loop, because the map spends sixty-four units of
   *     width on the act names set beside the line. Scaling that frame into a
   *     square left the loop at thirteen pixels by forty-one, adrift in the
   *     middle of a sixty-four pixel column of nothing. It is fitted to the
   *     route's own extent now - sampled off `routePoint`, so this and the map
   *     cannot disagree about where the line goes - and the element is the shape
   *     of what it draws: a tall, narrow gauge rather than a square with a
   *     splinter in it.
   *   - **It was one unbroken ring.** Seven acts drawn as a single rounded
   *     rectangle is a rounded rectangle. The map does not do that: an act is a
   *     run of stops and a link is the stretch between two of them, and a link
   *     is dark until the act behind it is finished. Drawn the same way here,
   *     `ACT_GAP` does at this size exactly what it does at full size - the line
   *     falls into seven groups before anything is read - and an unflown circuit
   *     is legibly seven of something instead of a blank pill.
   */
  private journeyDial(): SVGSVGElement {
    const PAD = 3;
    const H = 62;
    const stations = this.profile.stations;
    // The route's own extent, read off the line itself rather than off the two
    // constants that happen to bound it: the map's box is `MAP_W` by `MAP_H` and
    // the loop inside it is neither.
    const ring = routeCurve(0, ROUTE_LENGTH);
    let x0 = Infinity;
    let x1 = -Infinity;
    let y0 = Infinity;
    let y1 = -Infinity;
    for (const p of ring) {
      x0 = Math.min(x0, p.x);
      x1 = Math.max(x1, p.x);
      y0 = Math.min(y0, p.y);
      y1 = Math.max(y1, p.y);
    }
    const k = (H - 2 * PAD) / (y1 - y0);
    const W = (x1 - x0) * k + 2 * PAD;
    const place = (p: { x: number; y: number }): { x: number; y: number } => ({
      x: PAD + (p.x - x0) * k,
      y: PAD + (p.y - y0) * k,
    });
    const svg = svgEl('svg', {
      class: 'ui-dial',
      viewBox: `0 0 ${W.toFixed(2)} ${H}`,
    });
    svg.setAttribute('aria-hidden', 'true');
    const run = (from: number, to: number): string => polyPath(routeCurve(from, to).map(place));

    // Bottom to top: the links, then the acts standing on them, then whatever
    // has been flown lit over both. The order is the map's order and so is the
    // weighting - a link is the quietest thing on either picture until it is
    // earned, because until then it is a stretch of journey nobody has made.
    for (const link of ATLAS_LINKS) {
      svg.append(svgEl('path', { class: 'ui-dial-link', d: run(link.fromT, link.toT) }));
    }
    for (const band of CIRCUIT_ACTS) {
      svg.append(svgEl('path', { class: 'ui-dial-route', d: run(band.from, band.to) }));
    }
    for (const band of CIRCUIT_ACTS) {
      const flown = actFlownTo(stations, band.act);
      if (flown === null) continue;
      svg.append(svgEl('path', { class: 'ui-dial-flown', d: run(band.from, flown) }));
    }
    for (const link of ATLAS_LINKS) {
      if (!linkFlown(stations, link)) continue;
      svg.append(svgEl('path', { class: 'ui-dial-flown', d: run(link.fromT, link.toT) }));
    }
    const here = this.profile.saved?.position ?? null;
    if (here !== null) {
      const p = CIRCUIT_ATLAS.find((s) => s.act === here.act && s.station === here.level);
      if (p !== undefined) {
        const q = place(routePoint(p.t));
        const halo = svgEl('circle', {
          class: 'ui-dial-here-halo beat',
          cx: q.x.toFixed(2),
          cy: q.y.toFixed(2),
          r: 5,
        });
        svg.append(
          halo,
          svgEl('circle', {
            class: 'ui-dial-here',
            cx: q.x.toFixed(2),
            cy: q.y.toFixed(2),
            r: 2.4,
          }),
        );
      }
    }
    return svg;
  }

  /**
   * Three ways out of a held run, stacked, and one line about what they cost.
   *
   * RESTART used to share a row with COMFORT, and with that door gone a row of
   * one is just a full-width button with a wrapper around it. It is written as
   * one, so pause is a column of three - go on, go again, go back - at the same
   * width all the way down.
   *
   * The line under them is the only rules text in the build, and it is here
   * rather than on a screen of its own because this is the only screen where its
   * answer is being asked for: both of the buttons below RESUME read as "throw
   * away what I have done" until somebody says what they actually take, which is
   * a station. See `saveNote` in `i18n/strings.ts`.
   */
  private pauseScreen(): Node[] {
    const t = this.t;
    return [
      el('h2', 'ui-heading', t.paused),
      this.button(t.resume, 'primary', () => this.hooks.onResume()),
      this.button(t.restart, 'ghost wide', () => this.hooks.onRestart(true)),
      this.button(t.quit, 'ghost wide', () => this.hooks.onQuit()),
      el('p', 'ui-save-note', t.saveNote),
    ];
  }

  private overScreen(): Node[] {
    const t = this.t;
    const view = this.lastResult;
    if (view === null) return this.titleScreen();
    const { result, records, reason } = view;
    // Every act ends in its own words. The two endings that used to be shared -
    // the sea's and the air's, chosen by a boolean - are now seven, because five
    // more acts arrived behind them and every one of them was announcing that the
    // player had broken through the waterline. See `i18n/strings.ts`.
    const ending = endingsFor(view.act);
    const circuit = view.circuit;
    // ...and the circuit closing is not an act ending at all. It is the only
    // screen in the game that speaks about the whole journey.
    const heading =
      circuit !== undefined
        ? t.circuitComplete
        : result.completed
          ? ending.complete
          : reason === 'depleted'
            ? t.failDepleted
            : reason === 'ringMissed'
              ? t.failRing
              : ending.swept;
    const hint =
      circuit !== undefined
        ? t.circuitHint
        : result.completed
          ? ending.completeHint
          : reason === 'depleted'
            ? t.failDepletedHint
            : reason === 'ringMissed'
              ? t.failRingHint
              : ending.sweptHint;
    const out: Node[] = [];
    if (result.completed) out.push(el('p', 'ui-complete-kicker', t.missionComplete));
    out.push(el('h2', 'ui-heading', heading), el('p', 'ui-fine', hint));
    if (records.score) out.push(el('p', 'ui-record', t.newRecord));
    // A closed circuit reports the journey's score, not the last leg's.
    const score = el('p', 'ui-score', String(circuit?.score ?? result.score));
    score.setAttribute('aria-live', 'polite');
    out.push(score);
    if (circuit !== undefined) {
      out.push(
        el(
          'p',
          'ui-stats',
          `${t.campaignScore} · ${circuit.carried} ${t.carried} · ${circuit.cycles} ${t.cycleLabel}`,
        ),
      );
    }
    out.push(
      el(
        'p',
        'ui-stats',
        `${result.levelsCleared} ${t.levelsCleared} · ${result.ringsHeld} ${t.ringsHeld} · ${result.rescued} ${t.rescued} · ↑ ${Math.round(result.depth / 10)}m ${t.ascent}`,
      ),
    );
    if (!records.score && this.profile.bestScore > 0) {
      out.push(el('p', 'ui-fine', `${t.best} ${this.profile.bestScore}`));
    }
    out.push(
      this.row([
        this.button(t.playAgain, 'primary', () => this.hooks.onRestart(true)),
        this.button(t.newWater, 'primary', () => this.hooks.onRestart(false)),
      ]),
      // One button, full width. It was half of a row with SETTINGS beside it, and
      // a results screen is the last place anyone wants a preferences list: the
      // two things to do here are go again or go back.
      this.button(t.quit, 'ghost wide', () => this.hooks.onQuit()),
      el('p', 'ui-fine', `${t.seedLabel} ${view.seed}`),
    );
    return out;
  }

  /**
   * Slowblue: the whole journey, on one screen.
   *
   * This began as an act list - seven names in a column - and a column is the one
   * arrangement that makes a round trip look like a ladder. Then it was a column
   * with an altitude profile drawn over it, which is a ladder with a diagram of a
   * mountain on top. Then it was a dial: forty-two marks spaced evenly around one
   * closed ring, which was true about the order of the journey and silent about
   * everything else in it.
   *
   * Now it is the place. The world is drawn as what it is - eight named regions
   * from the floor of a trench to low orbit, stacked, each one falling away
   * towards the edges of the frame the way a surface does when you are high
   * enough above it to see that it is a surface - and the campaign is drawn
   * through it as one closed loop: out and up the left of it, home down the
   * right, meeting at the top where it turns over and at the bottom because act I
   * station 1 and act VII station 6 are the same trench floor.
   *
   * A station is where its own altitude puts it, which is the whole difference.
   * Twelve of the forty-two are in the sea and six are above a hundred
   * kilometres, and the picture says so before anything is read.
   *
   * The selected act is the one the screen is *about*, and it is chosen **on the
   * picture**: each act owns its stretch of the line and the name beside it, and
   * the two together are the target. There used to be a strip of seven numerals
   * under the map doing that job, which was a second copy of the map with the map
   * taken out of it - seven identical squares that say nothing about where the
   * acts are, sitting directly under a drawing whose whole subject is where the
   * acts are. What made the strip safe to delete is `ACT_GAP`: the stops now fall
   * into seven visible groups, so an act is a place on the picture a thumb can
   * aim at rather than six beads in a chain of forty-two.
   *
   * Under it, the act says what it is, and pressing it opens its stations. Not a
   * card - it was one, framed and tinted, which is a box drawn round the only
   * prose on the screen for no reason other than that it was prose. It is the
   * writing itself now, and the chevron on it is the whole disclosure: the
   * separate STATIONS button that used to sit two controls further down was a
   * second control for the one thing this text is already about.
   *
   * Three rules, all kept from the versions this replaces:
   *
   *   - **It is still not a level select.** Playing enters the circuit at the
   *     selected act, from its first station, exactly as before. The station list
   *     is a record and a map; nothing in it is a button.
   *   - **An act is open once the player has arrived at it**, never as a reward
   *     for a score. The map draws the whole loop whether or not it has been
   *     flown, because the title screen already promised the circuit in words -
   *     but it leaves what is ahead unlit, and its stations unnamed, because the
   *     promise is not the same thing as the visit.
   *   - **Selecting is not starting.** Pressing an act on the map moves the
   *     writing under it and nothing else; the button below plays it. That rule
   *     is why the seven can be on the picture at all - a target that started a
   *     run on first touch would be a target that ends someone's circuit by
   *     accident.
   */
  private circuitScreen(): Node[] {
    const t = this.t;
    const stations = this.profile.stations;
    const here = this.profile.saved?.position ?? null;
    const picked = this.selectedAct();

    /*
     * No heading, and this is the one screen that is right without one.
     *
     * Every other screen here opens with its own name because every other screen
     * is a column of controls that would otherwise start mid-sentence. This one
     * opens with a picture of a closed loop, seven names set beside it and the
     * word TRENCH FLOOR along the bottom, and a line of type over the top of that
     * saying THE CIRCUIT is a caption on a thing that is already captioned - fifteen
     * pixels of letterspaced type, and the ten of gap under it, spent telling the
     * reader what they are looking straight at.
     *
     * The height goes to the map, which is the only thing in this column that
     * gives: `.ui-map` is `flex: 1 1 0` between a floor and its own aspect ratio,
     * so on a tall phone the picture is already as wide as the screen and takes
     * the twenty-five pixels as air, and on a short one - where the map has been
     * squeezed to its floor and the screen scrolls - it takes them as picture.
     * The short screen is the one that needed them.
     *
     * What the type was also doing is naming the dialog, and that does not go
     * away just because nobody needs to see it: `render` labels the panel for
     * this screen instead, so a screen reader still opens "The circuit" and only
     * the pixels are gone.
     */
    const out: Node[] = [this.atlasMap(stations, here, picked)];
    /*
     * The whole circuit in two numbers, and they are the caption of the picture
     * rather than a second footer under the act.
     *
     * They used to sit *below* the card, twelve pixels under YOU ARE HERE and in
     * almost the same ink, which put two summaries of two different sizes - one
     * act, forty-two stations - hard against each other and made the reader work
     * out which was which. Worse, opening the stations pushed this line six rows
     * away from the map it is counting. Above the card it belongs to the drawing
     * it describes, and the card below it is then one block about one act with
     * nothing trailing it.
     */
    out.push(
      el(
        'p',
        'ui-fine ui-map-total',
        `${stationsCleared(stations)}/${TOTAL_STATIONS} ${t.levelsCleared} · ` +
          `${actsCleared(stations)}/${ACT_COUNT} ${t.actsLabel}`,
      ),
    );
    out.push(this.actCard(stations, here, picked));
    /**
     * The mode, above the button that starts water.
     *
     * It lived in a list of switches called SETTINGS, which is the wrong place
     * for it twice over. It changes what the game *is* rather than how it looks
     * - continuous circuit takes out the one screen that ever interrupts the
     * loop - and a change of that size belongs beside the control that commits
     * to it, not three taps away under a heading about preferences.
     *
     * The list is built inside the unlock rather than around it. It used to be
     * unconditional because it always had a row in it; now that the only mode
     * left is one §11 hands out, an unconditional `ui-list` would be an empty
     * box holding its own gap open above PLAY for every player who has not yet
     * closed a circuit.
     *
     * Above PLAY and below the map, so the order down the screen is the order of
     * the sentence: here is the journey, here is how it will be played, go.
     */
    // Only once there is a circuit to have closed. §11 unlocks this after a full
    // campaign, and offering it before then is offering to remove a screen the
    // player has never reached.
    if (this.profile.cycles > 0) {
      const modes = el('div', 'ui-list');
      modes.append(
        this.toggle(t.circuitMode, this.settings.circuit, (v) => this.patch({ circuit: v }), 'loop'),
      );
      out.push(modes);
    }
    out.push(this.playButton(stations, here, picked));
    // The same reading `playButton` makes, so the restart below can never offer to
    // put down a journey the button above is still calling BEGIN.
    const started = journeyUnderWay(stations, here);
    if (this.profile.cycles > 0) {
      out.push(
        el(
          'p',
          'ui-fine',
          `${this.profile.cycles} ${t.cycleLabel} · ${t.best} ${this.profile.bestCampaign} · ${this.profile.bestCargo} ${t.carried}`,
        ),
      );
    }
    /**
     * Putting the circuit down and setting off again, which is not the same thing
     * as the wipe below it and must not look like it.
     *
     * The map could already do this and could not say so: picking an act the save
     * is not sitting in gives BEGIN, and BEGIN opens a *fresh* circuit there. So
     * "start the whole thing again" was reachable by choosing act I - unless the
     * circuit was already in act I, where that button says CONTINUE and there was
     * no way back to the top at all. A door that exists only when you are far
     * enough from it is not a door.
     *
     * It keeps everything that is a *record* - the forty-two stations, the acts
     * unlocked, best score, best circuit, the cycles counted - and throws away only
     * the circuit in progress. That is the whole difference from the button under
     * it, and it is why this one is not `danger`: nothing a player earned is at
     * stake, only where they are standing.
     *
     * It still asks once. A circuit can be two hours old, the map above is drawing
     * exactly how much of one there is, and this is a screen people arrive at to
     * look at that picture rather than to press things.
     */
    if (started) {
      out.push(
        this.button(
          this.confirmingRestart ? t.restartJourneyConfirm : t.restartJourney,
          // Named as well as styled: its label changes when it is armed, so it is
          // the one control on this screen that cannot be found by what it says.
          'ghost wide ui-restart',
          () => {
            if (!this.confirmingRestart) {
              this.confirmingRestart = true;
              // Only one question may be open at a time, or the screen ends up
              // asking two and answering whichever is pressed next.
              this.confirmingReset = false;
              this.render();
              return;
            }
            this.confirmingRestart = false;
            // The same call the map's own BEGIN makes for act I, so a restarted
            // journey and a first one are the identical thing and cannot drift.
            this.hooks.onStartAct(0);
          },
        ),
      );
    }
    /**
     * The wipe, at the bottom of the only screen that draws what it destroys.
     *
     * It used to be a red button under a column of volume sliders, asking "ARE
     * YOU SURE?" about a word - progress - with nothing on the screen to say what
     * that word was worth. Here the answer is directly above it: forty-two
     * stations, seven acts, however many of them are lit. Nothing had to be added
     * to make the confirm mean something; it just had to be asked in front of the
     * picture.
     *
     * Hidden on a profile with nothing in it, because an erase button is a threat
     * to somebody who has not yet made anything to lose.
     */
    if (this.profile.runs > 0 || this.profile.cycles > 0) {
      out.push(
        this.button(this.confirmingReset ? t.eraseConfirm : t.eraseStations, 'danger wide', () => {
          if (!this.confirmingReset) {
            this.confirmingReset = true;
            this.confirmingRestart = false;
            this.render();
            return;
          }
          this.confirmingReset = false;
          this.hooks.onResetProgress();
        }),
      );
    }
    out.push(this.button(t.back, 'ghost wide', () => this.show('title')));
    return out;
  }

  /**
   * The one button on this screen that starts water, and what it is honest to
   * call itself.
   *
   * BEGIN and CONTINUE are different promises, and the map is the one screen
   * where which of them applies depends on what the player just pressed. It says
   * CONTINUE for exactly one act - the one the saved circuit is sitting in, once
   * that circuit has actually got somewhere - and pressing it resumes that
   * circuit where it was put down, station included, which is the same thing the
   * title screen's own primary does.
   *
   * Every other act is BEGIN, and means it: `onStartAct` opens a *fresh* circuit
   * at that act, from its first station. Labelling that CONTINUE because the
   * player has progress somewhere else would be the button telling them their
   * journey is safe at the moment it replaces it.
   */
  private playButton(
    stations: StationRecord,
    here: CampaignPosition | null,
    picked: number,
  ): HTMLButtonElement {
    const t = this.t;
    // "Under way" rather than "has a save": a circuit that was saved at act I
    // station 1 and never played is a game about to begin, whatever is on disk.
    const started = journeyUnderWay(stations, here);
    const resuming = started && here !== null && here.act === picked;
    return this.button(resuming ? t.continueRun : t.play, 'primary wide', () => {
      if (resuming) this.hooks.onStart();
      else this.hooks.onStartAct(picked);
    });
  }

  /**
   * Which act the middle of the ring is showing.
   *
   * The player's pick, if they made one and it is still an act they may have;
   * otherwise where the saved circuit is sitting; otherwise the furthest act they
   * have reached - which is act I for a first-time player, and for everyone else
   * is the act they would have pressed anyway.
   */
  private selectedAct(): number {
    const top = Math.max(0, Math.min(this.profile.unlockedAct, ACT_COUNT - 1));
    const picked = this.pickedAct;
    if (picked !== null && picked >= 0 && picked <= top) return picked;
    const here = this.profile.saved?.position.act ?? -1;
    if (here >= 0 && here <= top) return here;
    return top;
  }

  /**
   * The six stations of one act: what they are called, how far from the sea they
   * are, and the one line each of them has about what changed on the way.
   *
   * This is the finest structure the game has, and it is presented rather than
   * offered - the campaign checkpoints at act boundaries and nowhere finer, for
   * reasons `meta/Campaign.ts` sets out, so a station is a place you have been,
   * not a place you can be dropped into.
   *
   * It is drawn as what it is: the six stops of one act, on the same line the map
   * above draws them on, in the same three states. That is not decoration - it is
   * the thing this list was missing. It used to be six numbered rows beside a bare
   * vertical hairline that began and ended in mid-air, belonging to nothing above
   * it and saying nothing about where the player is standing except by tinting a
   * name. Now the rule runs stop to stop, each row owns a stop, and the numerals
   * are gone: a stop's place on a line *is* its number, which is exactly how the
   * picture overhead says it, and the `<ol>` still carries the ordinal for anyone
   * listening rather than looking.
   */
  private stationList(info: ActInfo, done: number, here: number): HTMLElement {
    const list = el('ol', 'ui-stations');
    info.act.levels.forEach((level, i) => {
      const item = el('li', i < done ? 'done' : '');
      if (i === here) item.classList.add('here');
      const stop = el('span', 'ui-station-stop');
      stop.setAttribute('aria-hidden', 'true');
      item.append(
        stop,
        el('span', 'ui-station-name', level.name),
        el('span', 'ui-station-depth', stationDepthLabel(info.act.levels, i)),
        el('span', 'ui-station-note', level.subtitle),
      );
      list.append(item);
    });
    return list;
  }

  /**
   * The map: one line, forty-two stops, seven acts you can put a thumb on.
   *
   * One SVG, and seven real buttons over it. The picture is SVG for the same
   * reason every other thing in the shell is a real element - it scales with the
   * page, it takes its colours from CSS, and it can carry a label a screen
   * reader will read - and the seven targets are HTML rather than SVG for
   * exactly the same reason: a `<g>` with a `tabindex` on it is a fake button,
   * and this game does not draw those. They are laid over the picture by
   * percentage, which is exact because the frame's aspect ratio is the atlas box.
   *
   * `meta/Circuit.ts` sets out the route and why it is shaped the way it is.
   * What is drawn out of it is a transit line and its grammar, in the order the
   * grammar wants:
   *
   *   1. **The whole route**: seven stretches at one weight in the quiet colour,
   *      and the seven handovers between them at half of it. That is the one
   *      place this picture spends a second line weight, and it is spent on the
   *      thing the old drawing could not say - where an act ends. An act nobody
   *      has reached is still drawn, because the journey is seven acts either
   *      way; it is drawn as an absence.
   *   2. **The part that has been flown**, in the one bright colour the picture
   *      has. Seven stretches and seven links, and the last link is the bottom
   *      of the map: it lights when the circuit closes, and not before.
   *   3. **Which way round it goes**: an arrowhead on each of the seven links,
   *      pointing the way the route travels. On the links because a link is the
   *      one stretch of line with no stop on it, and in the link's own ink -
   *      quiet ahead of you, lit behind - so that it reads as the head of that
   *      seam rather than as an eighth thing laid over the picture.
   *   4. **The stops** - forty-two, filled for the ones behind you - and a ring
   *      round each of the seven the line arrives at, which is where an act is
   *      entered and where its link lands.
   *   5. **The names**, set beside the line and never on it: what the act is,
   *      then its numeral and how far it reaches.
   *
   * Nothing is drawn twice and nothing is drawn that is not one of those five
   * things. The pictures this replaces were hard to read because everything in
   * them was as loud as everything else.
   */
  private atlasMap(
    stations: StationRecord,
    here: CampaignPosition | null,
    picked: number,
  ): HTMLElement {
    const t = this.t;
    const wrap = el('div', 'ui-map');
    const svg = svgEl('svg', {
      viewBox: `0 0 ${MAP_W} ${MAP_H}`,
      class: 'ui-map-world',
      role: 'img',
    });
    svg.setAttribute(
      'aria-label',
      `${t.circuit}: ${stationsCleared(stations)}/${TOTAL_STATIONS} ${t.levelsCleared}`,
    );
    const run = (from: number, to: number): string => polyPath(routeCurve(from, to));

    // The world the route stands on - the water and the dark - is not drawn
    // here. It is behind the whole screen, in `layoutWorld`, because a sea that
    // stops where the picture stops is a sea with a frame around it.

    // 1. The route, act by act, and the handovers between them.
    for (const band of CIRCUIT_ACTS) {
      svg.append(
        svgEl('path', {
          class: `ui-route${band.act === picked ? ' sel' : ''}`,
          d: run(band.from, band.to),
        }),
      );
    }
    for (const link of ATLAS_LINKS) {
      svg.append(svgEl('path', { class: 'ui-route join', d: run(link.fromT, link.toT) }));
    }

    // 2. ...and the part of it that has been flown.
    for (const band of CIRCUIT_ACTS) {
      const flown = actFlownTo(stations, band.act);
      if (flown === null) continue;
      svg.append(svgEl('path', { class: 'ui-map-flown', d: run(band.from, flown) }));
    }
    for (const link of ATLAS_LINKS) {
      if (!linkFlown(stations, link)) continue;
      svg.append(
        svgEl('path', {
          class: `ui-map-flown link${link.closes ? ' close' : ''}`,
          d: run(link.fromT, link.toT),
        }),
      );
    }

    // 3. ...and which way it is going. One arrowhead per seam, turned to the
    //    line it sits on - a chevron rather than a filled head, because every
    //    other mark in this picture is a stroke and a solid triangle would be
    //    the only object here with a fill of its own.
    for (const link of ATLAS_LINKS) {
      const a = linkArrow(link);
      svg.append(
        svgEl('path', {
          class: `ui-route-arrow${linkFlown(stations, link) ? ' on' : ''}`,
          d: ARROW_HEAD,
          transform: `translate(${a.x.toFixed(2)} ${a.y.toFixed(2)}) rotate(${a.angle.toFixed(1)})`,
        }),
      );
    }

    // 4. The seven ways in, and the forty-two stops.
    for (const band of CIRCUIT_ACTS) {
      const entry = entryOf(band.act);
      if (entry === undefined) continue;
      const q = routePoint(entry.t);
      svg.append(
        svgEl('circle', {
          class: `ui-map-entry${band.act === picked ? ' sel' : ''}`,
          cx: q.x.toFixed(2),
          cy: q.y.toFixed(2),
          r: 8,
        }),
      );
    }
    for (const p of CIRCUIT_ATLAS) {
      const q = routePoint(p.t);
      svg.append(
        svgEl('circle', {
          class:
            `ui-map-station${stationCleared(stations, p) ? ' on' : ''}` +
            `${p.act === picked ? ' sel' : ''}`,
          cx: q.x.toFixed(2),
          cy: q.y.toFixed(2),
          r: p.act === picked ? 4.8 : 4.2,
        }),
      );
    }
    if (here !== null) {
      const p = CIRCUIT_ATLAS.find((s) => s.act === here.act && s.station === here.level);
      if (p !== undefined) {
        const q = routePoint(p.t);
        const halo = svgEl('circle', {
          class: 'ui-map-here-halo beat',
          cx: q.x.toFixed(2),
          cy: q.y.toFixed(2),
          r: 13,
        });
        svg.append(
          halo,
          svgEl('circle', {
            class: 'ui-map-here',
            cx: q.x.toFixed(2),
            cy: q.y.toFixed(2),
            r: 7.5,
          }),
          svgEl('circle', {
            class: 'ui-map-here-core',
            cx: q.x.toFixed(2),
            cy: q.y.toFixed(2),
            r: 3,
          }),
        );
      }
    }

    // 5. The names. Two lines each: what the act is, and which act it is with
    //    how far it reaches - because a numeral on its own names nothing and a
    //    name on its own does not say where it is in the seven.
    //
    //    Both baselines are struck from the line the act is set on, so the two
    //    of them straddle it: the name's descenders sit just above, the caption
    //    just below. The two numbers are the type's own sizes in `.ui-stop-name`
    //    and `.ui-stop-meta` - a fifth of a name above, a caption and a bit
    //    below - and they move when those move, which is why they are named.
    const NAME_RISE = 5.5;
    const META_DROP = 11;
    for (const band of CIRCUIT_ACTS) {
      const info = CAMPAIGN[band.act];
      const open = band.act <= this.profile.unlockedAct;
      const on = `${band.act === picked ? ' sel' : ''}${open ? '' : ' locked'}`;
      const name = svgEl('text', {
        class: `ui-stop-name${on}`,
        x: band.labelX.toFixed(1),
        y: (band.labelY - NAME_RISE).toFixed(1),
        'text-anchor': band.anchor,
      });
      name.textContent = info.name;
      const meta = svgEl('text', {
        class: `ui-stop-meta${on}`,
        x: band.labelX.toFixed(1),
        y: (band.labelY + META_DROP).toFixed(1),
        'text-anchor': band.anchor,
      });
      meta.textContent = `${ROMAN[band.act] ?? band.act + 1} · ${band.range}`;
      svg.append(name, meta);
    }
    // ...and the one place on the line that is two stops: where it closes.
    const seam = svgEl('text', {
      class: 'ui-seam-name',
      x: MAP_W / 2,
      y: MAP_H - 20,
    });
    seam.textContent = CAMPAIGN[0].act.levels[0].name;
    svg.append(seam);

    wrap.append(svg, ...this.actTargets(stations, here, picked));
    return wrap;
  }

  /**
   * The world, laid out across the whole screen and under everything on it.
   *
   * The two surfaces used to be drawn inside the map's own `viewBox`, which put
   * a frame round them: the water stopped at the left and right edges of a
   * three-hundred-and-twenty-unit box and again at the top and bottom of it, and
   * four straight edges round a sea is a picture of a sea rather than the thing
   * the route is standing in. It is one element now, fixed to the viewport,
   * behind the panel, and the bands run off all four sides of the screen.
   *
   * Which means measuring rather than computing. The map is laid out by CSS - a
   * height that is a `clamp` on the viewport and a width that is whichever of
   * two things is smaller - so where the box landed and how big it got is a
   * question only the browser can answer. It is asked here, once per layout, and
   * the answer is handed to `meta/Circuit.ts` as a frame; everything about the
   * shape of the world stays over there with the rest of the geometry.
   *
   * Called on every render, and again whenever the map is resized or the screen
   * is scrolled under it - both of which move the box the surfaces are pinned
   * to, and neither of which is a render.
   *
   * A scroll is why the frame is remembered. The map screen scrolls on a short
   * phone and the listener is `passive`, so this runs at whatever rate a finger
   * moves; every pixel of that used to be four full-screen arcs rebuilt, and it
   * is now six of them and sixty placements on top. Most of those events do not
   * move the box at all - the panel only scrolls once the station list is open -
   * and the ones that do not are worth nothing.
   */
  private layoutWorld(): void {
    const map = this.panel.querySelector('svg.ui-map-world');
    const show = this.screen === 'circuit' && map !== null;
    this.world.classList.toggle('hidden', !show);
    if (!show || map === null) return;
    const box = map.getBoundingClientRect();
    if (box.width <= 0) return;
    const frame: WorldFrame = {
      scale: box.width / MAP_W,
      x: box.left,
      y: box.top,
      width: this.root.clientWidth,
      height: this.root.clientHeight,
    };
    const key = `${frame.scale} ${frame.x} ${frame.y} ${frame.width} ${frame.height}`;
    if (key === this.worldFrame) return;
    this.worldFrame = key;
    this.world.setAttribute('viewBox', `0 0 ${frame.width} ${frame.height}`);
    const face: [SVGPathElement, string][] = [
      [this.worldParts.space, worldBandPath(frame, SPACE_Y, 0)],
      [this.worldParts.air, worldLayerPath(frame, SPACE_Y, SEA_Y)],
      [this.worldParts.water, worldBandPath(frame, SEA_Y, frame.height)],
      [this.worldParts.bed, worldBandPath(frame, FLOOR_Y, frame.height)],
      [this.worldParts.karman, worldFacePath(frame, SPACE_Y)],
      [this.worldParts.sea, worldFacePath(frame, SEA_Y)],
    ];
    for (const [node, d] of face) node.setAttribute('d', d);
    // ...and everybody in them. Two attributes each and never a new node: the
    // shapes are unit-sized in `meta/Habitat.ts` precisely so that placing one is
    // a transform, and a mark the route is standing on is turned off rather than
    // shuffled out of the way.
    const placed = placeHabitat(frame);
    for (let i = 0; i < placed.length; i++) {
      const p = placed[i]!;
      const node = this.worldLife[i]!;
      node.setAttribute('opacity', p.ink.toFixed(3));
      if (p.ink <= 0) continue;
      node.setAttribute(
        'transform',
        `translate(${p.x.toFixed(2)} ${p.y.toFixed(2)}) rotate(${p.angle.toFixed(1)}) ` +
          `scale(${p.drawn.toFixed(3)})`,
      );
    }
  }

  /**
   * The seven acts, as seven targets laid over the picture.
   *
   * They carry no ink of their own beyond the faintest tint on the selected one:
   * everything a player needs to see about an act - whether it is lit, where it
   * runs, what it is called, how far it reaches - is already drawn underneath,
   * and a second outline round it would be the map competing with itself. What
   * they carry instead is everything a *button* has to have: a focus ring, a
   * name a screen reader reads as a sentence, a pressed state, and a disabled
   * one for an act nobody has reached yet.
   *
   * Each one is placed from the same rectangle `meta/Circuit.ts` computes and a
   * test checks, converted to percentages of the atlas box. The frame's
   * `aspect-ratio` is that box, so this is a placement rather than an estimate.
   */
  private actTargets(
    stations: StationRecord,
    here: CampaignPosition | null,
    picked: number,
  ): HTMLElement[] {
    const t = this.t;
    return CIRCUIT_ACTS.map((band) => {
      const info = CAMPAIGN[band.act]!;
      const open = band.act <= this.profile.unlockedAct;
      const done = clearedIn(stations, band.act);
      const current = here !== null && here.act === band.act;
      const roman = ROMAN[band.act] ?? String(band.act + 1);

      const b = document.createElement('button');
      b.type = 'button';
      b.className =
        `ui-map-act${open ? '' : ' locked'}${done >= band.count ? ' done' : ''}` +
        `${band.act === picked ? ' sel' : ''}${current ? ' here' : ''}`;
      b.disabled = !open;
      b.dataset.focus = `act-${band.act}`;
      b.setAttribute('aria-pressed', band.act === picked ? 'true' : 'false');
      b.style.left = `${((band.hit.x / MAP_W) * 100).toFixed(3)}%`;
      b.style.top = `${((band.hit.y / MAP_H) * 100).toFixed(3)}%`;
      b.style.width = `${((band.hit.w / MAP_W) * 100).toFixed(3)}%`;
      b.style.height = `${((band.hit.h / MAP_H) * 100).toFixed(3)}%`;
      // The target is a piece of a drawing; the label is the sentence the
      // drawing is making there, and a screen reader gets the sentence.
      const state = !open
        ? t.actLocked
        : done >= band.count
          ? t.actCleared
          : `${done}/${band.count} ${t.levelsCleared}`;
      b.setAttribute(
        'aria-label',
        `${t.actLabel} ${roman}: ${info.name} — ${state}${current ? `, ${t.hereLabel}` : ''}`,
      );
      if (open) {
        b.addEventListener('click', () => {
          this.hooks.onPress(false);
          this.pickedAct = band.act;
          this.focusKey = `act-${band.act}`;
          this.render();
        });
      }
      return b;
    });
  }

  /**
   * Under the map: the selected act, in the only words the screen has - and the
   * door to its stations.
   *
   * Name and verb, because the acts differ in what your hand is doing rather than
   * in what is in them; six dots, because "how much of this one is left" is the
   * question the map answers at a glance for the journey and not for the act the
   * player is about to press; and one line of what the act *is*, which is the
   * thing seven names and seven verbs between them never said.
   *
   * All of it is one disclosure. It was a bordered, tinted card with a separate
   * STATIONS button two controls below it, which is a frame drawn round some
   * prose and then a button drawn to open what the prose is about. The prose is
   * the control now: the whole block is pressable and the stations unfold
   * directly underneath the sentence that introduced them. Nothing is drawn round
   * any of it - a screen with one paragraph on it does not need the paragraph
   * boxed to find it.
   *
   * What frameless does not mean is unstructured, and for a while this was six
   * tiers of type - numeral, name, verb, dots, prose, badge - each five pixels
   * from the next, which is a pile rather than a card. Six things at equal
   * distance say nothing about which of them belong together. So the same six are
   * now three groups, and the space between them is what does the grouping:
   *
   *   - **Which act, and what it is to you**, on one letterspaced line. The
   *     numeral used to float on its own beside the name, at ten pixels and a
   *     third of an em apart, where a lone `I` reads as a stray tick rather than
   *     as a number; and the badge that says you are standing in this act used to
   *     be a *seventh* line at the bottom, directly above a second small line
   *     about the whole circuit. They are one eyebrow now - ACT I · YOU ARE HERE -
   *     and only the half that is news is in the accent.
   *   - **Name and verb**, tight together, because they are the same sentence.
   *   - **The arc**, with real air above it.
   *   - **The foot**: the word that says what opens, and nothing else. There were
   *     six dots beside it - one per station, filled behind you - and they are
   *     gone, because the map directly above draws those same six stops in those
   *     same states, at the place on the route where they actually are. A row of
   *     beads under a picture of the beads is the card repeating the drawing in a
   *     worse alphabet, and it is the second time this screen has had to delete a
   *     small copy of the map from underneath the map.
   */
  private actCard(
    stations: StationRecord,
    here: CampaignPosition | null,
    picked: number,
  ): HTMLElement {
    const t = this.t;
    const info = CAMPAIGN[picked]!;
    const total = info.act.levels.length;
    const done = clearedIn(stations, picked);
    const at = here !== null && here.act === picked ? here.level : -1;
    const open = this.stationsOpen;

    const core = el('div', 'ui-map-core');
    const b = document.createElement('button');
    b.type = 'button';
    b.className = `ui-map-core-open${open ? ' open' : ''}`;
    b.setAttribute('aria-expanded', open ? 'true' : 'false');
    b.setAttribute('aria-label', `${info.name} — ${t.stationList}`);
    b.dataset.focus = 'stations';

    // The eyebrow: which of the seven, and - only when there is something to say
    // that the lit stretch of line cannot - that this is where you left off, or
    // that there is nothing left of it.
    const kicker = el('span', `ui-map-core-kicker${at >= 0 ? ' here' : ''}`);
    kicker.append(`${t.actLabel} ${ROMAN[picked] ?? String(picked + 1)}`);
    const badge = at >= 0 ? t.hereLabel : done >= total ? t.actCleared : '';
    if (badge !== '') kicker.append(el('span', 'ui-map-core-badge', ` · ${badge}`));

    b.append(
      kicker,
      el('strong', 'ui-map-core-name', info.name),
      el('span', 'ui-map-core-verb', info.verb),
      // A `<span>` and not a `<p>`: it is inside the button, because the sentence
      // is what a player would press, and a button may only hold phrasing content.
      el('span', 'ui-map-arc', info.arc),
    );

    // The foot, and the only thing on the card that admits to being a control:
    // the word for what unfolds, and the chevron that says which way it goes.
    const foot = el('span', 'ui-map-core-foot');
    foot.append(el('span', 'ui-map-core-more', `${total} ${t.levelsCleared}`), chevron());
    b.append(foot);
    b.addEventListener('click', () => {
      this.hooks.onPress(false);
      this.stationsOpen = !open;
      this.focusKey = 'stations';
      this.render();
    });

    core.append(b);
    if (open) core.append(this.stationList(info, done, at));
    return core;
  }

  // --- widgets ------------------------------------------------------------

  private patch(delta: Partial<Settings>, rerender = true): void {
    this.settings = { ...this.settings, ...delta };
    // Whatever `applySettings` hands back during this call is an echo of what we
    // just sent it, and this shell has already stored it. Suppressing the round
    // trip is what makes `rerender` mean anything at all: without it the slider's
    // `rerender = false` was defeated one frame later by `setSettings` redrawing
    // the panel anyway, which is exactly the redraw the flag exists to avoid.
    this.selfPatching = true;
    try {
      this.hooks.onSettingsChange(this.settings);
    } finally {
      this.selfPatching = false;
    }
    // `render` draws the drawer as well as the panel, so a switch pressed inside
    // it during a run redraws the right thing even though the panel is empty. A
    // slider passes `rerender = false` and updates its own readout, for the
    // reason it always did: replacing a range input mid-drag drops the drag.
    if (rerender) this.render();
  }

  private patchAudio(
    track: AudioTrackKey,
    delta: Partial<AudioTrackSettings>,
    rerender = true,
  ): void {
    this.patch(
      {
        audio: {
          ...this.settings.audio,
          [track]: { ...this.settings.audio[track], ...delta },
        },
      },
      rerender,
    );
  }

  /**
   * One switch that silences everything, above the ten that shape it.
   *
   * It is deliberately *not* a track: muting sets `Settings.muted`, the mixer
   * underneath keeps every level it had, and unmuting hands back the mix the
   * player built rather than ten sliders at their defaults.
   *
   * There were two of these once, one in this drawer and one on a settings screen
   * that listed all ten slots whether or not the act filled them. That screen is
   * gone and nothing was lost with it: the drawer names each layer after what it
   * actually is in the act being played, which the settings copy could only guess
   * at, and "make it quiet, now" is answered from every other screen by the
   * button on the glass. A mixer belongs where the thing it mixes can be heard.
   */
  private masterSwitch(): HTMLElement {
    const row = this.toggle(this.t.allSound, !this.settings.muted, (on) => {
      // Both mixers are rebuilt by the patch, so the switch has to say where the
      // keyboard should land afterwards - exactly as a track switch does.
      this.focusKey = 'audio-master';
      this.patch({ muted: !on });
    });
    row.classList.add('ui-audio-master');
    row.querySelector('button')?.setAttribute('data-focus', 'audio-master');
    return row;
  }

  /**
   * One track, on one line: what it is, how loud it is, whether it is on.
   *
   * It was two lines and a readout - name and switch above, fader and `100%`
   * below - which is 58px a track and ten tracks a drawer. See `.ui-audio-track`
   * in `index.html` for what that cost. The number is gone with the second line
   * and the fader carries it instead: the fill *is* the level, and the percent a
   * reader needs is still on `aria-valuetext` where a reader was always getting
   * it from.
   *
   * The name stays a `<label>` for the fader rather than becoming part of the
   * switch. Two controls on one line have to be told apart by touch as well as by
   * eye, and the one that says what the row is should not also be the one that
   * turns it off.
   */
  private audioTrack(
    track: AudioTrackKey,
    label: string,
    settings: AudioTrackSettings,
  ): HTMLElement {
    const row = el('div', 'ui-audio-track');
    row.classList.toggle('muted', !settings.enabled);

    const volumeId = `audio-${track}-volume`;
    const name = document.createElement('label');
    name.className = 'ui-setting-label';
    name.htmlFor = volumeId;
    name.textContent = label;

    const toggle = document.createElement('button');
    toggle.type = 'button';
    // Two classes, and the second one is the whole difference between this switch
    // and the master above it. `.ui-switch` is a filled lozenge because everywhere
    // else in the shell one switch is being compared with nothing; here there are
    // ten in a column, and `.ui-audio-toggle` draws them as hairlines so that the
    // one a player has changed is the one that stands out. See `index.html`.
    toggle.className = 'ui-switch ui-audio-toggle';
    toggle.setAttribute('role', 'switch');
    toggle.setAttribute('aria-checked', settings.enabled ? 'true' : 'false');
    toggle.setAttribute('aria-label', label);
    toggle.textContent = settings.enabled ? this.t.on : this.t.off;
    toggle.classList.toggle('on', settings.enabled);
    // A switch that answers being pressed by moving focus somewhere else is a
    // switch a keyboard user can press exactly once. See `applyFocus`.
    toggle.dataset.focus = `audio-${track}`;
    toggle.addEventListener('click', () => {
      this.hooks.onPress(!settings.enabled);
      this.focusKey = `audio-${track}`;
      this.patchAudio(track, { enabled: !settings.enabled });
    });

    const slider = document.createElement('input');
    slider.id = volumeId;
    slider.type = 'range';
    slider.min = '0';
    slider.max = '100';
    slider.step = '1';
    slider.value = String(Math.round(settings.volume * 100));
    slider.setAttribute('aria-label', `${label} – ${this.t.volume}`);
    slider.setAttribute('aria-valuetext', `${slider.value}%`);
    // The fill is drawn by the stylesheet off this one number, so the level is a
    // property of the element rather than a second node kept in step with it -
    // which matters here more than it looks: the fader is the one control in the
    // shell that is *not* allowed to redraw itself mid-drag (`rerender = false`),
    // so anything it has to keep current has to be reachable without a render.
    //
    // On the row and not on the input, because the line the level is drawn on is
    // the row's - it is the rule under the track's name, running the width of the
    // panel, and the input is the transparent box over it that catches the drag.
    // See `.ui-audio-track::after` in `index.html`.
    const paint = (percent: number): void => row.style.setProperty('--fill', `${percent}%`);
    paint(Number(slider.value));
    slider.addEventListener('input', () => {
      const percent = Number(slider.value);
      paint(percent);
      slider.setAttribute('aria-valuetext', `${percent}%`);
      this.patchAudio(track, { volume: percent / 100 }, false);
    });
    row.append(name, slider, toggle);
    return row;
  }

  private button(label: string, cls: string, onClick: () => void): HTMLButtonElement {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = `ui-btn ${cls}`;
    b.textContent = label;
    b.addEventListener('click', () => {
      this.hooks.onPress(cls.includes('primary'));
      onClick();
    });
    return b;
  }

  private row(children: HTMLElement[]): HTMLDivElement {
    const d = el('div', 'ui-row');
    d.append(...children);
    return d;
  }

  private toggle(
    label: string,
    value: boolean,
    onChange: (v: boolean) => void,
    focus?: string,
  ): HTMLElement {
    const row = el('div', 'ui-setting');
    const name = el('span', 'ui-setting-label', label);
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'ui-switch';
    b.setAttribute('role', 'switch');
    b.setAttribute('aria-checked', value ? 'true' : 'false');
    b.setAttribute('aria-label', label);
    b.textContent = value ? this.t.on : this.t.off;
    b.classList.toggle('on', value);
    if (focus !== undefined) b.dataset.focus = focus;
    b.addEventListener('click', () => {
      this.hooks.onPress(!value);
      if (focus !== undefined) this.focusKey = focus;
      onChange(!value);
    });
    row.append(name, b);
    return row;
  }

}

/** The act numerals, written out. Seven of them and there will never be more. */
const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

/**
 * The arrowhead on a seam, drawn pointing right and turned to the line by the
 * caller. In atlas units, about a stop and a half across.
 *
 * Its point is on the line and its arms are open behind it, so the line runs
 * into the chevron and out through the tip - which is what makes it read as the
 * line going somewhere rather than as a symbol parked beside it.
 */
const ARROW_HEAD = 'M -3.2 -4 L 1.4 0 L -3.2 4';

/**
 * The disclosure glyph, and the one thing on the act card that turns.
 *
 * It was a text `⌄` swapped for a `⌃`, which is two different characters with two
 * different metrics sitting at two different heights, dangling off the end of the
 * verb where it read as a typo. Drawn, it is one shape that rotates, and the
 * rotation is safe here for the reason it was not before: `:active` owns
 * `transform` on the *button*, and this is a child of it.
 */
/**
 * The cross on the mixer's close, drawn rather than typed.
 *
 * A `×` is a multiplication sign at whatever weight the font feels like giving
 * it, and it sits on the text baseline rather than in the middle of the button -
 * which is visible the moment the button is a 30px circle with nothing else in
 * it. Two strokes at the shell's own hairline weight centre themselves.
 */
function closeMark(): SVGSVGElement {
  const svg = svgEl('svg', {
    viewBox: '0 0 12 12',
    'aria-hidden': 'true',
    focusable: 'false',
  });
  svg.append(svgEl('path', { d: 'M3 3 9 9' }), svgEl('path', { d: 'M9 3 3 9' }));
  return svg;
}

function chevron(): SVGSVGElement {
  const svg = svgEl('svg', {
    class: 'ui-map-core-chevron',
    viewBox: '0 0 12 12',
    'aria-hidden': 'true',
    focusable: 'false',
  });
  svg.append(svgEl('path', { d: 'M2.6 4.6 6 8l3.4-3.4' }));
  return svg;
}

function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  cls: string,
  text = '',
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (cls !== '') node.className = cls;
  if (text !== '') node.textContent = text;
  return node;
}

const SVG_NS = 'http://www.w3.org/2000/svg';

/**
 * The same thing as `el`, in the other namespace.
 *
 * `className` is read-only on an SVG element and `document.createElement` makes an
 * unknown HTML element that happens to be spelled `circle`, so neither half of the
 * function above can be reused. Attributes rather than properties for the same
 * reason: `x`, `cx` and `points` are not IDL properties that accept a number.
 */
function svgEl<K extends keyof SVGElementTagNameMap>(
  tag: K,
  attrs: Record<string, string | number>,
): SVGElementTagNameMap[K] {
  const node = document.createElementNS(SVG_NS, tag);
  for (const [name, value] of Object.entries(attrs)) node.setAttribute(name, String(value));
  return node;
}

/** A point in a drawn box. The map converts atlas units into these and no further. */
interface Place {
  x: number;
  y: number;
}

/**
 * A run of points as one path.
 *
 * Everything on the map is a sampled curve rather than an arc of anything -
 * surfaces droop, the loop is a sine of a sine - so there is no clever `A`
 * command to reach for and no reason to want one: at thirty-four samples a leg
 * the joins are under a pixel.
 */
function polyPath(points: readonly Place[]): string {
  return points
    .map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x.toFixed(2)} ${p.y.toFixed(2)}`)
    .join(' ');
}

/**
 * The mark above the wordmark: one ring with the water running through it.
 *
 * The two things the game is about, in forty-six pixels. The ring is the circuit
 * - the same closed loop the map draws - and the two waves are the only part of
 * the opening screen that is allowed to move, because the title screen's whole
 * claim is that the water is the thing you touch.
 *
 * The waves are drawn four periods wider than the box they are clipped to, so
 * the drift can run one period and start over without a seam.
 */
function titleMark(): SVGSVGElement {
  const svg = svgEl('svg', { class: 'ui-mark', viewBox: '0 0 48 48' });
  svg.setAttribute('aria-hidden', 'true');
  const defs = svgEl('defs', {});
  const clip = svgEl('clipPath', { id: 'slowblue-mark-clip' });
  clip.append(svgEl('circle', { cx: 24, cy: 24, r: 17 }));
  defs.append(clip);
  const water = svgEl('g', { 'clip-path': 'url(#slowblue-mark-clip)' });
  water.append(
    svgEl('path', {
      class: 'ui-mark-wave',
      d: 'M-24 26 q6 -5 12 0 t12 0 t12 0 t12 0 t12 0 t12 0',
    }),
    svgEl('path', {
      class: 'ui-mark-wave slow',
      d: 'M-24 33 q6 -4 12 0 t12 0 t12 0 t12 0 t12 0 t12 0',
    }),
  );
  svg.append(defs, water, svgEl('circle', { class: 'ui-mark-ring', cx: 24, cy: 24, r: 17 }));
  return svg;
}

/**
 * Whether there is a journey to speak of - anything a player would mind losing.
 *
 * "Under way" rather than "has a save": a circuit saved at act I station 1 and
 * never played is a game about to begin, whatever is on disk. Two controls read
 * it and they must agree, or the map would offer to restart a journey while the
 * button above it still said BEGIN.
 */
function journeyUnderWay(stations: StationRecord, here: CampaignPosition | null): boolean {
  return stationsCleared(stations) > 0 || (here !== null && (here.act > 0 || here.level > 0));
}

/**
 * A mode that changes what the game is, said next to the button that starts it.
 *
 * Continuous circuit removes the results screen. It is a setting, and a setting
 * that silently changes the game is a setting the player will not connect to the
 * game they got.
 */
function modeNote(text: string): HTMLElement {
  return el('p', 'ui-mode', text);
}

/**
 * The mixer button's face: a speaker with two arcs coming off it.
 *
 * Three things have stood here. The `≋` glyph read as the water rather than the
 * sound of it; three faders read as settings of *some* kind, with nothing in the
 * shape saying which. This says sound, and it is the one icon every player
 * already knows. The old worry about a speaker - that a speaker means mute - is
 * a worry about a speaker with a *slash* through it, or one drawn silent. This
 * one is sounding, and the button that opens the layers is the same button that
 * shows their levels once it is open.
 */
function mixerIcon(): SVGSVGElement {
  const svg = svgEl('svg', { class: 'ui-ico ui-ico-mix', viewBox: '0 0 16 16' });
  svg.setAttribute('aria-hidden', 'true');
  svg.append(
    // Cone and body in one closed shape, so the fill lands as one speaker.
    svgEl('path', { class: 'solid', d: 'M8.2 2.6 4.6 5.8H2.4v4.4h2.2l3.6 3.2z' }),
    svgEl('path', { d: 'M10.9 5.9a4 4 0 0 1 0 4.2' }),
    svgEl('path', { d: 'M12.9 3.9a7 7 0 0 1 0 8.2' }),
    // Only drawn when the button carries `.muted`; see the stylesheet.
    svgEl('path', { class: 'slash', d: 'M2.6 13.4 13.4 2.6' }),
  );
  return svg;
}

/**
 * The title screen's field: three shafts of surface light, two rings and
 * fourteen motes.
 *
 * Every number here is written down rather than rolled, and for a reason that is
 * not tidiness: `e2e/capture.spec.ts` photographs this screen, and a backdrop
 * that deals itself a new arrangement on every load is a screenshot that can
 * never be compared with the last one.
 */
const SHAFTS: readonly {
  left: number;
  tilt: number;
  delay: number;
  span: number;
}[] = [
  { left: -6, tilt: 9, delay: 0, span: 17 },
  { left: 34, tilt: -6, delay: -6.5, span: 21 },
  { left: 66, tilt: 12, delay: -12, span: 15 },
];

/** `x` is a percentage across, `d` the climb in seconds, `s` the diameter. */
const MOTES: readonly { x: number; d: number; delay: number; s: number }[] = [
  { x: 8, d: 26, delay: -2, s: 2 },
  { x: 17, d: 34, delay: -14, s: 3 },
  { x: 23, d: 21, delay: -8, s: 2 },
  { x: 31, d: 39, delay: -24, s: 2 },
  { x: 39, d: 29, delay: -5, s: 3 },
  { x: 46, d: 24, delay: -18, s: 2 },
  { x: 52, d: 36, delay: -11, s: 2 },
  { x: 58, d: 27, delay: -21, s: 3 },
  { x: 64, d: 32, delay: -3, s: 2 },
  { x: 71, d: 23, delay: -16, s: 2 },
  { x: 78, d: 37, delay: -9, s: 3 },
  { x: 84, d: 28, delay: -26, s: 2 },
  { x: 90, d: 31, delay: -13, s: 2 },
  { x: 95, d: 25, delay: -6, s: 2 },
];

function buildVeil(): HTMLDivElement {
  const veil = el('div', 'ui-veil hidden');
  veil.setAttribute('aria-hidden', 'true');
  for (const s of SHAFTS) {
    const shaft = el('i', 'ui-veil-shaft');
    shaft.style.left = `${s.left}%`;
    shaft.style.transform = `rotate(${s.tilt}deg)`;
    shaft.style.animationDuration = `${s.span}s`;
    shaft.style.animationDelay = `${s.delay}s`;
    veil.append(shaft);
  }
  veil.append(el('div', 'ui-veil-ring'), el('div', 'ui-veil-ring inner'));
  for (const m of MOTES) {
    const mote = el('i', 'ui-veil-mote');
    mote.style.left = `${m.x}%`;
    mote.style.width = `${m.s}px`;
    mote.style.height = `${m.s}px`;
    mote.style.animationDuration = `${m.d}s`;
    mote.style.animationDelay = `${m.delay}s`;
    veil.append(mote);
  }
  return veil;
}
