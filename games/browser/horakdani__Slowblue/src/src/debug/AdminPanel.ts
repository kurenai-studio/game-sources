import type { AudioEngine, PreviewVoice } from '../audio/AudioEngine';
import { CAMPAIGN_ACTS } from '../config/campaign';
import {
  ACT_WATER,
  levelStartSectionIn,
  type Act,
  type Level,
  type ScriptEntry,
  type SectionSpec,
} from '../config/levels';
import { BEDS, BED_LIST, type BedKey } from '../audio/Beds';
import type { AudioTrackKey } from '../config/settings';

/**
 * Slowblue: the admin surface. Every authored thing in the game, one click away.
 *
 * The tuning panel next door answers "what does this number feel like". This one
 * answers a question the campaign made unanswerable: **what does this one piece
 * sound and look like, on its own?** Forty-two stations of authored content sit
 * behind a run that has to be flown from the trench floor to get to them, and
 * seven bed voices are on Poisson clocks that deal a whale once a minute. Neither
 * can be *examined* by playing the game, which is the only way they were ever
 * checked, which is why the last station of act II had been seen about four times.
 *
 * Three tabs, and they are the three things there are to try:
 *
 *   - **Stations** - all forty-two stations. One click drops the run on the station's
 *     first section, in the right act, the right medium and the right palette.
 *   - **Sections** - every authored section, individually. Same click, one
 *     section further in: the course simply starts building from that script
 *     index (see `ObstacleSystem.reset`), so a narrows is a run that opens on a
 *     narrows rather than a run that eventually reaches one.
 *   - **Sounds** - every sound the engine can make, fired by hand, over a bed
 *     whose depth, medium and ring-hold are on sliders instead of on the game.
 *
 * It is a dev tool and it says so: it is behind `?admin=1` (or a dev build), it
 * freezes the run underneath rather than letting it die behind the overlay, and
 * a run started from here is not written to the player's profile - see `main.ts`.
 */

export interface AdminHost {
  /** Start a run on exactly this section of this act. */
  play(act: Act, section: number): void;
  audio: AudioEngine;
  /** True if this mixer track is on and above zero. A muted track is why nothing played. */
  audible(track: AudioTrackKey): boolean;
  /** Turns every mixer track back on, so a sound test is never silent by accident. */
  unmuteAll(): void;
  /**
   * While the sound tab is up, the panel owns the bed: `main` stops pushing the
   * medium, the depth and the ring hold at it every frame. Without this a slider
   * is overwritten sixty times a second by whatever the water is doing.
   */
  setAudioOverride(on: boolean): void;
  /** Stops the clock under the overlay. A run must not die while it is being read. */
  setFrozen(frozen: boolean): void;
  /** Where the run currently is: act key, station index, section id. */
  here(): { act: string; level: number; section: number; medium: string };
}

type Tab = 'levels' | 'sections' | 'sounds';

/**
 * Every act the campaign has, in play order, straight from the registry - so an
 * act added to `config/campaign.ts` is startable here without this file knowing
 * it exists. The admin surface has to reach all seven; a hand-maintained list is
 * exactly the thing that quietly stops at two.
 */
const ACTS: Act[] = CAMPAIGN_ACTS;

const ACT_NAMES: Record<string, string> = {
  water: 'I · WATER',
  air: 'II · AIR',
  thin: 'III · THIN AIR',
  orbit: 'IV · ORBIT',
  reentry: 'V · FALLBACK',
  rain: 'VI · RAIN',
  home: 'VII · HOMECOMING',
};

/** Roman numerals for the station index. Six per act; nothing here needs more. */
const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];

const KIND_NAMES: Record<string, string> = {
  open: 'open',
  gate: 'gate',
  rock: 'rock',
  narrows: 'narrows',
  drift: 'chicane',
  vortex: 'vortex',
  predator: 'predator',
  bank: 'cloud bank',
  tower: 'tower cloud',
  pass: 'pass',
  wisps: 'wisps',
  rotor: 'rotor',
  raptor: 'raptor',
  street: 'cloud street',
  drape: 'drape',
  bloom: 'jellyfish bloom',
};

/** One sound the panel can fire, with the mixer track that can silence it. */
export interface SoundEntry {
  label: string;
  track: AudioTrackKey;
  play: (audio: AudioEngine, pan: number) => void;
}

/**
 * Every event cue, fired by hand.
 *
 * Four of them are **the bed's**, not the game's, and are marked so: the stroke,
 * the rescue and the ring are voiced by whichever bed is selected above
 * (`Rescues.ts`), because the hand and the reward are made of the medium the same
 * way the room is. Play them once per bed; that is the whole reason the bed
 * picker sits at the top of this tab.
 */
const EVENT_SOUNDS: SoundEntry[] = [
  { label: 'stroke · fast ▸ bed', track: 'movement', play: (a, p) => a.stroke(0.9, p) },
  { label: 'stroke · slow ▸ bed', track: 'movement', play: (a, p) => a.stroke(0.08, p) },
  { label: 'swarm joins ▸ bed', track: 'objectives', play: (a, p) => a.rescue(12, p) },
  { label: 'ring held ▸ bed', track: 'objectives', play: (a, p) => a.ring(p) },
  { label: 'ring lost', track: 'danger', play: (a) => a.ringLost() },
  { label: 'split swarm rejoins', track: 'objectives', play: (a) => a.reform() },
  { label: 'section cleared', track: 'objectives', play: (a) => a.gate(3) },
  { label: 'streak broken', track: 'danger', play: (a) => a.streakBreak() },
  { label: 'straggler lost', track: 'danger', play: (a, p) => a.loss(0, p) },
  { label: 'hit a rock', track: 'danger', play: (a, p) => a.loss(1, p) },
  { label: 'taken by a hunter', track: 'danger', play: (a, p) => a.loss(2, p) },
  { label: 'bite', track: 'danger', play: (a, p) => a.bite(p) },
  { label: 'new station', track: 'objectives', play: (a) => a.level(2) },
  { label: 'campaign complete', track: 'objectives', play: (a) => a.complete() },
  { label: 'zone (old cue)', track: 'objectives', play: (a) => a.zone() },
  { label: 'run failed', track: 'danger', play: (a) => a.fail() },
  { label: 'new record', track: 'objectives', play: (a) => a.record() },
  { label: 'interface · bright', track: 'interface', play: (a) => a.ui(true) },
  { label: 'interface · muted', track: 'interface', play: (a) => a.ui(false) },
];

/**
 * The seven ending cues, in the order the circuit plays them.
 *
 * Their own group, and not because there are a lot of them. Every other sound in
 * this panel fires dozens of times in a run and can be heard by playing the game
 * badly for thirty seconds; these fire **once per act**, at the end of it, after
 * ten minutes of flying, and only if the act was finished. Six of the seven had
 * never been in this list at all - `surface()` was, because it is act I's and
 * predates the campaign - so the only way to hear the other six was to complete
 * the act they belong to. Four of them were written without ever being heard.
 *
 * They are also the longest sounds the engine makes: `overview()` holds for
 * fourteen seconds and `circle()` for fourteen. Fired back to back they overlap
 * into something that is not any of them, so they are worth listening to one at a
 * time, with a pause - which is the other reason for grouping them apart.
 */
export const ENDING_SOUNDS: SoundEntry[] = [
  { label: 'I · breaking the surface', track: 'objectives', play: (a) => a.surface() },
  { label: 'II · the top of the air', track: 'objectives', play: (a) => a.release() },
  { label: 'III · the air runs out', track: 'objectives', play: (a) => a.airless() },
  { label: 'IV · the camera turns', track: 'objectives', play: (a) => a.overview() },
  { label: 'V · the fire goes out', track: 'objectives', play: (a) => a.nucleus() },
  { label: 'VI · fresh water and salt', track: 'objectives', play: (a) => a.estuary() },
  { label: 'VII · the circle closes', track: 'objectives', play: (a) => a.circle() },
];

/**
 * The bed's own voices, per bed. All of them are scheduled in the game; none is
 * triggered.
 *
 * Keyed by bed rather than listed flat, because a flat list was how the engine
 * itself used to be arranged and it is the same mistake: a whale button that
 * works while the orbit bed is up is a tool that will happily demonstrate a sound
 * the game cannot make.
 */
const BED_SOUNDS: Record<BedKey, { label: string; track: AudioTrackKey; voice: PreviewVoice }[]> = {
  deep: [
    { label: 'bubble', track: 'ocean', voice: 'bubble' },
    { label: 'gurgle', track: 'ocean', voice: 'gurgle' },
    { label: 'exhale · splash', track: 'ocean', voice: 'hush' },
    { label: 'whale song', track: 'whale', voice: 'whale' },
    { label: 'bell', track: 'ambience', voice: 'bowl' },
  ],
  flight: [
    { label: 'wingbeat', track: 'ocean', voice: 'wing' },
    { label: 'flock wings', track: 'ocean', voice: 'flock' },
    { label: 'exhale · glide', track: 'ocean', voice: 'hush' },
    { label: 'gust', track: 'motion', voice: 'gust' },
    { label: 'thunder', track: 'whale', voice: 'thunder' },
    { label: 'bell', track: 'ambience', voice: 'bowl' },
  ],
  thin: [
    { label: 'ice crystal', track: 'ocean', voice: 'crystal' },
    { label: 'layer shear', track: 'motion', voice: 'shear' },
    { label: 'infrasound', track: 'whale', voice: 'infrasound' },
    { label: 'glass bell', track: 'ambience', voice: 'bowl' },
  ],
  orbit: [
    { label: 'heartbeat', track: 'motion', voice: 'heart' },
    { label: 'whistler swarm', track: 'whale', voice: 'whistler' },
    { label: 'clear bell', track: 'ambience', voice: 'bowl' },
  ],
  fire: [
    { label: 'glowing grain', track: 'shimmer', voice: 'spark' },
    { label: 'shockwave', track: 'motion', voice: 'shock' },
    { label: 'deep bell', track: 'ambience', voice: 'bowl' },
  ],
  rain: [
    { label: 'raindrop', track: 'ocean', voice: 'drop' },
    { label: 'exhale · drops', track: 'ocean', voice: 'hush' },
    { label: 'leaf patter', track: 'shimmer', voice: 'patter' },
    { label: 'thunder', track: 'whale', voice: 'thunder' },
    { label: 'bell', track: 'ambience', voice: 'bowl' },
  ],
  brook: [
    { label: 'splash', track: 'ocean', voice: 'riffle' },
    { label: 'exhale · eddy', track: 'ocean', voice: 'hush' },
    { label: 'stone in the streambed', track: 'whale', voice: 'stone' },
    { label: 'wooden bell', track: 'ambience', voice: 'bowl' },
  ],
  homecoming: [
    { label: 'bubble', track: 'ocean', voice: 'bubble' },
    { label: 'sea snow', track: 'motion', voice: 'flake' },
    { label: 'whale nearby', track: 'whale', voice: 'whale' },
    { label: 'deep bell', track: 'ambience', voice: 'bowl' },
  ],
};

export class AdminPanel {
  private root: HTMLDivElement;
  private toggle: HTMLButtonElement;
  private body: HTMLDivElement;
  private status: HTMLDivElement;
  private open = false;
  private tab: Tab = 'levels';
  private act: Act = ACT_WATER;
  /** The bed the sound tab is driving. Pushed at the engine on every change. */
  private bed = { key: 'deep' as BedKey, arc: 0.5, pan: 0 };

  constructor(private readonly host: AdminHost) {
    this.toggle = document.createElement('button');
    this.toggle.className = 'slowblue-admin-toggle';
    this.toggle.type = 'button';
    this.toggle.textContent = 'A';
    this.toggle.setAttribute('aria-label', 'admin');
    this.toggle.addEventListener('click', () => this.setOpen(!this.open));

    this.root = document.createElement('div');
    this.root.className = 'slowblue-admin';

    this.status = document.createElement('div');
    this.status.className = 'slowblue-admin-status';

    this.body = document.createElement('div');
    this.body.className = 'slowblue-admin-body';

    this.root.append(this.header(), this.status, this.body);
    document.body.append(this.toggle, this.root);
    this.setOpen(false);

    window.addEventListener('keydown', (e) => {
      // Never while something is being typed into - the tuning panel has a seed field.
      const tag = (e.target as HTMLElement | null)?.tagName;
      if (tag === 'INPUT' || tag === 'TEXTAREA') return;
      if (e.key === 'a' || e.key === 'A') this.setOpen(!this.open);
      else if (e.key === 'Escape' && this.open) this.setOpen(false);
    });
  }

  setOpen(open: boolean): void {
    this.open = open;
    this.root.classList.toggle('open', open);
    this.toggle.classList.toggle('on', open);
    this.host.setFrozen(open);
    this.host.setAudioOverride(open && this.tab === 'sounds');
    if (open) this.render();
    else this.body.replaceChildren();
  }

  /** Called once a frame from the loop. Only the one line that can change. */
  update(): void {
    if (!this.open) return;
    const at = this.host.here();
    const act = ACT_NAMES[at.act] ?? at.act;
    this.status.textContent = `now: ${act} · station ${ROMAN[at.level] ?? at.level + 1} · section ${at.section} · ${at.medium === 'air' ? 'air' : 'water'}`;
  }

  // --- chrome -------------------------------------------------------------

  private header(): HTMLElement {
    const bar = el('div', 'slowblue-admin-tabs');
    const tabs: [Tab, string][] = [
      ['levels', 'STATIONS'],
      ['sections', 'SECTIONS'],
      ['sounds', 'SOUNDS'],
    ];
    for (const [tab, label] of tabs) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'slowblue-admin-tab';
      b.textContent = label;
      b.dataset.tab = tab;
      b.addEventListener('click', () => {
        this.tab = tab;
        this.host.setAudioOverride(tab === 'sounds');
        this.render();
      });
      bar.append(b);
    }
    const close = document.createElement('button');
    close.type = 'button';
    close.className = 'slowblue-admin-close';
    close.textContent = '×';
    close.setAttribute('aria-label', 'close');
    close.addEventListener('click', () => this.setOpen(false));
    bar.append(close);
    return bar;
  }

  private render(): void {
    for (const b of this.root.querySelectorAll<HTMLElement>('.slowblue-admin-tab')) {
      b.classList.toggle('on', b.dataset.tab === this.tab);
    }
    this.update();
    switch (this.tab) {
      case 'levels':
        this.body.replaceChildren(this.actSwitch(), ...this.levelRows());
        break;
      case 'sections':
        this.body.replaceChildren(this.actSwitch(), ...this.sectionRows());
        break;
      case 'sounds':
        this.body.replaceChildren(...this.soundControls());
        break;
    }
    this.body.scrollTop = 0;
  }

  private actSwitch(): HTMLElement {
    const row = el('div', 'slowblue-admin-acts');
    for (const act of ACTS) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'slowblue-admin-act';
      b.classList.toggle('on', act === this.act);
      b.textContent = ACT_NAMES[act.key] ?? act.key;
      b.addEventListener('click', () => {
        this.act = act;
        this.render();
      });
      row.append(b);
    }
    return row;
  }

  // --- the map ------------------------------------------------------------

  private levelRows(): HTMLElement[] {
    return this.act.levels.map((level, i) => {
      const start = levelStartSectionIn(this.act, i);
      const row = document.createElement('button');
      row.type = 'button';
      row.className = 'slowblue-admin-row';
      row.append(
        el('span', 'slowblue-admin-index', ROMAN[i] ?? String(i + 1)),
        el('span', 'slowblue-admin-name', level.name),
        el('span', 'slowblue-admin-meta', altitudeLabel(level)),
        el('span', 'slowblue-admin-sub', `${level.subtitle} · ${summarise(level)}`),
      );
      row.addEventListener('click', () => this.jump(start));
      return row;
    });
  }

  private sectionRows(): HTMLElement[] {
    const out: HTMLElement[] = [];
    let level = -1;
    this.act.script.forEach((entry: ScriptEntry, section: number) => {
      if (entry.level !== level) {
        level = entry.level;
        const head = el(
          'div',
          'slowblue-admin-group',
          `${ROMAN[level] ?? level + 1} · ${this.act.levels[level]!.name}`,
        );
        out.push(head);
      }
      const spec = entry.spec;
      const row = document.createElement('button');
      row.type = 'button';
      row.className = 'slowblue-admin-row compact';
      row.append(
        el('span', 'slowblue-admin-index', `${ROMAN[entry.level] ?? entry.level + 1}/${entry.step + 1}`),
        el('span', 'slowblue-admin-name', KIND_NAMES[spec.kind] ?? spec.kind),
        el('span', 'slowblue-admin-meta', `#${section}`),
        el('span', 'slowblue-admin-sub', badges(spec).join(' · ')),
      );
      row.addEventListener('click', () => this.jump(section));
      out.push(row);
    });
    return out;
  }

  private jump(section: number): void {
    const act = this.act;
    // Unlock on the click that asked for it: a jump into act II with a cold audio
    // context is a silent flock, and the gesture that could fix that is this one.
    void this.host.audio.unlock();
    this.setOpen(false);
    this.host.play(act, section);
  }

  // --- the sounds ---------------------------------------------------------

  private soundControls(): HTMLElement[] {
    const out: HTMLElement[] = [];

    const muted = [
      ...EVENT_SOUNDS,
      ...ENDING_SOUNDS,
      ...Object.values(BED_SOUNDS).flat(),
    ].some((s) => !this.host.audible(s.track));
    if (muted) {
      const warn = el('div', 'slowblue-admin-warn', 'some mixer tracks are muted or at zero');
      const fix = document.createElement('button');
      fix.type = 'button';
      fix.className = 'slowblue-admin-btn';
      fix.textContent = 'unmute all';
      fix.addEventListener('click', () => {
        this.host.unmuteAll();
        this.render();
      });
      warn.append(fix);
      out.push(warn);
    }

    out.push(el('div', 'slowblue-admin-group', 'THE BED'));
    const beds = el('div', 'slowblue-admin-acts');
    for (const spec of BED_LIST) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'slowblue-admin-act';
      b.classList.toggle('on', this.bed.key === spec.key);
      b.textContent = spec.name;
      b.addEventListener('click', () => {
        this.bed.key = spec.key;
        this.pushBed();
        this.render();
      });
      beds.append(b);
    }
    out.push(beds);

    out.push(
      // One slider now, not two. Every bed reads the arc as its own quantity -
      // depth in act I, height in act III, how much fire is left in act V - so a
      // separate depth and altitude were two controls for one number.
      this.slider('arc (station within the act)', this.bed.arc, (v) => {
        this.bed.arc = v;
        this.pushBed();
      }),
      this.slider('ring hold', 0, (v) => this.host.audio.setRingHold(v, v > 0 ? 1 : 0, this.bed.pan)),
      this.slider('pan (left ↔ right)', 0.5, (v) => {
        this.bed.pan = v * 2 - 1;
      }),
    );

    // The voices of whichever bed is selected, and only those: a button that
    // plays a whale while the orbit bed is up is a button that lies about what
    // the game does. `BED_SOUNDS` is keyed by bed for that reason.
    out.push(el('div', 'slowblue-admin-group', `BED VOICES · ${this.bedName()}`));
    for (const s of BED_SOUNDS[this.bed.key]) {
      out.push(this.soundButton(s.label, s.track, () => this.host.audio.preview(s.voice)));
    }

    out.push(el('div', 'slowblue-admin-group', 'EVENTS'));
    for (const s of EVENT_SOUNDS) {
      out.push(this.soundButton(s.label, s.track, () => s.play(this.host.audio, this.bed.pan)));
    }

    out.push(el('div', 'slowblue-admin-group', 'ACT ENDINGS'));
    for (const s of ENDING_SOUNDS) {
      out.push(this.soundButton(s.label, s.track, () => s.play(this.host.audio, this.bed.pan)));
    }
    return out;
  }

  /** Pushes the panel's own bed at the engine. Only the sound tab ever calls it. */
  private pushBed(): void {
    // The brook is the one bed that reads metres as well as the arc, and 400 m is
    // where the stream is fastest - see `Riffle.ts`. Everywhere else it is ignored.
    this.host.audio.setBed(this.bed.key, this.bed.arc, this.bed.key === 'brook' ? -400 * (1 - this.bed.arc) : 0);
  }

  private bedName(): string {
    return BEDS[this.bed.key].name.toUpperCase();
  }

  private soundButton(label: string, track: AudioTrackKey, play: () => void): HTMLElement {
    const audible = this.host.audible(track);
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'slowblue-admin-row compact sound';
    b.classList.toggle('muted', !audible);
    b.append(
      el('span', 'slowblue-admin-name', label),
      el('span', 'slowblue-admin-meta', audible ? track : `${track} · muted`),
    );
    b.addEventListener('click', () => {
      // Every browser wants a gesture before the first sound, and Safari wants one
      // again after a tab switch. This click is one; wait for it rather than
      // firing into a context that is still resuming.
      void this.host.audio.unlock().then((ready) => {
        if (ready) {
          this.pushBed();
          play();
        }
      });
    });
    return b;
  }

  private slider(label: string, value: number, onInput: (v: number) => void): HTMLElement {
    const row = el('label', 'slowblue-admin-slider');
    const name = el('span', '', label);
    const input = document.createElement('input');
    input.type = 'range';
    input.min = '0';
    input.max = '100';
    input.step = '1';
    input.value = String(Math.round(value * 100));
    const out = el('span', 'slowblue-admin-val', input.value);
    input.addEventListener('input', () => {
      out.textContent = input.value;
      onInput(Number(input.value) / 100);
    });
    row.append(name, input, out);
    return row;
  }
}

/** "6000 m deep" / "11000 m high". `depthMeters` is negative above the sea. */
function altitudeLabel(level: Level): string {
  const m = level.depthMeters;
  if (m > 0) return `${m} m deep`;
  if (m < 0) return `${-m} m high`;
  return 'surface';
}

/** What a station is made of, in one line: sections, rings, columns, hunters. */
function summarise(level: Level): string {
  let rings = 0;
  let required = 0;
  let hunters = 0;
  for (const s of level.sections) {
    for (const r of s.rings ?? []) {
      rings++;
      if (r.required === true) required++;
    }
    if (s.kind === 'predator' || s.kind === 'raptor') hunters += s.hunters.length;
  }
  const parts = [count(level.sections.length, 'section'), count(rings, 'ring')];
  if (required > 0) parts.push(`${required} mandatory`);
  if (hunters > 0) parts.push(count(hunters, 'hunter'));
  return parts.join(' · ');
}

/** What one section is carrying. Empty for a section that is only its own geometry. */
function badges(spec: SectionSpec): string[] {
  const out: string[] = [];
  const rings = spec.rings ?? [];
  if (rings.length > 0) {
    const required = rings.filter((r) => r.required === true).length;
    out.push(required > 0 ? `${count(rings.length, 'ring')} (${required} mandatory)` : count(rings.length, 'ring'));
  }
  if (spec.kind === 'predator' || spec.kind === 'raptor') {
    out.push(count(spec.hunters.length, 'hunter'));
  }
  if (spec.kind === 'vortex' || spec.kind === 'rotor') out.push(`vortex ${spec.strength}`);
  // The three shapes that are not apertures, so the panel says what they are
  // rather than leaving them as a name with a ring count after it: a street is a
  // length, a drape is a count of strands, a bloom is a width.
  if (spec.kind === 'street') out.push(`length ${spec.length ?? 660} px`);
  if (spec.kind === 'drape') out.push(count(spec.strands.length, 'strand'));
  if (spec.kind === 'bloom') out.push(`width ${Math.round(spec.radius * 100)}%`);
  return out;
}

/** "1 ring" / "3 rings". Every label here is a count, and "1 rings" reads like a typo. */
function count(n: number, noun: string): string {
  return `${n} ${noun}${n === 1 ? '' : 's'}`;
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
