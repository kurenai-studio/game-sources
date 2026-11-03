import { gameState } from '../core/GameState.js';
import { eventBus, Events } from '../core/EventBus.js';
import { WEAPONS, PLAYER_CONFIG } from '../core/Constants.js';
import { CROSSHAIR_PX_PER_RAD, CROSSHAIR_RETURN } from '../gameplay/Gunplay.js';
import { perf } from '../core/Perf.js';

const SLOT_ORDER = ['rifle', 'sniper', 'shotgun', 'pistol'];

export class Hud {
  constructor(root) {
    this.root = root;
    root.innerHTML = `
      <div class="hud-vignette"></div>
      <div class="hud-scope"><div class="lens"></div><i class="h"></i><i class="v"></i><span class="mag-x"></span></div>
      <div class="hud-compass"><canvas width="840" height="56"></canvas></div>
      <div class="hud-obj"><small>Objective</small><span>Clear Ashline block</span></div>
      <div class="hud-clear" hidden>
        <i class="hud-clear-rule"></i>
        <strong class="hud-clear-title">Ashline block cleared</strong>
        <i class="hud-clear-rule"></i>
      </div>
      <div class="hud-radar"><canvas width="236" height="236"></canvas></div>
      <div class="hud-dmg"><canvas width="320" height="320"></canvas></div>
      <div class="hud-cross"><i class="n"></i><i class="e"></i><i class="s"></i><i class="w"></i></div>
      <div class="hud-hitmark"><i></i><i></i><i></i><i></i></div>
      <div class="hud-feed"></div>
      <div class="hud-stance">Standing</div>
      <div class="hud-prompt" hidden></div>
      <div class="hud-sens" hidden></div>
      <div class="hud-health">
        <div class="bars"><div class="armor"><i></i></div><div class="bar"><i></i></div></div>
        <span class="hp">100</span>
      </div>
      <div class="hud-ammo">
        <div class="stack"><span class="mag">30</span> <span class="res">/ 90</span></div>
        <div class="wep">${WEAPONS.rifle.name}</div>
        <div class="slots"></div>
      </div>
    `;
    this.compass = root.querySelector('.hud-compass canvas');
    this.radar = root.querySelector('.hud-radar canvas');
    this.dmg = root.querySelector('.hud-dmg canvas');
    this.mag = root.querySelector('.mag');
    this.res = root.querySelector('.res');
    this.obj = root.querySelector('.hud-obj span');
    this.clearEl = root.querySelector('.hud-clear');
    this.feed = root.querySelector('.hud-feed');
    this.hitmark = root.querySelector('.hud-hitmark');
    this.vig = root.querySelector('.hud-vignette');
    this.cross = root.querySelector('.hud-cross');
    this.scope = root.querySelector('.hud-scope');
    this.scopeMag = root.querySelector('.hud-scope .mag-x');
    this.stance = root.querySelector('.hud-stance');
    this.prompt = root.querySelector('.hud-prompt');
    this.sens = root.querySelector('.hud-sens');
    this.hp = root.querySelector('.hud-health .hp');
    this.hpBar = root.querySelector('.hud-health .bar i');
    this.armorBar = root.querySelector('.hud-health .armor i');
    this.wep = root.querySelector('.hud-ammo .wep');
    this.slots = root.querySelector('.hud-ammo .slots');
    this._hitT = 0;
    this._hitHead = false;
    this._feeds = [];
    this._gap = 3;
    this._hpPulse = 0;
    this._arcs = [];          // directional damage: {from, t}, max 4
    this._slotsHtml = '';
    this._wepName = '';
    this._radarT = 0;
    /* Dirty-check caches (autopsy fix 10): the HUD was writing text/style
     * every frame — continuous style/layout invalidation. */
    this._magTxt = '';
    this._resTxt = '';
    this._stanceTxt = '';
    this._hitOp = '';
    this._vigOp = -1;
    this._vigDmg = -1;
    this._feedHtml = '';
    this._hpTxt = '';
    this._ctxCompass = this.compass.getContext('2d');
    this._ctxRadar = this.radar.getContext('2d');
    this._ctxDmg = this.dmg.getContext('2d');
    this._crossOp = '';
    this._gapPx = -1;
    this._scopeOn = null;
    this._scopeMag = '';
    this._promptKey = '';
    this._clearHold = 0;
    this._clearDone = 0;
    this._sensOn = null;
    this._sensTxt = '';
    this._hpLow = null;
    this._hpScale = '';
    this._yawQ = 1e9;
    this._radarKey = '';
    this._radarAcc = 0;
    this._arcsOn = false;
    eventBus.on(Events.ENEMY_HIT, (d) => {
      this._hitT = 1;
      this._hitHead = !!(d?.headshot || d?.killed);
    });
    eventBus.on(Events.ENEMY_DIE, () => this._push('Hostile down'));
    eventBus.on(Events.PLAYER_HIT, (d) => {
      this._hpPulse = 1;
      if (d?.from) {
        if (this._arcs.length >= 4) this._arcs.shift();   // reuse oldest
        this._arcs.push({ from: d.from, t: 0.6 });
      }
    });
    eventBus.on(Events.PICKUP, (d) => {
      if (d?.kind === 'supply') {
        const bits = [];
        if (d.hp) bits.push(`+${Math.round(d.hp)} HP`);
        if (d.armor) bits.push(`+${Math.round(d.armor)} armor`);
        this._push(bits.length ? bits.join(' · ') : 'Supplies');
        return;
      }
      const cfg = WEAPONS[d.id];
      if (cfg) this._push(`Picked up ${cfg.name} — slot ${cfg.slot}`);
    });
    eventBus.on(Events.EXTRACT_READY, () => {
      this.obj.textContent = 'Move to extract';
      this._push('Extract is open');
      this._playClearBanner();
    });
    eventBus.on(Events.GAME_WIN, () => {
      this.obj.textContent = 'Area secure';
      this._hideClearBanner(true);
    });
    eventBus.on(Events.GAME_OVER, () => this._hideClearBanner(true));
    eventBus.on(Events.GAME_RESTART, () => {
      this.obj.textContent = 'Clear Ashline block';
      this._hideClearBanner(true);
    });
    eventBus.on(Events.GAME_START, () => {
      this.obj.textContent = 'Clear Ashline block';
      this._hideClearBanner(true);
      this._push('Supplies marked on your map');
    });
  }

  _playClearBanner() {
    const el = this.clearEl;
    if (!el || this.root.hidden) return;
    this._hideClearBanner(true);
    el.hidden = false;
    void el.offsetWidth;
    el.classList.add('is-in');
    this._clearHold = setTimeout(() => {
      el.classList.add('is-out');
      this._clearDone = setTimeout(() => this._hideClearBanner(true), 420);
    }, 2400);
  }

  _hideClearBanner(immediate = false) {
    clearTimeout(this._clearHold);
    clearTimeout(this._clearDone);
    this._clearHold = 0;
    this._clearDone = 0;
    const el = this.clearEl;
    if (!el) return;
    if (immediate) {
      el.hidden = true;
      el.classList.remove('is-in', 'is-out');
      return;
    }
    el.classList.add('is-out');
    this._clearDone = setTimeout(() => {
      el.hidden = true;
      el.classList.remove('is-in', 'is-out');
    }, 420);
  }

  /* Gap IS the live firing cone: gameState.player.spread (same value
   * Combat._fire uses), mapped at 240 px/rad with e-fold return 20.
   * Hidden while sprinting and while sniper-scoped. */
  _updateCross(dt) {
    const st = gameState.player;
    const cfg = WEAPONS[gameState.activeWeapon] || WEAPONS.rifle;
    const spread = st.spread || cfg.spread.hip;
    const target = 3 + spread * CROSSHAIR_PX_PER_RAD;
    const k = dt > 0 ? 1 - Math.exp(-CROSSHAIR_RETURN * dt) : 1;
    this._gap += (target - this._gap) * k;
    const gapPx = Math.round(this._gap);
    if (gapPx !== this._gapPx) {
      this._gapPx = gapPx;
      this.cross.style.setProperty('--gap', `${gapPx}px`);
    }
    const op = (st.sprinting || st.scoped) ? '0' : '1';
    if (op !== this._crossOp) {
      this._crossOp = op;
      this.cross.style.opacity = op;
    }
  }

  _push(text) {
    this._feeds.unshift({ text, t: 4 });
    this._feeds = this._feeds.slice(0, 5);
  }

  /** External one-line feed message (Game: input hints). Dedupes the top
   * entry so key-mashing doesn't fill the feed with the same hint. */
  notify(text) {
    if (this._feeds[0]?.text === text) {
      this._feeds[0].t = 4;
      return;
    }
    this._push(text);
  }

  _updateHealth(dt) {
    const st = gameState.player;
    const hp = Math.max(0, Math.round(st.health));
    const hpTxt = String(hp);
    if (hpTxt !== this._hpTxt) {
      this._hpTxt = hpTxt;
      this.hp.textContent = hpTxt;
      this.hpBar.style.width = `${Math.max(0, Math.min(100, st.health))}%`;
    }
    if (st.armor !== this._armorVal) {
      this._armorVal = st.armor;
      const armor = Math.max(0, st.armor) / PLAYER_CONFIG.ARMOR * 100;
      this.armorBar.style.width = `${Math.max(0, Math.min(100, armor))}%`;
      this.armorBar.parentElement.style.opacity = st.armor > 0.5 ? '1' : '0.25';
    }
    this._hpPulse = Math.max(0, this._hpPulse - dt * 4);
    const scale = (1 + 0.15 * this._hpPulse).toFixed(3);
    if (scale !== this._hpScale) {
      this._hpScale = scale;
      this.hp.style.transform = `scale(${scale})`;
    }
    const low = hp < 35;
    if (low !== this._hpLow) {
      this._hpLow = low;
      this.hp.classList.toggle('low', low);
      this.hpBar.classList.toggle('low', low);
    }
  }

  _updateScope() {
    const st = gameState.player;
    const on = !!(st.scoped && st.alive && gameState.activeWeapon === 'sniper');
    if (on !== this._scopeOn) {
      this._scopeOn = on;
      this.scope.style.opacity = on ? '1' : '0';
      this.scope.classList.toggle('on', on);
    }
    if (on) {
      const mag = st.scopeStage >= 2 ? '2×' : '1×';
      if (mag !== this._scopeMag) {
        this._scopeMag = mag;
        this.scopeMag.textContent = mag;
      }
    }
  }

  _drawArcs(dt, player) {
    const c = this.dmg;
    const ctx = this._ctxDmg;
    if (!this._arcs.length) {
      if (this._arcsOn) {
        ctx.clearRect(0, 0, c.width, c.height);
        this._arcsOn = false;
      }
      return;
    }
    this._arcsOn = true;
    ctx.clearRect(0, 0, c.width, c.height);
    const cx = c.width / 2, cy = c.height / 2, R = 120;
    for (const a of this._arcs) {
      a.t -= dt;
      if (a.t <= 0) continue;
      const dx = a.from.x - player.pos.x;
      const dz = a.from.z - player.pos.z;
      const ca = Math.cos(-player.yaw), sa = Math.sin(-player.yaw);
      const lx = dx * ca - dz * sa;
      const lz = dx * sa + dz * ca;
      // Screen angle: 0 = ahead (up), positive clockwise (right).
      const ang = Math.atan2(lx, -lz);
      ctx.strokeStyle = `rgba(210,58,42,${(a.t / 0.6 * 0.85).toFixed(3)})`;
      ctx.lineWidth = 7;
      ctx.beginPath();
      // Canvas 0 rad = +x (right); up is -PI/2. 60° wide segment.
      ctx.arc(cx, cy, R, ang - Math.PI / 2 - Math.PI / 6, ang - Math.PI / 2 + Math.PI / 6);
      ctx.stroke();
    }
    this._arcs = this._arcs.filter((a) => a.t > 0);
  }

  _updateSlots() {
    const rows = [];
    for (const id of SLOT_ORDER) {
      const cfg = WEAPONS[id];
      if (!gameState.weapons[id]?.owned) continue;
      const active = gameState.activeWeapon === id;
      rows.push(`<span class="${active ? 'on' : ''}"><b>${cfg.slot}</b> ${cfg.name.toUpperCase()}</span>`);
    }
    const html = rows.join('');
    if (html !== this._slotsHtml) {
      this._slotsHtml = html;
      this.slots.innerHTML = html;
    }
    const name = WEAPONS[gameState.activeWeapon].name;
    if (name !== this._wepName) {
      this._wepName = name;
      this.wep.textContent = name;
    }
  }

  update(dt, player, enemies) {
    const w = gameState.weapon;
    const magTxt = String(w.mag);
    if (magTxt !== this._magTxt) {
      this._magTxt = magTxt;
      this.mag.textContent = magTxt;
    }
    const resTxt = `/ ${w.reserve}`;
    if (resTxt !== this._resTxt) {
      this._resTxt = resTxt;
      this.res.textContent = resTxt;
    }
    this._hitT = Math.max(0, this._hitT - dt * 4);
    const hitOp = this._hitT.toFixed(2);
    if (hitOp !== this._hitOp) {
      this._hitOp = hitOp;
      this.hitmark.style.opacity = hitOp;
      this.hitmark.classList.toggle('head', this._hitHead);
    }
    // Damage vignette base layer + low-health 1.2 Hz pulse on top. The
    // gradient string only rebuilds when dmg moves >0.01 (autopsy fix 10).
    const dmg = 1 - gameState.player.health / 100;
    let vigOp = dmg * 0.85;
    if (gameState.player.health < 35 && gameState.player.alive) {
      vigOp += 0.12 * Math.sin(performance.now() * 0.001 * Math.PI * 2.4);
    }
    vigOp = Math.max(0, vigOp);
    if (Math.abs(vigOp - this._vigOp) > 0.005) {
      this._vigOp = vigOp;
      this.vig.style.opacity = vigOp.toFixed(2);
    }
    if (Math.abs(dmg - this._vigDmg) > 0.01) {
      this._vigDmg = dmg;
      this.vig.style.background = `radial-gradient(ellipse at 50% 50%, transparent ${52 - dmg * 18}%, rgba(90,0,0,${0.55 * dmg}) 100%)`;
    }
    this._updateCross(dt);
    this._updateHealth(dt);
    this._updateScope();
    this._updateSlots();
    this._updatePrompt();
    this._drawArcs(dt, player);
    const stanceTxt = gameState.player.crouching ? 'Crouched' : gameState.player.sprinting ? 'Sprinting' : 'Standing';
    if (stanceTxt !== this._stanceTxt) {
      this._stanceTxt = stanceTxt;
      this.stance.textContent = stanceTxt;
    }

    const showSens = player.sensToast > 0;
    if (showSens !== this._sensOn) {
      this._sensOn = showSens;
      this.sens.hidden = !showSens;
    }
    if (showSens) {
      const txt = `Sensitivity ${player.sensMult.toFixed(2)}×`;
      if (txt !== this._sensTxt) {
        this._sensTxt = txt;
        this.sens.textContent = txt;
      }
      this.sens.style.opacity = Math.min(1, player.sensToast * 2.5).toFixed(2);
    }

    this._radarT += dt;
    this._radarAcc += dt;
    perf.mark('minimap');
    this._drawCompass(player.yaw);
    this._drawRadar(player, enemies);
    perf.done('minimap');
    // Feed DOM only rebuilds when the visible entries change (was an
    // innerHTML write every frame, even while empty).
    for (const f of this._feeds) f.t -= dt;
    this._feeds = this._feeds.filter((f) => f.t > 0);
    const feedHtml = this._feeds.map((f) => `<div>${f.text}</div>`).join('');
    if (feedHtml !== this._feedHtml) {
      this._feedHtml = feedHtml;
      this.feed.innerHTML = feedHtml;
    }
  }

  _drawCompass(yaw) {
    const yawQ = (yaw * 200 + 0.5) | 0;
    if (yawQ === this._yawQ) return;
    this._yawQ = yawQ;
    const c = this.compass;
    const ctx = this._ctxCompass;
    const w = c.width, h = c.height;
    ctx.clearRect(0, 0, w, h);
    const deg = ((-yaw * 180 / Math.PI) % 360 + 360) % 360;
    ctx.fillStyle = 'rgba(0,0,0,0.28)';
    ctx.fillRect(0, 8, w, h - 16);
    ctx.strokeStyle = 'rgba(230,224,200,0.75)';
    ctx.fillStyle = '#e6e0c8';
    ctx.font = '600 18px ui-sans-serif, system-ui';
    ctx.textAlign = 'center';
    const labels = { 0: 'N', 90: 'E', 180: 'S', 270: 'W' };
    for (let a = 0; a < 360; a += 15) {
      const x = w * 0.5 + ((a - deg + 540) % 360 - 180) * 3.1;
      if (x < 10 || x > w - 10) continue;
      const major = a % 90 === 0;
      ctx.beginPath();
      ctx.moveTo(x, major ? 12 : 18);
      ctx.lineTo(x, major ? 28 : 24);
      ctx.stroke();
      if (labels[a]) ctx.fillText(labels[a], x, 48);
    }
    ctx.fillStyle = '#c4b57a';
    ctx.beginPath();
    ctx.moveTo(w * 0.5, 6);
    ctx.lineTo(w * 0.5 - 6, 16);
    ctx.lineTo(w * 0.5 + 6, 16);
    ctx.fill();
  }

  _updatePrompt() {
    const near = gameState.nearbyPickup;
    const key = near ? `${near.id}|${near.name || ''}` : '';
    if (key === this._promptKey) return;
    this._promptKey = key;
    if (!near) {
      this.prompt.hidden = true;
      return;
    }
    this.prompt.hidden = false;
    const label = near.id === 'health' ? 'MED CHEST +50 HP'
      : near.id === 'armor' ? 'ARMOR CHEST +50 SHIELD'
        : (near.name || 'SUPPLY').toUpperCase();
    this.prompt.textContent = `[E or walk over] ${label}`;
  }

  _drawRadar(player, enemies) {
    const yawQ = (player.yaw * 80 + 0.5) | 0;
    const pulseBucket = (this._radarT * 2.2 * 12) | 0;
    let bits = `${yawQ}|${pulseBucket}`;
    for (const e of enemies) {
      if (!e.alive) continue;
      bits += `|${(e.root.position.x * 4) | 0},${(e.root.position.z * 4) | 0}`;
    }
    for (const p of gameState.pickups) bits += p.taken ? '1' : '0';
    if (bits === this._radarKey && this._radarAcc < 0.05) return;
    this._radarKey = bits;
    this._radarAcc = 0;
    const c = this.radar;
    const ctx = this._ctxRadar;
    const w = c.width, h = c.height, cx = w / 2, cy = h / 2, R = 100;
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = 'rgba(6,10,8,0.55)';
    ctx.beginPath();
    ctx.arc(cx, cy, R, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = 'rgba(196,181,122,0.35)';
    ctx.lineWidth = 2;
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(cx, cy, R * 0.5, 0, Math.PI * 2);
    ctx.stroke();
    ctx.fillStyle = '#d8d2b4';
    ctx.beginPath();
    ctx.moveTo(cx, cy - 8);
    ctx.lineTo(cx - 5, cy + 6);
    ctx.lineTo(cx + 5, cy + 6);
    ctx.fill();
    const scale = R / 28;
    for (const e of enemies) {
      if (!e.alive) continue;
      const dx = e.root.position.x - player.pos.x;
      const dz = e.root.position.z - player.pos.z;
      const ca = Math.cos(-player.yaw), sa = Math.sin(-player.yaw);
      const x = dx * ca - dz * sa;
      const z = dx * sa + dz * ca;
      const px = cx + x * scale;
      const py = cy - z * scale;
      if (Math.hypot(px - cx, py - cy) > R - 6) continue;
      ctx.fillStyle = '#d24a3a';
      ctx.beginPath();
      ctx.arc(px, py, 4, 0, Math.PI * 2);
      ctx.fill();
    }
    // Persistent supply marks: edge-clamped so a crate 48 m from spawn
    // still reads. Health = dusty green, armor = steel blue.
    const pulse = 0.62 + 0.38 * Math.sin(this._radarT * Math.PI * 2.2);
    for (const p of gameState.pickups) {
      if (p.taken) continue;
      const dx = p.x - player.pos.x;
      const dz = p.z - player.pos.z;
      const ca = Math.cos(-player.yaw), sa = Math.sin(-player.yaw);
      const x = dx * ca - dz * sa;
      const z = dx * sa + dz * ca;
      let px = cx + x * scale;
      let py = cy - z * scale;
      const rad = Math.hypot(px - cx, py - cy);
      if (rad > R - 8) {
        const k = (R - 8) / rad;
        px = cx + (px - cx) * k;
        py = cy + (py - cy) * k;
      }
      const s = 5.5 + 2.2 * pulse;
      const hp = p.id === 'health';
      ctx.fillStyle = hp
        ? `rgba(110, 180, 100, ${0.45 + 0.45 * pulse})`
        : `rgba(110, 150, 190, ${0.45 + 0.45 * pulse})`;
      ctx.beginPath();
      ctx.arc(px, py, s + 3, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = hp ? '#7dcf7a' : '#7aa4d4';
      ctx.beginPath();
      ctx.moveTo(px, py - s);
      ctx.lineTo(px + s * 0.72, py);
      ctx.lineTo(px, py + s);
      ctx.lineTo(px - s * 0.72, py);
      ctx.closePath();
      ctx.fill();
    }
  }
}
