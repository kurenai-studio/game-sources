const W = 480, H = 270;
const PLAY_X0 = 136, PLAY_X1 = 343;          // 208 px of playfield, centred
const LEFT_RULE = 135, RIGHT_RULE = 344;

// The framebuffer holds palette indices, not colours. That is what lets the page prove no pixel
// escaped ls32 and colour every pixel by the set it belongs to.
class Fb {
  // Defaults to the whole screen; the reference sheet asks for one the size of a single sprite.
  constructor(w, h) {
    this.w = w || W; this.h = h || H;
    this.d = new Int16Array(this.w * this.h).fill(0);
  }
  px(x, y, c) {
    if (c < 0 || x < 0 || y < 0 || x >= this.w || y >= this.h) return;
    this.d[y * this.w + x] = c;
  }
  at(x, y) { return this.d[y * this.w + x]; }
  rect(x, y, w, h, c) {
    for (let j = 0; j < h; j++) for (let i = 0; i < w; i++) this.px(x + i, y + j, c);
  }
  frame(x, y, w, h, c) {
    for (let i = 0; i < w; i++) { this.px(x + i, y, c); this.px(x + i, y + h - 1, c); }
    for (let j = 0; j < h; j++) { this.px(x, y + j, c); this.px(x + w - 1, y + j, c); }
  }
  // step 2 gives a 50 % checker, which is the only dithering the direction allows, and only in
  // background layers where it does not move.
  dither(x, y, w, h, c, step) {
    for (let j = 0; j < h; j++) {
      for (let i = 0; i < w; i++) if ((i + j) % step === 0) this.px(x + i, y + j, c);
    }
  }
  blit(id, cx, cy, mode) {
    const s = SPRITES[id];
    const x0 = cx - ((s.w - 1) >> 1), y0 = cy - ((s.h - 1) >> 1);
    for (let j = 0; j < s.h; j++) {
      for (let i = 0; i < s.w; i++) {
        const ch = s.art[j][i];
        const c = CHARS[ch];
        if (c < 0) continue;
        if (mode === 'hollow') { if (ch !== 'k') continue; this.px(x0 + i, y0 + j, 3); }
        // The blink is a batch tint in the real renderer; an indexed framebuffer has no alpha, so
        // the mock stands in for it with a checker. What it communicates is the same.
        else if (mode === 'dither' && (i + j) % 2 === 0) continue;
        else this.px(x0 + i, y0 + j, c);
      }
    }
  }
  text5(str, x, y, c) {
    let cx = x;
    for (const ch of str) {
      const g = FONT5[ch] || FONT5[' '];
      // g is 7 rows, or 9 when the glyph descends. Reading its length is what keeps the two cases
      // from needing two code paths, here and in the real loader.
      for (let j = 0; j < g.length; j++) {
        for (let i = 0; i < 5; i++) if (g[j] & (1 << (4 - i))) this.px(cx + i, y + j, c);
      }
      cx += 6;
    }
  }
  text7(str, x, y, c) {
    let cx = x;
    for (const ch of str.toUpperCase()) {
      const g = FONT7[ch];
      if (g) {
        for (let j = 0; j < 11; j++) {
          for (let i = 0; i < 7; i++) if (g[j] & (1 << (6 - i))) this.px(cx + i, y + j, c);
        }
      }
      cx += 8;
    }
  }
  ellipse(cx, cy, rx, ry, c) {
    for (let j = -ry; j <= ry; j++) {
      for (let i = -rx; i <= rx; i++) {
        if ((i * i) / (rx * rx) + (j * j) / (ry * ry) <= 1) this.px(cx + i, cy + j, c);
      }
    }
  }
}

// Seeded so the city is the same city every time the page loads. Same reason the core has an Rng.
function rng(seed) {
  let s = seed >>> 0;
  return () => { s ^= s << 13; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s / 4294967296; };
}

// A city seen from above: blocks, streets, rooftops and fires. Background-legal colours only, and
// no detail that competes with the playfield - that is R7 and R8 doing their job.
function drawCity(fb, scroll) {
  fb.rect(PLAY_X0, 0, 208, H, 1);
  const r = rng(0x5EED);
  const blocks = [];
  for (let i = 0; i < 46; i++) {
    blocks.push({
      x: PLAY_X0 + 4 + Math.floor(r() * 190),
      y: Math.floor(r() * 640),
      w: 14 + Math.floor(r() * 34),
      h: 16 + Math.floor(r() * 40),
      lit: r() < 0.30,
      fire: r() < 0.22
    });
  }
  // Streets first, so the blocks sit on top of them.
  for (let y = -(scroll % 46); y < H; y += 46) fb.rect(PLAY_X0, y, 208, 3, 2);
  for (let x = PLAY_X0 + 18; x < PLAY_X1; x += 52) fb.rect(x, 0, 3, H, 2);

  for (const b of blocks) {
    const y = ((b.y - scroll) % 640 + 640) % 640 - 60;
    if (y > H || y + b.h < 0) continue;
    fb.rect(b.x, y, b.w, b.h, 2);
    fb.frame(b.x, y, b.w, b.h, 3);
    // Rooftop detail: skylights and vents, never brighter than N4.
    for (let j = 3; j < b.h - 3; j += 5) {
      for (let i = 3; i < b.w - 3; i += 6) fb.rect(b.x + i, y + j, 3, 2, b.lit ? 9 : 8);
    }
    if (b.fire) {
      fb.ellipse(b.x + (b.w >> 1), y + (b.h >> 1), 5, 4, 10);
      fb.ellipse(b.x + (b.w >> 1), y + (b.h >> 1), 3, 2, 11);
      fb.dither(b.x + (b.w >> 1) - 7, y + (b.h >> 1) - 6, 14, 12, 10, 3);
    }
  }
  // Smoke drifting over the city, the closest and plainest layer.
  const r2 = rng(0xC0FFEE);
  for (let i = 0; i < 9; i++) {
    const x = PLAY_X0 + 6 + Math.floor(r2() * 190);
    const y = ((Math.floor(r2() * 500) - scroll * 1.6) % 500 + 500) % 500 - 90;
    fb.dither(x, y, 26 + Math.floor(r2() * 20), 16, 3, 3);
  }
}

function drawHud(fb, st) {
  fb.rect(0, 0, LEFT_RULE, H, 2);
  fb.rect(RIGHT_RULE + 1, 0, W - RIGHT_RULE - 1, H, 2);
  const ruleColour = st.hitFlash ? 20 : 3;
  fb.rect(LEFT_RULE, 0, 1, H, ruleColour);
  fb.rect(RIGHT_RULE, 0, 1, H, ruleColour);

  fb.text5('LIVES', 12, 14, 4);
  for (let i = 0; i < 5; i++) fb.blit('icon-life', 12 + i * 12 + 4, 24 + 4, i < st.lives ? 'full' : 'hollow');

  fb.text5('BOMBS', 12, 44, 4);
  for (let i = 0; i < 3; i++) fb.blit('icon-bomb', 12 + i * 12 + 4, 54 + 4, i < st.bombs ? 'full' : 'hollow');

  fb.text5('POWER', 12, 74, 4);
  for (let i = 0; i < 4; i++) {
    const x = 12 + i * 15;
    if (i < st.power) { fb.rect(x, 84, 13, 7, 21); fb.rect(x, 84, 13, 1, 22); fb.frame(x, 84, 13, 7, 0); }
    else { fb.rect(x, 84, 13, 7, 2); fb.frame(x, 84, 13, 7, 3); }
  }

  fb.text5('STATE', 12, 104, 4);
  if (st.shield) fb.blit('icon-shield', 12 + 6, 114 + 6, 'full');
  if (st.invulnPickup > 0) {
    fb.blit('icon-invuln', 28 + 6, 114 + 6, 'full');
    fb.rect(28, 128, 13, 1, 2);
    fb.rect(28, 128, Math.round(13 * st.invulnPickup), 1, 25);
  }

  if (st.module) {
    fb.text5('MODULE', 12, 146, 4);
    fb.blit('icon-module', 12 + 8, 156 + 8, 'full');
    fb.text5(st.module, 34, 161, 20);
  }

  fb.text5('SCORE', 362, 14, 4);
  fb.text7(String(st.score).padStart(7, '0'), 412, 24, 20);

  if (st.boss) {
    fb.text5('BOSS', 362, 44, 4);
    fb.frame(347, 20, 8, 230, 0);
    fb.rect(348, 21, 6, 228, 2);
    const rows = Math.round(228 * st.bossHp);
    fb.rect(348, 21, 6, rows, 24);
    fb.rect(353, 21, 1, rows, 23);
  }
}
