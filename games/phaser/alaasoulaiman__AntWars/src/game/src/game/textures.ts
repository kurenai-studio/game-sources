// Copyright (c) 2026 Alaa Soulaiman and KovaTech Industries Inc. MIT License, see LICENSE.
// Every sprite of slice 1, drawn in code at boot. Original placeholder art: thick outlines, big eyes, loud colours.
// Critters face right (angle 0) so a sprite's rotation is its heading.
import * as Phaser from 'phaser';
import { POWERS } from '../sim/growth';

const INK = 0x1f1206;
type G = Phaser.GameObjects.Graphics;

function make(scene: Phaser.Scene, key: string, w: number, h: number, draw: (g: G) => void): void {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  draw(g);
  g.generateTexture(key, w, h);
  g.destroy();
}

function blobEllipse(g: G, x: number, y: number, w: number, h: number, color: number): void {
  g.fillStyle(INK, 1);
  g.fillEllipse(x, y, w + 6, h + 6);
  g.fillStyle(color, 1);
  g.fillEllipse(x, y, w, h);
}

function blobCircle(g: G, x: number, y: number, r: number, color: number): void {
  g.fillStyle(INK, 1);
  g.fillCircle(x, y, r + 3);
  g.fillStyle(color, 1);
  g.fillCircle(x, y, r);
}

function bentLine(g: G, x1: number, y1: number, x2: number, y2: number, x3: number, y3: number): void {
  g.beginPath();
  g.moveTo(x1, y1);
  g.lineTo(x2, y2);
  g.lineTo(x3, y3);
  g.strokePath();
}

/** Six legs in a tripod gait: frame 0 and 1 swing opposite pairs. */
function sixLegs(g: G, cx: number, cy: number, reach: number, width: number, frame: number): void {
  const swing = frame === 0 ? 1 : -1;
  g.lineStyle(width, INK, 1);
  for (const s of [-1, 1]) {
    const a = swing * s * reach * 0.22;
    g.lineBetween(cx + 3, cy + s * 3, cx + reach * 0.75 + a, cy + s * reach);
    g.lineBetween(cx, cy + s * 3, cx - a, cy + s * reach * 1.12);
    g.lineBetween(cx - 3, cy + s * 3, cx - reach * 0.75 + a, cy + s * reach);
  }
}

function hero(g: G, frame: number): void {
  const cy = 32;
  sixLegs(g, 31, cy, 19, 4, frame);
  g.lineStyle(3, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 50, cy + s * 4, 56, cy + s * 10, 62, cy + s * 9);
  g.fillStyle(INK, 1);
  g.fillTriangle(1, cy, 8, cy - 4, 8, cy + 4);
  blobEllipse(g, 17, cy, 26, 21, 0xffb627);
  blobEllipse(g, 32, cy, 13, 11, 0xffb627);
  blobCircle(g, 45, cy, 10.5, 0xffc94a);
  g.fillStyle(0xffe7a0, 0.9);
  g.fillEllipse(13, cy - 4, 11, 5);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(48, cy + s * 5, 4.8);
    g.fillStyle(0x111111, 1);
    g.fillCircle(49.8, cy + s * 5, 2.5);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(50.5, cy + s * 5 - 1.2, 0.9);
  }
}

function armyAnt(g: G, frame: number): void {
  const cy = 28;
  sixLegs(g, 27, cy, 16, 3.5, frame);
  g.lineStyle(3, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 40, cy + s * 3, 46, cy + s * 9, 51, cy + s * 10);
  blobEllipse(g, 14, cy, 21, 16, 0xa3271b);
  blobEllipse(g, 27, cy, 11, 9, 0xa3271b);
  blobCircle(g, 37, cy, 8.5, 0xc0392b);
  g.lineStyle(3.5, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 43, cy + s * 3, 50, cy + s * 6, 53, cy + s * 1);
  g.fillStyle(0xe35d4f, 0.8);
  g.fillEllipse(11, cy - 3, 9, 4);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(39.5, cy + s * 4, 3.1);
    g.fillStyle(0xff2a1a, 1);
    g.fillCircle(40.6, cy + s * 4, 1.6);
    g.lineStyle(2.4, INK, 1);
    g.lineBetween(36, cy + s * 7.5, 42.5, cy + s * 2.5);
  }
}

function wasp(g: G, frame: number): void {
  const cy = 30;
  g.lineStyle(3, INK, 1);
  for (const s of [-1, 1]) {
    g.lineBetween(31, cy + s * 3, 37, cy + s * 12);
    g.lineBetween(28, cy + s * 3, 24, cy + s * 13);
  }
  g.fillStyle(INK, 1);
  g.fillTriangle(0, cy, 7, cy - 3.5, 7, cy + 3.5);
  blobEllipse(g, 17, cy, 26, 18, 0xffd23f);
  g.fillStyle(0x1b1b1b, 1);
  g.fillEllipse(14, cy, 4.5, 15);
  g.fillEllipse(21, cy, 4.5, 16);
  blobEllipse(g, 33, cy, 12, 12, 0x3a2a12);
  blobCircle(g, 43, cy, 7.5, 0xffd23f);
  for (const s of [-1, 1]) {
    g.fillStyle(0x161616, 1);
    g.fillEllipse(45.5, cy + s * 3.6, 5.5, 4.4);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(46.5, cy + s * 3.6 - 1, 0.9);
  }
  const spread = frame === 0 ? 1 : 0.5;
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 0.5);
    g.fillEllipse(29, cy + s * (8 + 7 * spread), 23, 6 + 6 * spread);
    g.lineStyle(2, 0xdfe9ff, 0.95);
    g.strokeEllipse(29, cy + s * (8 + 7 * spread), 23, 6 + 6 * spread);
  }
}

function spider(g: G, frame: number): void {
  const cx = 32;
  const cy = 32;
  const swing = frame === 0 ? 1 : -1;
  g.lineStyle(3.5, INK, 1);
  for (const s of [-1, 1]) {
    for (let i = 0; i < 4; i++) {
      const deg = 40 + i * 35 + swing * s * (i % 2 === 0 ? 8 : -8);
      const a = (deg * Math.PI) / 180;
      const kx = cx + Math.cos(a) * 14;
      const ky = cy + s * (Math.sin(a) * 14 - 4);
      const fx = cx + Math.cos(a) * 28;
      const fy = cy + s * (Math.sin(a) * 28 + 2);
      bentLine(g, cx + 2, cy + s * 2, kx, ky, fx, fy);
    }
  }
  blobCircle(g, cx - 8, cy, 13, 0x4b2a6b);
  g.fillStyle(0xff8a3d, 1);
  g.fillCircle(cx - 12, cy - 4, 2.6);
  g.fillCircle(cx - 12, cy + 4, 2.6);
  g.fillCircle(cx - 5, cy, 2.6);
  blobCircle(g, cx + 8, cy, 8, 0x5d3784);
  g.fillStyle(0xff3b3b, 1);
  for (const s of [-1, 1]) {
    g.fillCircle(cx + 12, cy + s * 2.4, 1.9);
    g.fillCircle(cx + 10, cy + s * 5.4, 1.5);
  }
}

function termite(g: G, frame: number): void {
  const cy = 18;
  sixLegs(g, 17, cy, 10, 2.5, frame);
  blobEllipse(g, 11, cy, 15, 12, 0xf1dcb0);
  blobCircle(g, 24, cy, 6, 0xd08a3c);
  g.lineStyle(2, INK, 1);
  for (const s of [-1, 1]) g.lineBetween(29, cy + s * 2, 33, cy + s * 3.5);
}

/** A dart drawn as a glyph for the power icons: tail to tip along ang, centred on (x, y). */
function dartGlyph(g: G, x: number, y: number, ang: number, len: number, alpha = 1): void {
  const c = Math.cos(ang);
  const s = Math.sin(ang);
  const tx = x + (c * len) / 2;
  const ty = y + (s * len) / 2;
  const bx = x - (c * len) / 2;
  const by = y - (s * len) / 2;
  g.lineStyle(7, INK, alpha);
  g.lineBetween(bx, by, tx, ty);
  g.lineStyle(3, 0xfff3b0, alpha);
  g.lineBetween(bx, by, tx, ty);
  g.fillStyle(INK, alpha);
  g.fillTriangle(tx + c * 9, ty + s * 9, tx - s * 7, ty + c * 7, tx + s * 7, ty - c * 7);
  g.fillStyle(0xfff3b0, alpha);
  g.fillTriangle(tx + c * 5, ty + s * 5, tx - s * 3.5, ty + c * 3.5, tx + s * 3.5, ty - c * 3.5);
}

/** The 14 level up power icons (sim/growth.ts POWERS): a coloured tile with one plain glyph, original art. */
function powerIcon(g: G, id: string, color: number): void {
  g.fillStyle(INK, 1);
  g.fillRoundedRect(0, 0, 64, 64, 14);
  g.fillStyle(color, 1);
  g.fillRoundedRect(3, 3, 58, 58, 12);
  g.fillStyle(0xffffff, 0.2);
  g.fillRoundedRect(7, 6, 50, 20, 9);
  const up = -Math.PI / 2;
  switch (id) {
    case 'jaw':
      g.lineStyle(10, INK, 1);
      bentLine(g, 15, 14, 20, 40, 31, 48);
      bentLine(g, 49, 14, 44, 40, 33, 48);
      g.lineStyle(4, 0xffffff, 1);
      bentLine(g, 15, 14, 20, 40, 31, 48);
      bentLine(g, 49, 14, 44, 40, 33, 48);
      break;
    case 'glands':
      for (const [x, y] of [[38, 18], [24, 34], [40, 46]]) {
        g.fillStyle(INK, 1);
        g.fillCircle(x, y + 3, 8);
        g.fillTriangle(x, y - 10, x - 7, y, x + 7, y);
        g.fillStyle(0xe1f5fe, 1);
        g.fillCircle(x, y + 3, 5);
      }
      g.lineStyle(3, INK, 1);
      g.lineBetween(8, 20, 20, 20);
      g.lineBetween(6, 46, 22, 46);
      break;
    case 'shell': {
      const pts = [
        new Phaser.Math.Vector2(32, 9), new Phaser.Math.Vector2(53, 17), new Phaser.Math.Vector2(49, 41),
        new Phaser.Math.Vector2(32, 56), new Phaser.Math.Vector2(15, 41), new Phaser.Math.Vector2(11, 17),
      ];
      g.fillStyle(INK, 1);
      g.fillPoints(pts, true);
      g.fillStyle(0xe8f5e9, 1);
      g.fillPoints(pts.map((p) => new Phaser.Math.Vector2(32 + (p.x - 32) * 0.78, 33 + (p.y - 33) * 0.78)), true);
      g.fillStyle(0x2e7d32, 1);
      g.fillRect(28, 21, 8, 24);
      g.fillRect(20, 29, 24, 8);
      break;
    }
    case 'honeydew':
      g.fillStyle(INK, 1);
      g.fillCircle(32, 39, 16);
      g.fillTriangle(32, 7, 17, 33, 47, 33);
      g.fillStyle(0xfff8e1, 1);
      g.fillCircle(32, 39, 12);
      g.fillTriangle(32, 13, 21, 34, 43, 34);
      g.fillStyle(0xffffff, 1);
      g.fillCircle(27, 36, 3.5);
      break;
    case 'eye':
      g.fillStyle(INK, 1);
      g.fillEllipse(32, 33, 50, 30);
      g.fillStyle(0xffffff, 1);
      g.fillEllipse(32, 33, 43, 23);
      g.fillStyle(INK, 1);
      g.fillCircle(32, 33, 9);
      g.fillStyle(0xffffff, 1);
      g.fillCircle(35, 30, 3);
      break;
    case 'fang':
      dartGlyph(g, 23, 34, up, 30);
      dartGlyph(g, 41, 34, up, 30);
      break;
    case 'fork':
      dartGlyph(g, 32, 34, up, 28);
      dartGlyph(g, 20, 38, up - 0.55, 24);
      dartGlyph(g, 44, 38, up + 0.55, 24);
      break;
    case 'echo':
      dartGlyph(g, 32, 44, up, 24, 0.45);
      dartGlyph(g, 32, 28, up, 24);
      break;
    case 'needle':
      g.lineStyle(5, INK, 1);
      g.strokeCircle(30, 34, 11);
      dartGlyph(g, 32, 34, 0, 40);
      break;
    case 'hop':
      g.fillStyle(INK, 1);
      for (const [x, y] of [[22, 30], [30, 20], [40, 17], [49, 22]]) g.fillCircle(x, y, 3);
      g.lineStyle(4, INK, 1);
      g.strokeCircle(52, 34, 6);
      g.strokeCircle(14, 22, 6);
      dartGlyph(g, 22, 46, -0.6, 24);
      break;
    case 'lucky':
      g.lineStyle(4, INK, 1);
      g.lineBetween(32, 34, 40, 54);
      for (const [x, y] of [[24, 24], [40, 24], [24, 40], [40, 40]]) {
        g.fillStyle(INK, 1);
        g.fillCircle(x, y, 10);
        g.fillStyle(0xd7ffe9, 1);
        g.fillCircle(x, y, 7);
      }
      break;
    case 'fury':
      g.fillStyle(INK, 1);
      g.fillCircle(32, 42, 15);
      g.fillTriangle(32, 6, 17, 38, 47, 38);
      g.fillStyle(0xffd54f, 1);
      g.fillCircle(32, 43, 10);
      g.fillTriangle(32, 16, 23, 40, 41, 40);
      break;
    case 'frost':
      g.lineStyle(6, INK, 1);
      for (let i = 0; i < 3; i++) {
        const a = (i * Math.PI) / 3;
        g.lineBetween(32 - Math.cos(a) * 21, 33 - Math.sin(a) * 21, 32 + Math.cos(a) * 21, 33 + Math.sin(a) * 21);
      }
      g.lineStyle(3, 0xffffff, 1);
      for (let i = 0; i < 3; i++) {
        const a = (i * Math.PI) / 3;
        g.lineBetween(32 - Math.cos(a) * 19, 33 - Math.sin(a) * 19, 32 + Math.cos(a) * 19, 33 + Math.sin(a) * 19);
      }
      g.fillStyle(0xffffff, 1);
      g.fillCircle(32, 33, 5);
      break;
    case 'stance':
      g.fillStyle(INK, 1);
      g.fillEllipse(32, 38, 48, 34);
      g.fillStyle(0x8d8d8d, 1);
      g.fillEllipse(32, 38, 42, 28);
      g.fillStyle(0xc4c4c4, 1);
      g.fillEllipse(25, 31, 16, 8);
      g.lineStyle(3, INK, 1);
      bentLine(g, 36, 28, 40, 38, 36, 46);
      break;
    case 'fire':
      // A flame: an outer tongue and a bright core.
      g.fillStyle(INK, 1);
      g.fillCircle(32, 41, 15);
      g.fillTriangle(32, 9, 17, 40, 47, 40);
      g.fillStyle(0xffd54f, 1);
      g.fillCircle(32, 41, 12);
      g.fillTriangle(32, 14, 20, 40, 44, 40);
      g.fillStyle(0xffffff, 0.95);
      g.fillCircle(32, 44, 5.5);
      break;
    case 'spark':
      // A lightning bolt.
      g.fillStyle(INK, 1);
      g.fillTriangle(37, 6, 14, 37, 33, 35);
      g.fillTriangle(31, 29, 50, 27, 25, 59);
      g.fillStyle(0xffffff, 1);
      g.fillTriangle(35, 11, 19, 34, 32, 33);
      g.fillTriangle(32, 31, 45, 30, 28, 52);
      break;
  }
}

/** Slice 4: the shock puddle (frost plus spark), an electric pool with a few bright arcs. */
function puddle(g: G): void {
  g.fillStyle(0x4fc3f7, 0.35);
  g.fillCircle(64, 64, 60);
  g.lineStyle(4, 0xb3ecff, 0.9);
  g.strokeCircle(64, 64, 58);
  g.lineStyle(3, 0xfff59d, 0.95);
  const rng = new Phaser.Math.RandomDataGenerator(['puddle-v1']);
  for (let i = 0; i < 6; i++) {
    const a = rng.realInRange(0, Math.PI * 2);
    const r1 = rng.realInRange(8, 22);
    const r2 = rng.realInRange(34, 52);
    const bend = a + rng.realInRange(-0.5, 0.5);
    bentLine(g, 64 + Math.cos(a) * r1, 64 + Math.sin(a) * r1, 64 + Math.cos(bend) * ((r1 + r2) / 2), 64 + Math.sin(bend) * ((r1 + r2) / 2), 64 + Math.cos(a) * r2, 64 + Math.sin(a) * r2);
  }
}

/** The blinding steam (fire plus frost): a soft white cloud of overlapping puffs. */
function steam(g: G): void {
  const rng = new Phaser.Math.RandomDataGenerator(['steam-v1']);
  for (let i = 0; i < 9; i++) {
    const a = (i / 9) * Math.PI * 2;
    const r = i === 0 ? 0 : rng.realInRange(28, 44);
    g.fillStyle(0xf4f7fb, 0.32);
    g.fillCircle(80 + Math.cos(a) * r, 80 + Math.sin(a) * r, rng.realInRange(30, 40));
  }
  g.fillStyle(0xffffff, 0.45);
  g.fillCircle(80, 80, 34);
}

/** Armour plates over the hero (the same 64 by 64 frame, facing right): more bands and spikes at each health tier. */
function plates(g: G, tier: number): void {
  const cy = 32;
  const steel = 0x7b8794;
  const shine = 0xc9d3dc;
  // Tier 1: two bands across the abdomen.
  for (const x of [12, 20]) {
    g.fillStyle(INK, 1);
    g.fillRoundedRect(x - 3, cy - 10, 6, 20, 3);
    g.fillStyle(steel, 1);
    g.fillRoundedRect(x - 2, cy - 9, 4, 18, 2);
  }
  if (tier >= 2) {
    // Tier 2: a plate on the thorax and two shoulder spikes.
    g.fillStyle(INK, 1);
    g.fillEllipse(32, cy, 15, 13);
    g.fillStyle(steel, 1);
    g.fillEllipse(32, cy, 11, 9);
    g.fillStyle(shine, 1);
    g.fillEllipse(30, cy - 2, 5, 3);
    for (const s of [-1, 1]) {
      g.fillStyle(INK, 1);
      g.fillTriangle(29, cy + s * 5, 35, cy + s * 5, 32, cy + s * 13);
      g.fillStyle(shine, 1);
      g.fillTriangle(30.5, cy + s * 6, 33.5, cy + s * 6, 32, cy + s * 11);
    }
  }
  if (tier >= 3) {
    // Tier 3: a helmet and a row of spikes down the back.
    g.fillStyle(INK, 1);
    g.fillEllipse(44, cy, 14, 18);
    g.fillStyle(steel, 1);
    g.fillEllipse(44, cy, 10, 14);
    for (const x of [8, 16, 24]) {
      g.fillStyle(INK, 1);
      g.fillTriangle(x - 3, cy, x + 3, cy, x, cy - 9);
      g.fillStyle(shine, 1);
      g.fillTriangle(x - 1.5, cy - 1, x + 1.5, cy - 1, x, cy - 6);
    }
  }
}

/** A boulder, drawn round so the art matches its collision circle (the Yard scales it to the rock's radius). */
function rock(g: G): void {
  const rng = new Phaser.Math.RandomDataGenerator(['rock-v1']);
  const ring = (r: number, jitter: number) => {
    const pts: Phaser.Math.Vector2[] = [];
    for (let i = 0; i < 12; i++) {
      const a = (i * Math.PI * 2) / 12;
      const rr = r + rng.realInRange(-jitter, jitter);
      pts.push(new Phaser.Math.Vector2(100 + Math.cos(a) * rr, 100 + Math.sin(a) * rr));
    }
    return pts;
  };
  const outer = ring(94, 3);
  g.fillStyle(INK, 1);
  g.fillPoints(outer, true);
  g.fillStyle(0x6e736b, 1);
  g.fillPoints(outer.map((p) => new Phaser.Math.Vector2(100 + (p.x - 100) * 0.93, 100 + (p.y - 100) * 0.93)), true);
  g.fillStyle(0x8f948b, 1);
  g.fillEllipse(92, 90, 150, 138);
  g.fillStyle(0xb9beb3, 1);
  g.fillEllipse(74, 66, 70, 40);
  g.lineStyle(5, INK, 0.8);
  bentLine(g, 112, 52, 124, 84, 114, 112);
  bentLine(g, 60, 122, 86, 132, 92, 154);
  g.fillStyle(0x5f8f4a, 1);
  for (const [x, y, r] of [[136, 132, 9], [148, 118, 6], [124, 146, 6], [52, 98, 5]]) g.fillCircle(x, y, r);
}

/** The Anteater from above, facing right: a bushy tail, a striped shoulder, a long snout. */
function anteater(g: G, frame: number): void {
  const cy = 60;
  const swing = frame === 0 ? 1 : -1;
  g.lineStyle(10, INK, 1);
  for (const s of [-1, 1]) {
    g.lineBetween(106, cy + s * 18, 112 + swing * s * 8, cy + s * 44);
    g.lineBetween(62, cy + s * 18, 56 - swing * s * 8, cy + s * 44);
  }
  blobEllipse(g, 34, cy, 66, 50, 0x5d4a3a);
  g.lineStyle(4, 0x3d2f24, 1);
  for (const x of [18, 30, 42]) g.lineBetween(x, cy - 18, x + 6, cy + 18);
  blobEllipse(g, 84, cy, 92, 64, 0x9c7a5b);
  g.lineStyle(12, INK, 1);
  g.lineBetween(98, cy - 28, 80, cy + 28);
  g.lineStyle(5, 0xf2e6d0, 1);
  g.lineBetween(104, cy - 24, 88, cy + 24);
  g.fillStyle(INK, 1);
  g.fillTriangle(116, cy - 16, 168, cy - 3, 116, cy + 16);
  g.fillTriangle(168, cy - 3, 168, cy + 3, 116, cy + 16);
  g.fillStyle(0xb08d6c, 1);
  g.fillTriangle(119, cy - 12, 163, cy - 1, 119, cy + 12);
  g.fillTriangle(163, cy - 1, 163, cy + 1, 119, cy + 12);
  blobCircle(g, 120, cy, 15, 0xa88565);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(126, cy + s * 7, 4);
    g.fillStyle(0x111111, 1);
    g.fillCircle(127.5, cy + s * 7, 2.2);
  }
}

/** Slice 3. The beetle from above, facing right: a domed shell split down the middle, a small head with two pincers. */
function beetle(g: G, frame: number): void {
  const cy = 32;
  sixLegs(g, 30, cy, 24, 4, frame);
  g.lineStyle(4, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 50, cy + s * 4, 58, cy + s * 9, 61, cy + s * 3);
  blobCircle(g, 50, cy, 8, 0x22382c);
  blobEllipse(g, 28, cy, 42, 38, 0x2f5d43);
  g.fillStyle(0x4f8f6a, 1);
  g.fillEllipse(24, cy - 7, 26, 12);
  g.fillStyle(0x9fd8b4, 0.9);
  g.fillEllipse(20, cy - 9, 12, 5);
  g.lineStyle(3, INK, 1);
  g.lineBetween(9, cy, 48, cy);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(53, cy + s * 4, 2.6);
    g.fillStyle(0x111111, 1);
    g.fillCircle(54, cy + s * 4, 1.4);
  }
}

/** The antlion from above, facing right: a fat sandy body and two huge curved pincers that open and close. */
function antlion(g: G, frame: number): void {
  const cy = 32;
  sixLegs(g, 26, cy, 15, 3, frame);
  const open = frame === 0 ? 1 : 0.45;
  g.lineStyle(5, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 40, cy + s * 4, 52, cy + s * (6 + 9 * open), 60, cy + s * (1 + 3 * open));
  g.lineStyle(2.5, 0xe9d3a3, 1);
  for (const s of [-1, 1]) bentLine(g, 41, cy + s * 4, 52, cy + s * (6 + 9 * open), 59, cy + s * (1 + 3 * open));
  blobEllipse(g, 20, cy, 32, 26, 0xa88552);
  g.fillStyle(0x7d5f34, 1);
  for (const x of [12, 19, 26]) g.fillEllipse(x, cy, 3, 20);
  blobCircle(g, 38, cy, 8, 0xc29c62);
  for (const s of [-1, 1]) {
    g.fillStyle(0x111111, 1);
    g.fillCircle(41, cy + s * 4, 2.2);
  }
}

/** The centipede's head, facing right: round, two long feelers and two fangs. */
function centipedeHead(g: G, frame: number): void {
  const cy = 22;
  const wave = frame === 0 ? 1 : -1;
  g.lineStyle(2.5, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 30, cy + s * 5, 38, cy + s * (9 + wave), 44, cy + s * (14 - wave));
  g.lineStyle(3.5, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 30, cy + s * 4, 35, cy + s * 4, 36, cy + s * 1);
  blobCircle(g, 22, cy, 12, 0xd0602f);
  g.fillStyle(0xf08a52, 1);
  g.fillEllipse(19, cy - 4, 10, 5);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(27, cy + s * 5, 3);
    g.fillStyle(0x111111, 1);
    g.fillCircle(28, cy + s * 5, 1.6);
  }
}

/** One body segment of the centipede, facing right, a pair of legs each side that swing by frame. */
function centipedeSegment(g: G, frame: number): void {
  const cy = 18;
  const swing = frame === 0 ? 3 : -3;
  g.lineStyle(3, INK, 1);
  for (const s of [-1, 1]) {
    g.lineBetween(18, cy + s * 4, 18 + swing * s, cy + s * 16);
    g.lineBetween(14, cy + s * 4, 14 - swing * s, cy + s * 15);
  }
  blobEllipse(g, 17, cy, 24, 22, 0xb84a24);
  g.fillStyle(0xe0743e, 1);
  g.fillEllipse(15, cy - 4, 12, 5);
}

/** A sand pit seen from above: rings of sand that darken toward a hole in the middle. */
function pit(g: G): void {
  const rings: Array<[number, number]> = [[72, 0xd9c08a], [60, 0xc9ab72], [46, 0xb8975e], [32, 0x9c7c48], [18, 0x6e5530], [9, 0x3d2e19]];
  for (const [r, c] of rings) {
    g.fillStyle(c, 1);
    g.fillEllipse(75, 75, r * 2, r * 1.8);
  }
  g.lineStyle(2, 0x8a6d40, 0.6);
  for (const r of [54, 40, 26]) g.strokeEllipse(75, 75, r * 2, r * 1.8);
}

/** The HUD's sound switch: a speaker with waves (sound on) or with a cross (muted), on a dark round tile. */
function soundIcon(g: G, on: boolean): void {
  g.fillStyle(0x000000, 0.55);
  g.fillRoundedRect(2, 2, 60, 60, 14);
  g.lineStyle(3, 0xffffff, 0.5);
  g.strokeRoundedRect(2, 2, 60, 60, 14);
  g.fillStyle(0xffffff, 1);
  g.fillRect(14, 25, 9, 14);
  g.fillTriangle(22, 25, 34, 15, 34, 49);
  g.fillTriangle(22, 39, 22, 25, 34, 49);
  if (on) {
    g.lineStyle(4, 0xffffff, 1);
    g.beginPath();
    g.arc(34, 32, 9, -0.9, 0.9);
    g.strokePath();
    g.beginPath();
    g.arc(34, 32, 16, -0.9, 0.9);
    g.strokePath();
  } else {
    g.lineStyle(5, 0xff6b5e, 1);
    g.lineBetween(39, 23, 53, 41);
    g.lineBetween(53, 23, 39, 41);
  }
}

/** Slice 4. The ember ant: an army ant's build in fire colours, its abdomen a glowing coal. */
function emberAnt(g: G, frame: number): void {
  const cy = 28;
  sixLegs(g, 27, cy, 16, 3.5, frame);
  g.lineStyle(3, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 40, cy + s * 3, 46, cy + s * 9, 51, cy + s * 10);
  blobEllipse(g, 14, cy, 22, 18, 0xd9480f);
  g.fillStyle(0xffb347, 1);
  g.fillEllipse(13, cy, 14, 10);
  g.fillStyle(0xfff3a0, 1);
  g.fillEllipse(12, cy, 6, 4);
  blobEllipse(g, 27, cy, 11, 9, 0x8f2a0a);
  blobCircle(g, 37, cy, 8.5, 0xb83a12);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(39.5, cy + s * 4, 3);
    g.fillStyle(0xffd000, 1);
    g.fillCircle(40.6, cy + s * 4, 1.5);
  }
}

/** The dusk moth from above: soft wide wings in two shades of violet that beat between the frames, a furry body. */
function duskMoth(g: G, frame: number): void {
  const cy = 30;
  const spread = frame === 0 ? 1 : 0.62;
  for (const s of [-1, 1]) {
    g.fillStyle(INK, 1);
    g.fillEllipse(26, cy + s * (10 + 9 * spread), 30, 10 + 14 * spread);
    g.fillStyle(0x7d6aa8, 1);
    g.fillEllipse(26, cy + s * (10 + 9 * spread), 26, 7 + 13 * spread);
    g.fillStyle(0xc9b8f0, 0.9);
    g.fillCircle(24, cy + s * (10 + 9 * spread), 3.5 + 1.5 * spread);
    g.fillStyle(INK, 1);
    g.fillCircle(24, cy + s * (10 + 9 * spread), 1.6);
  }
  blobEllipse(g, 28, cy, 30, 11, 0x5b4a7a);
  blobCircle(g, 44, cy, 6, 0x6e5c92);
  g.lineStyle(2, INK, 1);
  for (const s of [-1, 1]) bentLine(g, 48, cy + s * 2, 54, cy + s * 7, 58, cy + s * 9);
  for (const s of [-1, 1]) {
    g.fillStyle(0xffe680, 1);
    g.fillCircle(46.5, cy + s * 3, 1.8);
  }
}

/** The Scythe Mantis from above, facing right: a long green body, a small head and two big folded blades. */
function scytheMantis(g: G, frame: number): void {
  const cy = 55;
  const swing = frame === 0 ? 1 : -1;
  g.lineStyle(5, INK, 1);
  for (const s of [-1, 1]) {
    g.lineBetween(40, cy + s * 6, 30 + swing * s * 5, cy + s * 34);
    g.lineBetween(26, cy + s * 6, 12 - swing * s * 5, cy + s * 30);
  }
  blobEllipse(g, 28, cy, 52, 20, 0x3f8f3a);
  g.fillStyle(0x7fd06a, 1);
  g.fillEllipse(24, cy - 3, 30, 7);
  blobEllipse(g, 62, cy, 24, 12, 0x4aa543);
  for (const s of [-1, 1]) {
    g.lineStyle(8, INK, 1);
    bentLine(g, 66, cy + s * 5, 84, cy + s * 26, 100, cy + s * 12);
    g.lineStyle(4, 0xb6f09a, 1);
    bentLine(g, 66, cy + s * 5, 84, cy + s * 26, 100, cy + s * 12);
  }
  blobEllipse(g, 80, cy, 16, 20, 0x5cbf4f);
  for (const s of [-1, 1]) {
    g.fillStyle(0xfff36a, 1);
    g.fillCircle(84, cy + s * 8, 4.2);
    g.fillStyle(INK, 1);
    g.fillCircle(85.5, cy + s * 8, 1.8);
  }
}

/** The Brood Hornet from above: a big striped body in orange and black, a heavy sting, wide wings. */
function broodHornet(g: G, frame: number): void {
  const cy = 48;
  g.lineStyle(4, INK, 1);
  for (const s of [-1, 1]) {
    g.lineBetween(52, cy + s * 5, 62, cy + s * 20);
    g.lineBetween(46, cy + s * 5, 40, cy + s * 21);
  }
  g.fillStyle(INK, 1);
  g.fillTriangle(0, cy, 12, cy - 6, 12, cy + 6);
  blobEllipse(g, 28, cy, 42, 30, 0xff9f1c);
  g.fillStyle(0x1b1209, 1);
  g.fillEllipse(22, cy, 7, 26);
  g.fillEllipse(33, cy, 7, 27);
  blobEllipse(g, 55, cy, 20, 20, 0x3a240c);
  blobCircle(g, 71, cy, 12, 0xffa51f);
  for (const s of [-1, 1]) {
    g.fillStyle(0x161616, 1);
    g.fillEllipse(75, cy + s * 6, 9, 7);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(77, cy + s * 6 - 1.5, 1.4);
  }
  const spread = frame === 0 ? 1 : 0.5;
  for (const s of [-1, 1]) {
    g.fillStyle(0xffffff, 0.5);
    g.fillEllipse(48, cy + s * (13 + 11 * spread), 38, 9 + 9 * spread);
    g.lineStyle(2.5, 0xdfe9ff, 0.95);
    g.strokeEllipse(48, cy + s * (13 + 11 * spread), 38, 9 + 9 * spread);
  }
}

export function makeTextures(scene: Phaser.Scene): void {
  make(scene, 'puddle', 128, 128, puddle);
  make(scene, 'steam', 160, 160, steam);
  for (const t of [1, 2, 3]) make(scene, `plates${t}`, 64, 64, (g) => plates(g, t));
  for (const f of [0, 1]) {
    make(scene, `ember${f}`, 56, 56, (g) => emberAnt(g, f));
    make(scene, `moth${f}`, 64, 64, (g) => duskMoth(g, f));
    make(scene, `mantis${f}`, 112, 112, (g) => scytheMantis(g, f));
    make(scene, `hornet${f}`, 96, 96, (g) => broodHornet(g, f));
  }
  make(scene, 'pit', 150, 150, pit);
  make(scene, 'ring', 64, 64, (g) => {
    g.lineStyle(6, 0xffffff, 1);
    g.strokeCircle(32, 32, 26);
  });
  make(scene, 'sound_on', 64, 64, (g) => soundIcon(g, true));
  make(scene, 'sound_off', 64, 64, (g) => soundIcon(g, false));

  for (const f of [0, 1]) {
    make(scene, `beetle${f}`, 64, 64, (g) => beetle(g, f));
    make(scene, `antlion${f}`, 64, 64, (g) => antlion(g, f));
    make(scene, `centipede${f}`, 44, 44, (g) => centipedeHead(g, f));
    make(scene, `centSeg${f}`, 36, 36, (g) => centipedeSegment(g, f));
  }

  for (const p of POWERS) make(scene, `pow_${p.id}`, 64, 64, (g) => powerIcon(g, p.id, p.color));
  make(scene, 'rock', 200, 200, rock);
  for (const f of [0, 1]) make(scene, `anteater${f}`, 172, 120, (g) => anteater(g, f));
  for (const f of [0, 1]) {
    make(scene, `ant${f}`, 64, 64, (g) => hero(g, f));
    make(scene, `armyAnt${f}`, 56, 56, (g) => armyAnt(g, f));
    make(scene, `wasp${f}`, 60, 60, (g) => wasp(g, f));
    make(scene, `spider${f}`, 64, 64, (g) => spider(g, f));
    make(scene, `termite${f}`, 36, 36, (g) => termite(g, f));
  }

  make(scene, 'dart', 28, 10, (g) => {
    g.fillStyle(INK, 1);
    g.fillTriangle(16, 0, 28, 5, 16, 10);
    g.fillRect(0, 2, 18, 6);
    g.fillStyle(0xfff3b0, 1);
    g.fillTriangle(17, 2, 26, 5, 17, 8);
    g.fillRect(1, 3.5, 17, 3);
  });
  make(scene, 'sting', 18, 8, (g) => {
    g.fillStyle(INK, 1);
    g.fillTriangle(0, 0.5, 18, 4, 0, 7.5);
    g.fillStyle(0xff6a2a, 1);
    g.fillTriangle(1.5, 2, 15, 4, 1.5, 6);
  });
  make(scene, 'web', 22, 22, (g) => {
    g.lineStyle(2, 0xffffff, 0.95);
    for (let i = 0; i < 4; i++) {
      const a = (i * Math.PI) / 4;
      g.lineBetween(11 - Math.cos(a) * 10, 11 - Math.sin(a) * 10, 11 + Math.cos(a) * 10, 11 + Math.sin(a) * 10);
    }
    g.strokeCircle(11, 11, 5.5);
    g.strokeCircle(11, 11, 9);
    g.fillStyle(0xffffff, 0.55);
    g.fillCircle(11, 11, 3.5);
  });
  make(scene, 'bead', 20, 22, (g) => {
    g.fillStyle(INK, 1);
    g.fillCircle(10, 13.5, 8);
    g.fillTriangle(10, 0, 2.6, 11, 17.4, 11);
    g.fillStyle(0xffc93c, 1);
    g.fillCircle(10, 13.5, 6);
    g.fillTriangle(10, 3, 4.6, 11.5, 15.4, 11.5);
    g.fillStyle(0xffffff, 0.9);
    g.fillCircle(8, 12.5, 2);
  });
  make(scene, 'jelly', 32, 32, (g) => {
    g.fillStyle(0xff7eb6, 1);
    g.fillCircle(16, 17, 13.5);
    g.fillStyle(0xfff0f7, 1);
    g.fillCircle(16, 17, 10.5);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(12, 13, 3.5);
  });
  make(scene, 'crown', 36, 28, (g) => {
    const pts = [
      new Phaser.Math.Vector2(3, 25), new Phaser.Math.Vector2(3, 8), new Phaser.Math.Vector2(11, 16),
      new Phaser.Math.Vector2(18, 3), new Phaser.Math.Vector2(25, 16), new Phaser.Math.Vector2(33, 8),
      new Phaser.Math.Vector2(33, 25),
    ];
    g.fillStyle(0xffd84a, 1);
    g.fillPoints(pts, true);
    g.lineStyle(3, INK, 1);
    g.strokePoints(pts, true);
    g.fillStyle(0xe8304a, 1);
    g.fillCircle(18, 19, 3.2);
  });
  make(scene, 'puff', 12, 12, (g) => {
    g.fillStyle(0xffffff, 1);
    g.fillCircle(6, 6, 6);
  });
  make(scene, 'arrow', 44, 44, (g) => {
    g.fillStyle(INK, 1);
    g.fillTriangle(4, 4, 42, 22, 4, 40);
    g.fillStyle(0xffe07a, 1);
    g.fillTriangle(9, 11, 33, 22, 9, 33);
  });
  make(scene, 'hole', 72, 46, (g) => {
    g.fillStyle(0x5a3b1e, 1);
    g.fillEllipse(36, 23, 70, 44);
    g.fillStyle(0x2a1a0c, 1);
    g.fillEllipse(36, 25, 48, 28);
    g.fillStyle(0x120a04, 1);
    g.fillEllipse(36, 27, 32, 17);
  });
  make(scene, 'nest', 220, 220, (g) => {
    const rng = new Phaser.Math.RandomDataGenerator(['nest-v1']);
    g.fillStyle(0x5e3d1d, 1);
    g.fillCircle(110, 110, 104);
    g.fillStyle(0x7a5230, 1);
    g.fillCircle(110, 110, 92);
    g.fillStyle(0x93653a, 1);
    g.fillCircle(110, 106, 74);
    g.fillStyle(0xa87a48, 1);
    g.fillCircle(108, 100, 52);
    for (let i = 0; i < 70; i++) {
      const a = rng.realInRange(0, Math.PI * 2);
      const r = rng.realInRange(20, 98);
      g.fillStyle(rng.pick([0x4d3118, 0xb88a56, 0x6b4726]), 1);
      g.fillCircle(110 + Math.cos(a) * r, 110 + Math.sin(a) * r, rng.realInRange(1.5, 4));
    }
    g.fillStyle(0x2a1a0c, 1);
    g.fillEllipse(110, 112, 48, 32);
    g.fillStyle(0x120a04, 1);
    g.fillEllipse(110, 115, 32, 19);
  });
  make(scene, 'grass', 256, 256, (g) => {
    const rng = new Phaser.Math.RandomDataGenerator(['grass-v1']);
    g.fillStyle(0x4f9a3c, 1);
    g.fillRect(0, 0, 256, 256);
    for (let i = 0; i < 14; i++) {
      const x = rng.between(0, 255);
      const y = rng.between(0, 255);
      const r = rng.between(14, 34);
      g.fillStyle(rng.pick([0x58a344, 0x47903a]), 0.45);
      for (const ox of [-256, 0, 256]) for (const oy of [-256, 0, 256]) g.fillCircle(x + ox, y + oy, r);
    }
    for (let i = 0; i < 280; i++) {
      const x = rng.between(4, 251);
      const y = rng.between(12, 251);
      g.lineStyle(2, rng.pick([0x458a33, 0x5aab45, 0x3f7f2f, 0x66b84f]), 0.9);
      g.lineBetween(x, y, x + rng.between(-3, 3), y - rng.between(5, 11));
    }
  });
  make(scene, 'tuft', 26, 20, (g) => {
    g.lineStyle(3, 0x2f6d24, 1);
    for (const [x, y] of [[5, 4], [10, 1], [15, 2], [21, 5]]) g.lineBetween(13, 19, x, y);
  });
  make(scene, 'clover', 28, 28, (g) => {
    for (let i = 0; i < 3; i++) {
      const a = -Math.PI / 2 + (i * Math.PI * 2) / 3;
      g.fillStyle(0x3f8f35, 1);
      g.fillCircle(14 + Math.cos(a) * 6, 14 + Math.sin(a) * 6, 6.5);
      g.fillStyle(0x6cc05a, 1);
      g.fillCircle(14 + Math.cos(a) * 6, 14 + Math.sin(a) * 6, 2.5);
    }
  });
  make(scene, 'pebble', 22, 16, (g) => {
    g.fillStyle(0x7d827a, 1);
    g.fillEllipse(11, 8, 21, 14);
    g.fillStyle(0xb5b9b0, 1);
    g.fillEllipse(8, 6, 8, 4);
  });
  make(scene, 'flower', 26, 26, (g) => {
    for (let i = 0; i < 5; i++) {
      const a = (i * Math.PI * 2) / 5;
      g.fillStyle(0xffffff, 1);
      g.fillCircle(13 + Math.cos(a) * 6.5, 13 + Math.sin(a) * 6.5, 5);
    }
    g.fillStyle(0xffcf33, 1);
    g.fillCircle(13, 13, 4.2);
  });
}
