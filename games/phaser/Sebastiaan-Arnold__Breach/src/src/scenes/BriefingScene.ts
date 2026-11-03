import Phaser from 'phaser';
import { VIEW_H, VIEW_W } from '../config';
import { blocksSight, isOutdoor, parseLevel } from '../core/grid';
import { sfx } from '../game/audio';
import { hasBreachCharge, hasSuppressors, progress, unlockedWeapons } from '../game/progress';
import { WEAPONS, type WeaponId } from '../game/weapons';
import { rollSituation, type Situation } from '../game/situation';
import { levelById } from '../levels';
import { campaignOf, DIFFICULTY } from '../levels/campaigns';
import { isFloorDressing, isFurniture, propSize } from '../levels/props';
import type { LevelDef, Reliability } from '../levels/types';
import { ACCENT, Button, DIM, display, fadeIn, goTo, RED, setupScreenCamera, stagger, style, TEXT, UI } from './ui';

const MAP = { x: 40, y: 120, w: 720, h: 545 };
const PANEL = { x: 800, w: 420 };
const RELIABILITY_COLOR: Record<Reliability, string> = { Confirmed: '#4ade80', Likely: '#facc15', Unverified: RED };

/** The loadout carries over from one briefing to the next. */
const kit: { primary: WeaponId | null; suppressors: boolean } = { primary: null, suppressors: true };

interface EntryView {
  route: Phaser.GameObjects.Graphics;
  pts: { x: number; y: number }[];
  marker: Phaser.GameObjects.Graphics;
  mapLabel: Phaser.GameObjects.Text;
}

/**
 * The briefing: a police tablet with the floor plan on the left and the case file, intel and
 * entry choice on the right. The real situation is rolled here, so the map's marks point at it
 * (mostly).
 */
export class BriefingScene extends Phaser.Scene {
  private def!: LevelDef;
  private situation!: Situation;
  private entryIndex = 0;
  private hoverIndex = -1;
  private entries: EntryView[] = [];
  private rows: Phaser.GameObjects.Text[] = [];
  private primary: WeaponId = 'pistol';
  private gunLabels: Phaser.GameObjects.Text[] = [];
  private gunBlurb?: Phaser.GameObjects.Text;
  private deployButton!: Button;
  /** A ring that pulses round the chosen entry point on the plan. */
  private pulse!: Phaser.GameObjects.Graphics;
  /** Command's marks on the plan: faded in once the plan has scanned in. */
  private marks: Phaser.GameObjects.GameObject[] = [];

  constructor() {
    super('briefing');
  }

  init(data: { levelId: string }): void {
    this.def = levelById(data.levelId);
    this.situation = rollSituation(this.def.mission!);
    this.entryIndex = 0;
    this.hoverIndex = -1;
    this.entries = [];
    this.rows = [];
    this.gunLabels = [];
    this.marks = [];
    // A specialty mission issues its gun; otherwise the last choice, or the best all-round gun
    // issued so far (the sniper rifle is a specialist's pick).
    const guns = unlockedWeapons(progress);
    this.primary = this.def.mission?.issued
      ?? (kit.primary && guns.includes(kit.primary) ? kit.primary : guns.filter((g) => g !== 'sniper').at(-1) ?? 'pistol');
  }

  create(): void {
    setupScreenCamera(this);
    this.cameras.main.setBackgroundColor(0x05070a);
    fadeIn(this);
    sfx.menuAmbience(true);
    const m = this.def.mission!;

    // Tablet frame.
    const frame = this.add.graphics();
    frame.fillStyle(0x0b1220, 1);
    frame.fillRoundedRect(16, 16, VIEW_W - 32, VIEW_H - 32, 14);
    frame.lineStyle(2, 0x1e3a5f, 1);
    frame.strokeRoundedRect(16, 16, VIEW_W - 32, VIEW_H - 32, 14);
    frame.lineStyle(1, 0x1e3a5f, 1);
    frame.lineBetween(PANEL.x - 20, 40, PANEL.x - 20, VIEW_H - 40);

    // Header: which case of which campaign, the address and the time.
    const c = campaignOf(this.def.id);
    const caseNo = c ? `${c.title.toUpperCase()}  ·  CASE ${c.levels.indexOf(this.def.id) + 1} OF ${c.levels.length}` : 'CASE';
    const header = [
      this.add.text(MAP.x, 40, caseNo, display(13, ACCENT)),
      this.add.text(MAP.x, 56, m.title.toUpperCase(), display(34, '#f8fafc')),
      this.add.text(MAP.x, 96, `${m.location}  ·  ${m.time}  ·  Unit 7`, style(13, DIM)),
    ];

    this.drawMap();
    const panelObjects = this.drawPanel();
    this.refreshEntries();

    // The entrance: header and panel settle in while the plan scans in from the top.
    stagger(this, header, 0, 60, 6);
    stagger(this, panelObjects, 150, 14, 4);
    this.scanIn();

    // Keys: 1-9 or up and down pick an entry, left and right a gun, Enter deploys.
    this.input.keyboard?.on('keydown', (e: KeyboardEvent) => {
      if (this.data.get('leaving')) return;
      const digit = /^Digit([1-9])$/.exec(e.code);
      const n = this.def.entries.length;
      if (digit && Number(digit[1]) <= n) this.selectEntry(Number(digit[1]) - 1);
      if (e.code === 'ArrowUp' || e.code === 'KeyW') this.selectEntry((this.entryIndex - 1 + n) % n);
      if (e.code === 'ArrowDown' || e.code === 'KeyS') this.selectEntry((this.entryIndex + 1) % n);
      if (e.code === 'ArrowLeft' || e.code === 'KeyA') this.cycleGun(-1);
      if (e.code === 'ArrowRight' || e.code === 'KeyD') this.cycleGun(1);
      if (e.code === 'Enter') this.deployButton.activate();
      if (e.code === 'Escape') {
        sfx.back();
        goTo(this, 'menu');
      }
    });
  }

  /**
   * The plan scans in under a moving line, top to bottom, then command's marks fade in on it.
   */
  private scanIn(): void {
    const cover = this.add.rectangle(MAP.x - 4, MAP.y - 4, MAP.w + 8, MAP.h + 28, UI.panel).setOrigin(0).setDepth(5);
    const line = this.add.rectangle(MAP.x - 4, MAP.y - 4, MAP.w + 8, 2, UI.accent, 0.9).setOrigin(0).setDepth(6);
    const glow = this.add.rectangle(MAP.x - 4, MAP.y - 4, MAP.w + 8, 16, UI.accent, 0.12).setOrigin(0, 1).setDepth(6);
    const travel = MAP.h + 28;
    this.tweens.add({
      targets: [cover], y: MAP.y - 4 + travel, height: 0, duration: 900, ease: 'Cubic.InOut', delay: 120,
      onUpdate: () => {
        line.y = cover.y;
        glow.y = cover.y;
      },
      onComplete: () => {
        this.tweens.add({ targets: [line, glow], alpha: 0, duration: 200, onComplete: () => { line.destroy(); glow.destroy(); cover.destroy(); } });
        for (const m of this.marks) (m as unknown as Phaser.GameObjects.Components.Alpha).setAlpha(0);
        this.tweens.add({ targets: this.marks, alpha: 1, duration: 300 });
      },
    });
  }

  private cycleGun(dir: -1 | 1): void {
    const ids = this.gunLabels.map((l) => l.getData('gun') as WeaponId);
    if (ids.length < 2) return;
    this.selectGun(ids[(ids.indexOf(this.primary) + dir + ids.length) % ids.length]);
  }

  // ---------------------------------------------------------------- floor plan

  private drawMap(): void {
    const level = parseLevel(this.def.map);
    const s = Math.floor(Math.min(MAP.w / level.width, MAP.h / level.height));
    const ox = MAP.x + Math.floor((MAP.w - level.width * s) / 2);
    const oy = MAP.y + Math.floor((MAP.h - level.height * s) / 2);
    const g = this.add.graphics();
    const edge = (x: number, y: number) => x === 0 || y === 0 || x === level.width - 1 || y === level.height - 1;
    const solid = (x: number, y: number) => x < 0 || y < 0 || x >= level.width || y >= level.height || blocksSight(level.tiles[y * level.width + x]);
    // Inside a solid block (a neighbouring house, a locked flat): no wall face to draw.
    const mass = (x: number, y: number) => [-1, 0, 1].every((dy) => [-1, 0, 1].every((dx) => solid(x + dx, y + dy)));

    for (let y = 0; y < level.height; y++) {
      for (let x = 0; x < level.width; x++) {
        const i = y * level.width + x;
        const kind = level.tiles[i];
        const px = ox + x * s, py = oy + y * s;
        // The property boundary is drawn quietly so the building reads first.
        if ((edge(x, y) || mass(x, y)) && kind === 'wall') g.fillStyle(0x1e3a5f, 1);
        else if (kind === 'wall' || kind === 'plywood') g.fillStyle(0x7aa2d6, 1);
        else if (kind === 'interior') g.fillStyle(0x5b7fae, 1);
        else if (kind === 'furniture') g.fillStyle(0x22324d, 1);
        else if (kind === 'water') g.fillStyle(0x12324a, 1);
        else if (kind === 'glass') g.fillStyle(0x7dd3fc, 1);
        else if (isOutdoor(level.material[i])) g.fillStyle(level.material[i] === 'grass' ? 0x0d1a17 : 0x111a26, 1);
        else g.fillStyle(0x16233a, 1);
        g.fillRect(px, py, s, s);
      }
    }
    // Faint blueprint grid.
    g.lineStyle(1, 0x60a5fa, 0.06);
    for (let x = 0; x <= level.width; x++) g.lineBetween(ox + x * s, oy, ox + x * s, oy + level.height * s);
    for (let y = 0; y <= level.height; y++) g.lineBetween(ox, oy + y * s, ox + level.width * s, oy + y * s);

    for (const d of level.doors) {
      g.fillStyle(0xf59e0b, 1);
      if (d.orientation === 'h') g.fillRect(ox + d.tx * s, oy + d.ty * s + s / 2 - 1.5, s, 3);
      else g.fillRect(ox + d.tx * s + s / 2 - 1.5, oy + d.ty * s, 3, s);
    }
    // Vehicles and site kit; furniture already shows as furniture tiles.
    for (const prop of this.def.props ?? []) {
      if (isFurniture(prop) || isFloorDressing(prop)) continue;
      const { w, h } = propSize(prop);
      g.fillStyle(prop.kind === 'van' ? 0x1e3a8a : 0x334155, 1);
      g.fillRoundedRect(ox + prop.tx * s, oy + prop.ty * s, w * s, h * s, 3);
    }

    // Areas the plans don't cover.
    for (const z of this.def.mission!.unknownZones) {
      const x0 = ox + z.x0 * s, y0 = oy + z.y0 * s, w = (z.x1 - z.x0 + 1) * s, h = (z.y1 - z.y0 + 1) * s;
      g.fillStyle(0x334155, 0.95);
      g.fillRect(x0, y0, w, h);
      g.lineStyle(1, 0x94a3b8, 0.35);
      hatch(g, x0, y0, w, h, 8);
      this.add.text(x0 + w / 2, y0 + 3, 'NO PLANS', style(9, DIM, { fontStyle: 'bold' })).setOrigin(0.5, 0);
    }

    // Command's marks: last known suspect positions and the reported civilian.
    const marks = this.add.graphics();
    this.marks.push(marks);
    for (const p of this.situation.suspectMarks) {
      const x = ox + p.tx * s, y = oy + p.ty * s;
      marks.lineStyle(3, 0xef4444, 0.95);
      marks.lineBetween(x - 7, y - 7, x + 7, y + 7);
      marks.lineBetween(x - 7, y + 7, x + 7, y - 7);
    }
    // At most three civilians are marked, so a crowded case doesn't bury the plan. A hostage is
    // always marked.
    const m = this.def.mission!;
    for (const c of [...(m.hostage ? [m.hostage] : []), ...this.situation.civilians].slice(0, 3)) {
      marks.lineStyle(2, 0xfacc15, 0.9);
      marks.strokeCircle(ox + c.tx * s, oy + c.ty * s, s * 1.6);
    }
    // A case's twist gets a label on the plan, in the same yellow as its intel line.
    const tag = (text: string, x: number, y: number) => {
      const t = this.add.text(x, y, text, style(9, '#facc15', { fontStyle: 'bold', backgroundColor: '#0b1220', padding: { x: 3, y: 1 } })).setOrigin(0.5, 0);
      this.marks.push(t);
      return t;
    };
    for (const p of m.alarmPanels ?? []) {
      const ax = ox + p.tx * s, ay = oy + p.ty * s;
      marks.lineStyle(2, 0xfacc15, 0.9);
      marks.strokeRect(ax - 5, ay - 5, 10, 10);
      tag('ALARM', ax, ay + 8);
    }
    if (m.hostage) tag('HOSTAGE', ox + m.hostage.tx * s, oy + m.hostage.ty * s + s * 1.6 + 2);
    if (m.overwatch) {
      const gx = ox + m.overwatch.getaway.tx * s, gy = oy + m.overwatch.getaway.ty * s;
      marks.lineStyle(2, 0xfacc15, 0.9);
      marks.strokeRect(gx - 6, gy - 6, 12, 12);
      tag('CAR', gx, gy + 9);
    }
    if (m.evidence) {
      const ex = ox + m.evidence.tx * s, ey = oy + m.evidence.ty * s;
      marks.lineStyle(2, 0xfacc15, 0.9);
      marks.strokeRect(ex - 6, ey - 6, 12, 12);
      tag('EVIDENCE', ex, ey + 9);
    }

    // Entry points: a route from the van, a numbered marker and a name.
    const cx = ox + (level.width * s) / 2, cy = oy + (level.height * s) / 2;
    this.pulse = this.add.graphics();
    this.pulse.lineStyle(2, UI.accent, 1);
    this.pulse.strokeCircle(0, 0, 14);
    this.tweens.add({ targets: this.pulse, scale: { from: 1, to: 1.9 }, alpha: { from: 0.9, to: 0 }, duration: 1100, repeat: -1, ease: 'Quad.Out' });
    this.def.entries.forEach((entry, i) => {
      const pts = entry.approach.map((p) => ({ x: ox + p.tx * s, y: oy + p.ty * s }));
      const end = pts[pts.length - 1];
      const route = this.add.graphics();
      const marker = this.add.graphics().setPosition(end.x, end.y);
      this.add.text(end.x, end.y, `${i + 1}`, style(13, TEXT, { fontStyle: 'bold' })).setOrigin(0.5).setDepth(2);
      // Label on the outside of the building, away from the centre of the map.
      const away = Math.atan2(end.y - cy, end.x - cx);
      const lx = end.x + Math.cos(away) * 22, ly = end.y + Math.sin(away) * 22;
      // A dark backing keeps the label readable where it crosses walls on the plan.
      const mapLabel = this.add.text(lx, ly, cap(entry.name), style(11, TEXT, { fontStyle: 'bold', backgroundColor: '#0b1220', padding: { x: 3, y: 1 } }))
        .setOrigin(Math.cos(away) < -0.3 ? 1 : Math.cos(away) > 0.3 ? 0 : 0.5, Math.sin(away) > 0.3 ? 0 : Math.sin(away) < -0.3 ? 1 : 0.5);
      // An entry at the edge of the map has no room beside it: the label goes underneath.
      const b = mapLabel.getBounds();
      if (b.x < MAP.x || b.right > MAP.x + MAP.w) mapLabel.setPosition(end.x, end.y + 16).setOrigin(0.5, 0);
      // Under the marker, still keep it inside the plan.
      const u = mapLabel.getBounds();
      if (u.x < MAP.x) mapLabel.setX(mapLabel.x + MAP.x - u.x);
      if (u.right > MAP.x + MAP.w) mapLabel.setX(mapLabel.x - (u.right - MAP.x - MAP.w));
      const zone = this.add.zone(end.x, end.y, 34, 34).setInteractive({ useHandCursor: true });
      zone.on('pointerover', () => this.hover(i));
      zone.on('pointerout', () => this.hover(-1));
      zone.on('pointerup', () => this.selectEntry(i));
      this.entries.push({ route, pts, marker, mapLabel });
    });

    const legend = this.add.graphics();
    const ly = MAP.y + MAP.h + 18;
    legend.lineStyle(2.5, 0xef4444, 1);
    legend.lineBetween(MAP.x + 4, ly - 5, MAP.x + 14, ly + 5);
    legend.lineBetween(MAP.x + 4, ly + 5, MAP.x + 14, ly - 5);
    this.add.text(MAP.x + 22, ly, 'Last known suspect', style(11, DIM)).setOrigin(0, 0.5);
    legend.lineStyle(2, 0xfacc15, 1);
    legend.strokeCircle(MAP.x + 190, ly, 7);
    this.add.text(MAP.x + 204, ly, 'Civilian reported', style(11, DIM)).setOrigin(0, 0.5);
    legend.fillStyle(0x2563eb, 1);
    legend.fillCircle(MAP.x + 370, ly, 8);
    this.add.text(MAP.x + 384, ly, 'Entry point: click to choose', style(11, DIM)).setOrigin(0, 0.5);
  }

  // ---------------------------------------------------------------- case file, intel, entry

  private drawPanel(): Phaser.GameObjects.GameObject[] {
    const m = this.def.mission!;
    const x = PANEL.x, w = PANEL.w;
    let y = 40;
    const before = this.children.list.length;
    const heading = (t: string) => {
      const h = this.add.text(x, y - 1, t, display(13, ACCENT));
      this.add.rectangle(x + h.width + 10, y + 8, w - h.width - 10, 1, UI.line).setOrigin(0, 0.5);
      y += 20;
    };

    heading('SITUATION');
    for (const line of m.situation) {
      this.add.text(x, y, '–', style(12, DIM));
      const t = this.add.text(x + 16, y, line, style(12, TEXT, { lineSpacing: 2, wordWrap: { width: w - 16 } }));
      y += t.height + 5;
    }
    y += 12;

    heading('OBJECTIVE');
    const objective = this.add.text(x, y, m.objective, style(13, TEXT, { fontStyle: 'bold', wordWrap: { width: w } }));
    y += objective.height + 16;

    heading('INTEL');
    const rows: [string, string, string?][] = [
      ...(m.twist ? [[m.twist.label, m.twist.text, '#facc15'] as [string, string, string]] : []),
      ['Suspects', `${m.hostiles.min}–${m.hostiles.max}${this.armoured ? ', light vests' : ''}`],
      ['Weapons', m.loadout],
      ['Civilians', m.civilians.text],
      ['Intel', m.reliability, RELIABILITY_COLOR[m.reliability]],
    ];
    for (const [k, v, color] of rows) {
      this.add.text(x, y, k, style(13, DIM));
      const value = this.add.text(x + 110, y, v, style(13, color ?? TEXT, { wordWrap: { width: w - 110 } }));
      y += value.height + 5;
    }
    y += 12;

    heading('LOADOUT');
    const guns = m.issued ? [m.issued] : unlockedWeapons(progress);
    this.add.text(x, y, 'Primary', style(13, DIM));
    let gx = x + 110;
    for (const id of guns) {
      const label = this.add.text(gx, y - 2, (m.issued ? WEAPONS[id].name : WEAPONS[id].short).toUpperCase(), display(15, TEXT)).setInteractive({ useHandCursor: true });
      label.setData('gun', id);
      label.on('pointerover', () => id !== this.primary && (label.setColor(TEXT), sfx.hover()));
      label.on('pointerout', () => this.selectGun(this.primary, true));
      label.on('pointerup', () => this.selectGun(id));
      this.gunLabels.push(label);
      gx += label.width + 22;
    }
    if (m.issued) this.add.text(gx, y + 2, 'Issued for this mission', style(11, DIM));
    y += 22;
    // Room for the longest description among the guns on offer, measured rather than assumed,
    // so switching guns never pushes text into the line below.
    this.gunBlurb = this.add.text(x + 110, y, '', style(12, TEXT, { lineSpacing: 2, wordWrap: { width: w - 110 } }));
    y += Math.max(...guns.map((id) => this.gunBlurb!.setText(WEAPONS[id].blurb).height)) + 6;
    const sidearm = guns.some((g) => g !== 'pistol');
    this.add.text(x + 110, y, sidearm ? 'Sidearm: Pistol (2)' : 'More guns are issued with promotion', style(11, DIM));
    if (hasSuppressors(progress)) {
      const toggle = this.add.text(x + w, y, '', style(11, ACCENT)).setOrigin(1, 0).setInteractive({ useHandCursor: true });
      const label = () => toggle.setText(`Suppressors: ${kit.suppressors ? 'On' : 'Off'}`);
      toggle.on('pointerup', () => {
        kit.suppressors = !kit.suppressors;
        sfx.select();
        label();
      });
      label();
    }
    if (hasBreachCharge(progress) && !m.overwatch) {
      this.add.text(x + 110, y + 16, 'Breach charge  ×1  (G, facing a wall)', style(11, DIM));
      y += 16;
    }
    y += 26;
    this.selectGun(this.primary);

    heading('ENTRY POINT');
    this.def.entries.forEach((entry, i) => {
      const row = this.add.text(x, y, '', display(17, TEXT)).setInteractive({ useHandCursor: true });
      row.on('pointerover', () => {
        if (i !== this.hoverIndex) sfx.hover();
        this.hover(i);
      });
      row.on('pointerout', () => this.hover(-1));
      row.on('pointerup', () => this.selectEntry(i));
      row.setData('label', `${i + 1}   ${cap(entry.name)}`);
      this.rows.push(row);
      y += 28;
    });

    const by = VIEW_H - 112, bh = 48;
    this.deployButton = new Button(this, x + w / 2, by + bh / 2, w, bh, 'DEPLOY', () => this.deploy(), { primary: true, size: 19 });
    new Button(this, x + w / 2, by + bh + 26, 200, 30, 'BACK TO MENU', () => {
      sfx.back();
      goTo(this, 'menu');
    }, { size: 12 });
    return this.children.list.slice(before);
  }

  private selectGun(id: WeaponId, quiet = false): void {
    if (id !== this.primary && !quiet) sfx.select();
    this.primary = id;
    if (!this.def.mission?.issued) kit.primary = id;
    for (const l of this.gunLabels) {
      const on = l.getData('gun') === id;
      l.setColor(on ? ACCENT : DIM);
    }
    this.gunBlurb?.setText(WEAPONS[id].blurb);
  }

  /** Suspects at this rank wear vests. */
  private get armoured(): boolean {
    return DIFFICULTY[campaignOf(this.def.id)?.rank ?? 1].toughness > 1;
  }

  private hover(i: number): void {
    this.hoverIndex = i;
    this.refreshEntries();
  }

  private selectEntry(i: number): void {
    if (i !== this.entryIndex) sfx.select();
    this.entryIndex = i;
    this.refreshEntries();
  }

  /** Selected entry: bright route, filled marker, highlighted row. Others stay quiet. */
  private refreshEntries(): void {
    this.entries.forEach((e, i) => {
      const on = i === this.entryIndex;
      const hot = i === this.hoverIndex;
      e.route.clear();
      e.route.lineStyle(on ? 3 : 2, 0x60a5fa, on ? 0.95 : hot ? 0.6 : 0.25);
      for (let k = 1; k < e.pts.length; k++) {
        if (on) e.route.lineBetween(e.pts[k - 1].x, e.pts[k - 1].y, e.pts[k].x, e.pts[k].y);
        else dashed(e.route, e.pts[k - 1].x, e.pts[k - 1].y, e.pts[k].x, e.pts[k].y);
      }
      e.marker.clear();
      if (on) {
        e.marker.fillStyle(0x60a5fa, 0.25);
        e.marker.fillCircle(0, 0, 19);
      }
      e.marker.fillStyle(on ? 0x2563eb : hot ? 0x1e3a8a : 0x0b1220, 1);
      e.marker.fillCircle(0, 0, 13);
      e.marker.lineStyle(2, 0x60a5fa, on || hot ? 1 : 0.7);
      e.marker.strokeCircle(0, 0, 13);
      e.mapLabel.setColor(on ? TEXT : DIM).setAlpha(on || hot ? 1 : 0.7);
      const row = this.rows[i];
      row.setText(`${on ? '▸' : ' '} ${row.getData('label')}`).setColor(on ? ACCENT : hot ? TEXT : DIM);
    });
    this.deployButton.setText(`DEPLOY  ·  ${this.def.entries[this.entryIndex].name.toUpperCase()}`);
    const sel = this.entries[this.entryIndex];
    const end = sel.pts[sel.pts.length - 1];
    this.pulse.setPosition(end.x, end.y);
  }

  private deploy(): void {
    sfx.menuAmbience(false);
    goTo(this, 'game', {
      levelId: this.def.id, entryId: this.def.entries[this.entryIndex].id, situation: this.situation, primary: this.primary,
      suppressed: hasSuppressors(progress) && kit.suppressors,
    });
  }
}

function cap(s: string): string {
  return s[0].toUpperCase() + s.slice(1);
}

/** Diagonal hatching clipped to a rectangle. */
function hatch(g: Phaser.GameObjects.Graphics, x0: number, y0: number, w: number, h: number, step: number): void {
  // Each line runs up and to the right: (x0 + k + t, y0 + h - t) for t where it stays inside.
  for (let k = -h; k < w; k += step) {
    const t0 = Math.max(0, -k), t1 = Math.min(h, w - k);
    if (t0 < t1) g.lineBetween(x0 + k + t0, y0 + h - t0, x0 + k + t1, y0 + h - t1);
  }
}

function dashed(g: Phaser.GameObjects.Graphics, x0: number, y0: number, x1: number, y1: number): void {
  const d = Math.hypot(x1 - x0, y1 - y0);
  const n = Math.max(1, Math.floor(d / 8));
  for (let k = 0; k < n; k += 2) {
    const a = k / n, b = Math.min(1, (k + 1) / n);
    g.lineBetween(x0 + (x1 - x0) * a, y0 + (y1 - y0) * a, x0 + (x1 - x0) * b, y0 + (y1 - y0) * b);
  }
}
