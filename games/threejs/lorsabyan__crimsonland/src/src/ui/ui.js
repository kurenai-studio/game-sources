// All DOM lives here. The game calls in with events; `update` writes the HUD once per frame,
// touching an element only when its value changed.
import { TITLE, REPO, IS_TOUCH } from '../config.js';
import { BIOME_LIST } from '../data/biomes.js';
import { MISSIONS } from '../data/missions.js';
import { BONUSES } from '../data/bonuses.js';
import { PERKS } from '../data/perks.js';
import { WEAPONS, WEAPON_LIST } from '../data/weapons.js';
import { REWARDS, SOURCE, unlocked } from '../data/unlocks.js';
import { saveProfile } from '../core/save.js';
import { fmtTime, len, clamp } from '../core/util.js';

const $ = (id) => document.getElementById(id);
const TIMER_LABEL = { shield: ['Shield', '#7fd3ff'], speed: ['Speed', '#7fff8a'], fire: ['Fire rounds', '#ff7a3a'], xp2: ['Double XP', '#ffb8ff'], reflex: ['Reflex', '#f2e680'], overdrive: ['Overdrive', '#fff27f'], deathClock: ['Borrowed time', '#ff4a4a'] };
const TIER_NAME = { 1: 'Dust Basin', 2: 'Sunken Fen', 3: 'Cinder Flats', 4: 'White Silence' };
const FLOAT_POOL = 24;
const MARKERS = 6;
const LABELS = 26;

export class UI {
  constructor({ input, audio, profile, stage }) {
    Object.assign(this, { input, audio, profile, stage });
    this.hud = $('hud'); this.menu = $('menu'); this.perks = $('perks'); this.pause = $('pause'); this.over = $('over');
    this.cross = $('cross'); this.touch = $('touch');
    this.last = {};
    this.buildHud();
    this.buildFloats();
    this.cards = [];
    input.onSlot = (i) => this.cards[i]?.click();
    input.onPointer = (x, y) => { this.cross.style.transform = `translate(${x}px,${y}px)`; };
    this.buildTouch();
  }

  bindGame(game) { this.game = game; }

  // HUD ----------------------------------------------------------------------------------------
  buildHud() {
    this.hud.innerHTML = `
      <div class="h-top">
        <div class="vitals">
          <div class="hp-row"><span class="hp-num" data-k="hp">100</span><span class="hp-max" data-k="maxhp">/100</span></div>
          <div class="bar" data-k="hpbar"><i></i></div>
          <div class="bar xp"><i data-k="xpbar"></i></div>
          <div class="lvl" data-k="lvl"></div>
        </div>
        <div class="tally"><div class="score" data-k="score">0</div><div class="meta" data-k="meta"></div></div>
      </div>
      <div class="bossbar" data-k="boss" hidden><b data-k="bossname"></b><div class="bar"><i data-k="bossfill"></i></div></div>
      <div class="toasts" data-k="toasts"></div>
      <button class="perk-prompt" data-k="prompt" hidden></button>
      <div class="typed" data-k="typed" hidden></div>
      <div class="h-bot">
        <div class="wname" data-k="wname"></div>
        <div class="walt" data-k="walt"></div>
        <div class="ammo"><span class="ammo-num" data-k="ammo"></span><div class="ammo-bar" data-k="ammobar"><i data-k="ammofill"></i></div></div>
      </div>
      <div class="timers" data-k="timers"></div>`;
    this.el = {};
    this.hud.querySelectorAll('[data-k]').forEach((n) => { this.el[n.dataset.k] = n; });
    this.el.hpfill = this.el.hpbar.firstElementChild;
    this.el.prompt.addEventListener('click', () => this.game.openPerks());
    this.timerEls = {};
    for (const [k, [label, color]] of Object.entries(TIMER_LABEL)) {
      const d = document.createElement('div');
      d.className = 'timer'; d.style.color = color; d.hidden = true;
      d.innerHTML = `<span>${label}</span><em></em>`;
      this.el.timers.append(d);
      this.timerEls[k] = { root: d, bar: d.lastElementChild };
    }
  }

  buildFloats() {
    this.floats = [];
    this.floatI = 0;
    const box = $('floats');
    for (let i = 0; i < FLOAT_POOL; i++) { const s = document.createElement('span'); s.className = 'float'; s.hidden = true; box.append(s); this.floats.push(s); }
    this.labels = [];
    for (let i = 0; i < LABELS; i++) {
      const w = document.createElement('span');
      w.className = 'word'; w.hidden = true;
      w.innerHTML = '<b></b><em></em>';
      box.append(w);
      this.labels.push(w);
    }
    this.marks = [];
    for (let i = 0; i < MARKERS; i++) { const m = document.createElement('i'); m.className = 'marker'; m.hidden = true; box.append(m); this.marks.push(m); }
  }

  set(key, value, apply) { if (this.last[key] !== value) { this.last[key] = value; apply(value); } }
  text(key, value) { this.set(key, value, (v) => { this.el[key].textContent = v; }); }

  update(g) {
    const p = g.player;
    if (g.attract) return;
    const ammoFrac = p.reloading ? 1 - p.reloadT / p.reloadLen : p.ammo / p.clip;
    this.text('hp', Math.max(0, Math.ceil(p.hp)));
    this.text('maxhp', `/${p.maxHp}`);
    this.el.hpfill.style.transform = `scaleX(${clamp(p.hp / p.maxHp, 0, 1)})`;
    this.set('low', p.hp / p.maxHp < 0.3, (v) => this.el.hpbar.classList.toggle('low', v));
    const xp = !g.hasPerks ? 0 : (g.score - g.levelFrom) / (g.levelTo - g.levelFrom);
    this.el.xpbar.style.transform = `scaleX(${clamp(xp, 0, 1)})`;
    this.text('lvl', g.hasPerks ? `LEVEL ${g.level}` : g.mode.toUpperCase());
    this.text('score', g.score.toLocaleString('en-US'));
    const wave = g.mode === 'mission' ? `  WAVE ${g.director.wave}/${g.mission.waves.length}` : '';
    this.text('meta', `${fmtTime(g.time)}  ${g.stats.kills} KILLS${wave}`);
    const typing = g.mode === 'typing';
    this.text('wname', typing ? 'Keyboard' : p.weapon.name);
    this.text('walt', p.alt ? `Q  ${p.alt.weapon.name}` : '');
    this.text('ammo', typing ? `${g.typing.wpm} wpm` : p.reloading ? '...' : String(p.ammo));
    this.el.ammofill.style.transform = `scaleX(${typing ? 1 : clamp(ammoFrac, 0, 1)})`;
    this.set('reloading', p.reloading, (v) => this.el.ammobar.classList.toggle('reload', v));
    this.set('prompt', g.pendingPerks, (n) => {
      this.el.prompt.hidden = n <= 0 || !g.hasPerks;
      this.el.prompt.innerHTML = `Perk ready${n > 1 ? ` x${n}` : ''}${IS_TOUCH ? '' : '<kbd>E</kbd>'}`;
    });
    for (const k in this.timerEls) {
      const t = g.timers[k] ?? 0, e = this.timerEls[k];
      if (t > 0) { e.root.hidden = false; e.bar.style.transform = `scaleX(${t / (g.timerMax[k] || 1)})`; } else if (!e.root.hidden) e.root.hidden = true;
    }
    const b = g.horde.bossId;
    if (b >= 0) this.el.bossfill.style.transform = `scaleX(${clamp(g.horde.hp[b] / g.horde.maxHp[b], 0, 1)})`;
    this.crosshair(g, p, ammoFrac);
    this.markers(g);
    this.wordLabels(g, typing);
  }

  // Type to Kill: a word over each creature, with the typed part lit.
  wordLabels(g, typing) {
    this.set('typing', typing, (on) => {
      this.el.typed.hidden = !on;
      this.cross.hidden = on || IS_TOUCH;
      this.el.ammobar.hidden = on;
    });
    let n = 0;
    if (typing) {
      const t = g.typing, h = g.horde;
      for (const [i, word] of t.words) {
        if (n >= LABELS) break;
        const el = this.labels[n++];
        const p = this.stage.project(h.x[i], 2.3 * h.scale[i], h.z[i]);
        el.hidden = false;
        el.style.transform = `translate(${p.x}px,${p.y}px) translate(-50%,-100%)`;
        const lit = word.startsWith(t.buffer) ? t.buffer.length : 0;
        if (el.dataset.w !== word || Number(el.dataset.l) !== lit) {
          el.dataset.w = word; el.dataset.l = lit;
          el.firstChild.textContent = word.slice(0, lit);
          el.lastChild.textContent = word.slice(lit);
        }
      }
      this.text('typed', t.buffer || '\u00a0');
      this.set('misfire', t.misfire > 0, (v) => this.el.typed.classList.toggle('miss', v));
    }
    for (; n < LABELS; n++) { if (this.labels[n].hidden) break; this.labels[n].hidden = true; }
  }

  // Edge arrows for what the player must reach: hives, bosses, and the last stragglers of a mission.
  markers(g) {
    const h = g.horde, W = innerWidth, H = innerHeight, cx = W / 2, cy = H / 2;
    const few = g.mode === 'mission' && g.director.wave >= g.mission.waves.length && h.alive <= 6;
    let n = 0;
    for (let k = 0; k < h.count && n < MARKERS; k++) {
      const i = h.list[k];
      if (h.dead[i] > 0) continue;
      const d = h.defs[h.type[i]];
      if (!few && !d.boss && d.ai !== 'nest') continue;
      const p = this.stage.project(h.x[i], 1, h.z[i]);
      if (p.x > 0 && p.x < W && p.y > 0 && p.y < H) continue;
      const dx = p.x - cx, dy = p.y - cy, s = Math.min((cx - 40) / Math.abs(dx || 1), (cy - 40) / Math.abs(dy || 1));
      const m = this.marks[n++];
      m.hidden = false;
      m.style.transform = `translate(${cx + dx * s}px,${cy + dy * s}px) rotate(${Math.atan2(dy, dx)}rad)`;
    }
    for (; n < MARKERS; n++) { if (this.marks[n].hidden) break; this.marks[n].hidden = true; }
  }

  crosshair(g, p, ammoFrac) {
    if (this.input.mode !== 'mouse') return;
    const dist = len(this.input.aimX - p.x, this.input.aimZ - p.z);
    const angle = (p.weapon.spread + p.spread) * p.mods.spread;
    const pxPerUnit = innerHeight / (this.stage.viewHalfH * 2);
    const r = clamp(dist * Math.tan(angle) * pxPerUnit, 9, 58);
    const ring = this.crossRing ?? (this.crossRing = this.cross.querySelector('.ring'));
    const rel = this.crossReload ?? (this.crossReload = this.cross.querySelector('.reload'));
    ring.setAttribute('r', r.toFixed(1));
    rel.setAttribute('r', r.toFixed(1));
    rel.style.strokeDashoffset = p.reloading ? String(100 - ammoFrac * 100) : '100';
  }

  toast(text, color = '#efe6d4') {
    if (this.game?.attract) return;
    const t = document.createElement('div');
    t.className = 'toast'; t.textContent = text; t.style.color = color;
    this.el.toasts.append(t);
    while (this.el.toasts.children.length > 3) this.el.toasts.firstChild.remove();
    t.addEventListener('animationend', () => t.remove());
  }

  floatText(x, z, text, color) {
    if (this.game?.attract) return;
    const s = this.floats[this.floatI = (this.floatI + 1) % FLOAT_POOL], p = this.stage.project(x, 1.6, z);
    s.hidden = false; s.textContent = text; s.style.color = color;
    s.style.transform = `translate(${p.x - 14}px,${p.y}px)`;
    s.style.animation = 'none'; void s.offsetWidth; s.style.animation = '';
  }

  boss(name) {
    if (this.game?.attract) return;
    this.el.boss.hidden = !name;
    if (name) this.el.bossname.textContent = name;
  }

  setPlaying(on) {
    document.body.classList.toggle('playing', on);
    this.hud.hidden = !on;
    this.cross.hidden = !on || IS_TOUCH;
    this.touch.hidden = !on || !IS_TOUCH;
  }

  // Perks --------------------------------------------------------------------------------------
  showPerks(list, level) {
    this.perks.hidden = false;
    this.perks.innerHTML = `<div class="panel"><div class="eyebrow">Level ${level}</div><h2>Choose a perk</h2><div class="cards"></div></div>`;
    const box = this.perks.querySelector('.cards');
    this.cards = list.map((perk, i) => {
      const b = document.createElement('button');
      b.className = `card t-${perk.tag}`;
      b.innerHTML = `<kbd>${i + 1}</kbd><small>${perk.tag}</small><b></b><span></span>`;
      b.querySelector('b').textContent = perk.name;
      b.querySelector('span').textContent = perk.desc;
      b.addEventListener('click', () => this.game.choosePerk(perk));
      box.append(b);
      return b;
    });
    document.body.classList.remove('playing');
    this.audio.duck(true);
  }

  hidePerks() {
    this.perks.hidden = true;
    this.cards = [];
    document.body.classList.add('playing');
    this.audio.duck(false);
  }

  showPause(on) {
    this.pause.hidden = !on;
    document.body.classList.toggle('playing', !on);
    if (!on) return;
    const g = this.game;
    const held = PERKS.filter((p) => g.owned.has(p.id));
    const rows = held.map((p) => {
      const n = g.owned.get(p.id);
      return `<div class="t-${p.tag}"><b>${p.name}${n > 1 ? ` x${n}` : ''}</b><span>${p.desc}</span></div>`;
    }).join('');
    this.pause.innerHTML = `<div class="panel"><div class="eyebrow">${held.length ? `${held.length} perk${held.length === 1 ? '' : 's'} held` : g.mode}</div><h2>Paused</h2>${rows ? `<div class="held">${rows}</div>` : ''}<div class="actions"><button class="btn" data-a="resume">Resume</button><button class="btn alt" data-a="menu">Abandon run</button></div></div>`;
    this.pause.querySelector('[data-a=resume]').addEventListener('click', () => g.togglePause());
    this.pause.querySelector('[data-a=menu]').addEventListener('click', () => { this.pause.hidden = true; this.audio.duck(false); this.showMenu(); });
  }

  // End of run -----------------------------------------------------------------------------------
  gameOver(g, won) {
    const s = g.stats, acc = s.fired ? Math.round((Math.min(s.hit, s.fired) / s.fired) * 100) : 0;
    const P = this.profile;
    if (!won && !g.autoplay && g.mode !== 'mission') {
      (P.bests[g.mode] ??= []).push({ score: g.score, time: Math.round(g.time), level: g.level, kills: s.kills });
      P.bests[g.mode].sort((a, b) => b.score - a.score);
      P.bests[g.mode].length = Math.min(5, P.bests[g.mode].length);
    }
    let next = null, earned = '';
    if (won && g.mission && !g.autoplay) {
      if (P.missions[g.mission.id] === undefined) earned = this.earned(g.mission.id);
      P.missions[g.mission.id] = Math.min(P.missions[g.mission.id] ?? 1e9, Math.round(g.time));
    }
    if (won && g.mission) next = MISSIONS[MISSIONS.indexOf(g.mission) + 1] ?? null;
    saveProfile(P);
    const rows = g.mode === 'typing'
      ? [['Score', g.score.toLocaleString('en-US')], ['Time', fmtTime(g.time)], ['Kills', s.kills], ['Speed', `${g.typing.wpm} wpm`], ['Typos', g.typing.errors]]
      : [['Score', g.score.toLocaleString('en-US')], ['Time', fmtTime(g.time)], ['Kills', s.kills], ['Level', g.level], ['Accuracy', `${acc}%`]];
    this.over.hidden = false;
    this.over.innerHTML = `<div class="panel"><div class="eyebrow">${g.mission ? g.mission.name : g.mode}</div>
      <h2>${won ? 'Area secured' : 'Overrun'}</h2>
      <div class="stats">${rows.map(([k, v]) => `<div class="stat"><small>${k}</small><b>${v}</b></div>`).join('')}</div>
      ${earned}
      <div class="actions">${next ? '<button class="btn" data-a="next">Next mission</button>' : ''}<button class="btn${next ? ' alt' : ''}" data-a="again">Again</button><button class="btn alt" data-a="menu">Menu</button></div></div>`;
    document.body.classList.remove('playing');
    this.cross.hidden = true;
    const on = (a, fn) => this.over.querySelector(`[data-a=${a}]`)?.addEventListener('click', fn);
    on('again', () => this.begin(g.mode, g.mission));
    on('menu', () => this.showMenu());
    on('next', () => this.begin('mission', next));
  }

  // What a first clear hands over, for the results screen.
  earned(id) {
    const r = REWARDS[id];
    if (!r) return '';
    const names = r.perks.map((p) => PERKS.find((x) => x.id === p).name);
    return `<div class="earned"><span class="eyebrow">Unlocked</span>${r.weapon ? `<b>${WEAPONS[r.weapon].name}</b>` : ''}${names.map((n) => `<b class="perk">${n}</b>`).join('')}</div>`;
  }

  // Menus ----------------------------------------------------------------------------------------
  begin(mode, mission = null) {
    this.audio.unlock();
    this.audio.play('ui');
    this.menu.hidden = true; this.over.hidden = true; this.pause.hidden = true; this.perks.hidden = true;
    this.setPlaying(true);
    this.boss(null);
    this.game.start({ mode, mission, biome: this.profile.biome, attract: false });
    this.boss(null);
    this.last = {};
  }

  showMenu(screen = 'main') {
    const g = this.game;
    this.over.hidden = true; this.perks.hidden = true; this.pause.hidden = true;
    this.setPlaying(false);
    for (const m of [...this.marks, ...this.labels]) m.hidden = true;
    if (!g.attract) g.start({ mode: 'survival', biome: this.profile.biome, attract: true });
    this.menu.hidden = false;
    this[`screen_${screen}`]();
  }

  head() {
    const [a, b] = [TITLE.slice(0, 7), TITLE.slice(7)];
    return `<h1 class="title">${a}<br><i>${b}</i></h1>`;
  }

  screen_main() {
    const p = this.profile;
    const best = (k) => p.bests[k]?.[0]?.score;
    const done = Object.keys(p.missions).length;
    this.menu.innerHTML = `
      <div class="m-col">
        ${this.head()}
        <p class="tag">Hold the line. The ground keeps score.</p>
        <nav class="m-nav">
          <button class="m-item" data-go="survival">Survival<small>${best('survival') ? `best ${best('survival').toLocaleString('en-US')}` : 'endless horde'}</small></button>
          <button class="m-item" data-go="rush">Rush<small>${best('rush') ? `best ${best('rush').toLocaleString('en-US')}` : 'one rifle, no perks'}</small></button>
          ${IS_TOUCH ? '' : `<button class="m-item" data-go="typing">Type to kill<small>${best('typing') ? `best ${best('typing').toLocaleString('en-US')}` : 'your keyboard is the gun'}</small></button>`}
          <button class="m-item" data-screen="missions">Missions<small>${done}/${MISSIONS.length} cleared</small></button>
          <button class="m-item" data-screen="armory">Armory<small>${this.progress()}</small></button>
          <button class="m-item" data-screen="field">Field manual</button>
          <button class="m-item" data-screen="options">Options</button>
        </nav>
        <div class="m-row"><span class="m-label">Terrain</span><div class="chips" data-biomes></div></div>
        <p class="m-foot">Unofficial fan project. <a href="${REPO}" target="_blank" rel="noopener">Source on GitHub</a></p>
      </div>
      <aside class="m-side"><span class="m-label">Survival records</span><div class="board">${this.board(p.bests.survival)}</div></aside>`;
    const box = this.menu.querySelector('[data-biomes]');
    for (const b of BIOME_LIST) {
      const c = document.createElement('button');
      c.className = 'chip'; c.textContent = b.name; c.title = b.blurb;
      c.setAttribute('aria-pressed', String(p.biome === b.id));
      c.addEventListener('click', () => {
        p.biome = b.id; saveProfile(p);
        box.querySelectorAll('.chip').forEach((n) => n.setAttribute('aria-pressed', String(n === c)));
        this.audio.unlock();
        this.game.start({ mode: 'survival', biome: b.id, attract: true });
      });
      box.append(c);
    }
    this.wire();
  }

  progress() {
    const u = unlocked(this.profile);
    return `${u.weapons.size}/${WEAPON_LIST.length} weapons, ${u.perks.size}/${PERKS.length} perks`;
  }

  board(list) {
    if (!list?.length) return '<p>No runs yet. Everyone starts with a pistol.</p>';
    return list.map((r, i) => `<div><span>${i + 1}. ${fmtTime(r.time)}, L${r.level}</span><b>${r.score.toLocaleString('en-US')}</b></div>`).join('');
  }

  screen_missions() {
    const p = this.profile;
    const unlocked = (i) => i === 0 || p.missions[MISSIONS[i - 1].id] !== undefined;
    const tiers = [1, 2, 3, 4].map((t) => {
      const rows = MISSIONS.map((m, i) => ({ m, i })).filter(({ m }) => m.id[0] === String(t)).map(({ m, i }) => {
        const best = p.missions[m.id], open = unlocked(i);
        const prize = REWARDS[m.id]?.weapon ? `Unlocks ${WEAPONS[REWARDS[m.id].weapon].name}` : 'Unlocks perks';
        return `<button class="mission${best !== undefined ? ' done' : ''}" data-m="${i}" ${open ? '' : 'disabled'} title="${m.brief}"><b>${m.name}</b><span>${best !== undefined ? `cleared ${fmtTime(best)}` : open ? prize : 'locked'}</span></button>`;
      }).join('');
      return `<div><span class="m-label">${TIER_NAME[t]}</span><div class="tier-row">${rows}</div></div>`;
    }).join('');
    this.menu.innerHTML = `<div class="m-col" style="max-width:none"><div class="eyebrow">Campaign</div><h1 class="title" style="font-size:clamp(54px,8vw,104px)">Missions</h1><div class="tiers">${tiers}</div><button class="m-item back" data-screen="main" style="margin-top:14px">Back</button></div>`;
    this.menu.querySelectorAll('[data-m]').forEach((b) => b.addEventListener('click', () => this.begin('mission', MISSIONS[Number(b.dataset.m)])));
    this.wire(true);
  }

  screen_armory() {
    const u = unlocked(this.profile);
    const lockedNote = (id) => `Clear mission ${SOURCE[id]}`;
    const guns = WEAPON_LIST.map((w) => {
      const open = u.weapons.has(w.id), dps = Math.round(w.dmg * (w.pellets ?? 1) * w.rate);
      return `<div class="gear${open ? '' : ' locked'}"><b>${open ? w.name : 'Locked'}</b><span>${open ? `${dps} dps, ${w.clip} rounds` : lockedNote(w.id)}</span></div>`;
    }).join('');
    const perks = PERKS.map((p) => {
      const open = u.perks.has(p.id);
      return `<div class="gear t-${p.tag}${open ? '' : ' locked'}"><b>${open ? p.name : 'Locked'}</b><span>${open ? p.desc : lockedNote(p.id)}</span></div>`;
    }).join('');
    this.menu.innerHTML = `<div class="m-col" style="max-width:none"><div class="eyebrow">${this.progress()}</div><h1 class="title" style="font-size:clamp(54px,8vw,104px)">Armory</h1>
      <div class="tiers"><div><span class="m-label">Weapons</span><div class="tier-row">${guns}</div></div><div><span class="m-label">Perks</span><div class="tier-row wide">${perks}</div></div></div>
      <button class="m-item back" data-screen="main" style="margin-top:14px">Back</button></div>`;
    this.wire(true);
  }

  screen_field() {
    const keys = IS_TOUCH
      ? [['Left thumb', 'Move'], ['Right thumb', 'Aim and fire'], ['Perk button', 'Spend a level-up']]
      : [['WASD', 'Move'], ['Mouse', 'Aim'], ['Left click', 'Fire, hold for auto'], ['R', 'Reload'], ['E or Space', 'Choose a perk when one is ready'], ['1 to 6', 'Pick a perk card'], ['Q or right click', 'Swap weapons (with Second Holster)'], ['Esc', 'Pause']];
    const bonuses = Object.values(BONUSES).filter((b) => b.id !== 'points').map((b) => b.name).join(', ');
    this.menu.innerHTML = `<div class="m-col"><div class="eyebrow">Field manual</div><h1 class="title" style="font-size:clamp(54px,8vw,104px)">Orders</h1>
      <dl class="keys">${keys.map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`).join('')}</dl>
      <p class="prose">Kills earn experience. Each level gives you a perk, and perks are what keep you alive. Weapons drop from the horde and replace what you carry. Pick up everything you can: ${bonuses}.</p>
      <p class="prose">A gamepad also works: left stick to move, right stick to aim and fire, A for perks, X to reload.</p>
      ${IS_TOUCH ? '' : '<p class="prose">Type to Kill needs no mouse: type the word over a creature to kill it, Backspace to correct.</p>'}
      <button class="m-item back" data-screen="main" style="margin-top:auto">Back</button></div>`;
    this.wire();
  }

  screen_options() {
    const p = this.profile;
    this.menu.innerHTML = `<div class="m-col"><div class="eyebrow">Options</div><h1 class="title" style="font-size:clamp(54px,8vw,104px)">Setup</h1>
      <label class="opt">Sound<input type="range" min="0" max="1" step="0.05" value="${p.volume}" data-o="volume"></label>
      <label class="opt">Music<input type="range" min="0" max="1" step="0.05" value="${p.music}" data-o="music"></label>
      <div class="m-row"><span class="m-label">Screen shake</span><div class="chips" data-shake></div></div>
      <div class="m-row"><span class="m-label">Unlock everything</span><div class="chips" data-all></div></div>
      <div class="m-row"><span class="m-label">Graphics (reloads the game)</span><div class="chips" data-q></div></div>
      <button class="m-item back" data-screen="main" style="margin-top:auto">Back</button></div>`;
    this.menu.querySelector('[data-o=volume]').addEventListener('input', (e) => { p.volume = Number(e.target.value); this.audio.setVolume(p.volume); saveProfile(p); });
    this.menu.querySelector('[data-o=music]').addEventListener('input', (e) => { p.music = Number(e.target.value); this.audio.setMusic(p.music); saveProfile(p); });
    const sh = this.menu.querySelector('[data-shake]');
    for (const [label, on] of [['On', true], ['Off', false]]) {
      const c = document.createElement('button');
      c.className = 'chip'; c.textContent = label;
      c.setAttribute('aria-pressed', String(p.shake === on));
      c.addEventListener('click', () => {
        p.shake = on; saveProfile(p);
        this.stage.shakeScale = on ? 1 : 0;
        sh.querySelectorAll('.chip').forEach((n) => n.setAttribute('aria-pressed', String(n === c)));
      });
      sh.append(c);
    }
    const all = this.menu.querySelector('[data-all]');
    for (const [label, on] of [['Off', false], ['On', true]]) {
      const c = document.createElement('button');
      c.className = 'chip'; c.textContent = label;
      c.setAttribute('aria-pressed', String(!!p.unlockAll === on));
      c.addEventListener('click', () => {
        p.unlockAll = on; saveProfile(p);
        all.querySelectorAll('.chip').forEach((n) => n.setAttribute('aria-pressed', String(n === c)));
      });
      all.append(c);
    }
    const q = this.menu.querySelector('[data-q]');
    for (const name of ['high', 'medium', 'low']) {
      const c = document.createElement('button');
      c.className = 'chip'; c.textContent = name;
      c.setAttribute('aria-pressed', String(this.stage.tier.name === name));
      c.addEventListener('click', () => { p.quality = name; saveProfile(p); location.reload(); });
      q.append(c);
    }
    this.wire();
  }

  wire(dense = false) {
    this.menu.classList.toggle('dense', dense);
    this.menu.querySelectorAll('[data-screen]').forEach((b) => b.addEventListener('click', () => { this.audio.unlock(); this.audio.play('ui'); this[`screen_${b.dataset.screen}`](); }));
    this.menu.querySelectorAll('[data-go]').forEach((b) => b.addEventListener('click', () => this.begin(b.dataset.go)));
  }

  // Touch ----------------------------------------------------------------------------------------
  buildTouch() {
    const t = this.touch;
    t.innerHTML = '<div class="stick" hidden><i></i></div><div class="stick" hidden><i></i></div><button class="t-btn" aria-label="Pause">II</button>';
    const [left, right] = t.querySelectorAll('.stick');
    t.querySelector('.t-btn').addEventListener('click', () => this.game.togglePause());
    const active = new Map();
    const R = 56;
    const place = (s, x, y) => { s.style.left = `${x}px`; s.style.top = `${y}px`; };
    t.addEventListener('pointerdown', (e) => {
      if (e.target.closest('button')) return;
      const which = e.clientX < innerWidth / 2 ? 'move' : 'aim', stick = which === 'move' ? left : right;
      active.set(e.pointerId, { which, stick, ox: e.clientX, oy: e.clientY });
      stick.hidden = false;
      place(stick, e.clientX, e.clientY);
      stick.firstElementChild.style.transform = '';
      t.setPointerCapture(e.pointerId);
      this.audio.unlock();
      this.input.setStick(which, 0, 0, true);
    });
    t.addEventListener('pointermove', (e) => {
      const a = active.get(e.pointerId);
      if (!a) return;
      let dx = e.clientX - a.ox, dy = e.clientY - a.oy;
      const l = Math.hypot(dx, dy);
      if (l > R) { dx = (dx / l) * R; dy = (dy / l) * R; }
      a.stick.firstElementChild.style.transform = `translate(${dx}px,${dy}px)`;
      this.input.setStick(a.which, dx / R, dy / R, true);
    });
    const end = (e) => {
      const a = active.get(e.pointerId);
      if (!a) return;
      active.delete(e.pointerId);
      a.stick.hidden = true;
      this.input.setStick(a.which, 0, 0, false);
    };
    t.addEventListener('pointerup', end);
    t.addEventListener('pointercancel', end);
  }
}
