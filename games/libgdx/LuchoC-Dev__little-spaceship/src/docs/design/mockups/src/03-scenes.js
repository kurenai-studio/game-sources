// The carrier and the boss are drawn from primitives rather than character art: at 39x31 and
// 119x87 a hand-typed grid is a transcription error waiting to happen, and what matters here is
// the footprint. Both keep the outline every gameplay sprite must carry.
function drawCarrier(fb, cx, cy) {
  fb.ellipse(cx, cy, 16, 16, 0);
  fb.ellipse(cx, cy, 15, 15, 28);
  fb.rect(cx - 20, cy - 3, 7, 5, 0);
  fb.rect(cx + 14, cy - 3, 7, 5, 0);
  fb.rect(cx - 19, cy - 2, 5, 3, 18);
  fb.rect(cx + 15, cy - 2, 5, 3, 18);
  fb.ellipse(cx, cy - 1, 9, 8, 19);
  fb.ellipse(cx, cy - 1, 5, 5, 24);
  fb.ellipse(cx, cy - 1, 2, 2, 25);
  fb.rect(cx - 9, cy + 12, 3, 4, 0);
  fb.rect(cx + 7, cy + 12, 3, 4, 0);
  fb.rect(cx - 8, cy + 13, 1, 3, 24);
  fb.rect(cx + 8, cy + 13, 1, 3, 24);
}

function drawBoss(fb, cx, cy) {
  fb.ellipse(cx - 44, cy + 20, 16, 15, 0);
  fb.ellipse(cx + 44, cy + 20, 16, 15, 0);
  fb.ellipse(cx - 44, cy + 20, 15, 14, 28);
  fb.ellipse(cx + 44, cy + 20, 15, 14, 28);
  fb.ellipse(cx - 34, cy - 6, 14, 13, 0);
  fb.ellipse(cx + 34, cy - 6, 14, 13, 0);
  fb.ellipse(cx - 34, cy - 6, 13, 12, 28);
  fb.ellipse(cx + 34, cy - 6, 13, 12, 28);
  fb.ellipse(cx, cy - 2, 60, 39, 0);
  fb.ellipse(cx, cy - 2, 59, 38, 28);
  fb.ellipse(cx, cy - 4, 42, 24, 18);
  fb.ellipse(cx, cy - 8, 20, 17, 0);
  fb.ellipse(cx, cy - 8, 19, 16, 19);
  fb.ellipse(cx, cy - 8, 13, 11, 24);
  fb.ellipse(cx, cy - 8, 7, 6, 25);
  for (const s of [-1, 1]) {
    fb.rect(cx + s * 34 - 2, cy + 6, 4, 8, 0);
    fb.rect(cx + s * 34 - 1, cy + 7, 2, 7, 24);
    fb.rect(cx + s * 44 - 2, cy + 33, 4, 6, 0);
    fb.rect(cx + s * 44 - 1, cy + 34, 2, 5, 24);
  }
}

// One concrete moment of level 1 rather than a neutral arrangement: the pressure escalation, a
// tank and a carrier on screen at once, the player at weapon level 2 with a shield and missiles.
const SCENES = {
  escalation: {
    label: 'Pressure escalation',
    note: 'Two archetypes the player must prioritise between, mid-density enemy fire, a guaranteed drop falling.',
    hud: { lives: 3, bombs: 2, power: 2, shield: true, invulnPickup: 0, module: 'MISSILES', score: 12500, boss: false, bossHp: 1, hitFlash: false },
    player: { x: 240, y: 208, state: 'normal' },
    enemies: [
      ['enemy-tank', 196, 58], ['enemy-basic', 158, 44], ['enemy-basic', 178, 30],
      ['enemy-basic', 138, 30], ['enemy-light', 306, 72], ['enemy-light', 326, 52],
      ['enemy-rush', 274, 118], ['enemy-shooter', 240, 22]
    ],
    carrier: [312, 150],
    shots: [['shot-p1', 233, 178], ['shot-p1', 247, 178], ['shot-p1', 233, 148], ['shot-p1', 247, 148]],
    fire: [
      ['shot-e-small', 200, 96], ['shot-e-small', 210, 110], ['shot-e-small', 190, 110],
      ['shot-e-small', 168, 78], ['shot-e-small', 300, 104], ['shot-e-small', 318, 88],
      ['shot-e-heavy', 240, 132], ['shot-e-heavy', 196, 148], ['shot-e-bolt', 262, 92],
      ['shot-e-bolt', 288, 138], ['shot-e-small', 152, 128], ['shot-e-small', 160, 162],
      ['shot-e-small', 330, 128], ['shot-e-heavy', 276, 176], ['shot-e-small', 214, 186]
    ],
    pickups: [['pickup-weapon', 172, 140]]
  },
  boss: {
    label: 'Boss fight',
    note: 'The bar appears in the right margin. The boss is 119 px of the 208 px playfield, and the gaps between its parts are where the player lives.',
    hud: { lives: 2, bombs: 1, power: 4, shield: false, invulnPickup: 0, module: 'MISSILES', score: 48300, boss: true, bossHp: 0.62, hitFlash: false },
    player: { x: 228, y: 218, state: 'normal' },
    enemies: [],
    boss: [240, 62],
    shots: [['shot-p2', 228, 186], ['shot-p1', 216, 178], ['shot-p1', 240, 178], ['shot-p2', 228, 152]],
    fire: [
      ['shot-e-heavy', 190, 130], ['shot-e-heavy', 240, 140], ['shot-e-heavy', 290, 130],
      ['shot-e-small', 168, 152], ['shot-e-small', 196, 166], ['shot-e-small', 224, 174],
      ['shot-e-small', 256, 174], ['shot-e-small', 284, 166], ['shot-e-small', 312, 152],
      ['shot-e-bolt', 152, 118], ['shot-e-bolt', 328, 118], ['shot-e-small', 206, 196],
      ['shot-e-small', 274, 196], ['shot-e-small', 240, 202]
    ],
    pickups: []
  },
  hit: {
    label: 'Just took a hit',
    note: 'Respawn invulnerability on the ship, the playfield rules flashing, one life gone and the shield with it.',
    hud: { lives: 2, bombs: 2, power: 2, shield: false, invulnPickup: 0.7, module: null, score: 12500, boss: false, bossHp: 1, hitFlash: true },
    player: { x: 240, y: 208, state: 'blink' },
    enemies: [
      ['enemy-tank', 196, 58], ['enemy-basic', 158, 44], ['enemy-basic', 178, 30],
      ['enemy-light', 306, 72], ['enemy-rush', 274, 118]
    ],
    shots: [],
    fire: [
      ['shot-e-small', 200, 96], ['shot-e-small', 210, 110], ['shot-e-heavy', 240, 132],
      ['shot-e-bolt', 262, 92], ['shot-e-small', 152, 128], ['shot-e-small', 330, 128]
    ],
    pickups: []
  }
};

function renderScene(key, scroll) {
  const sc = SCENES[key];
  const fb = new Fb();
  drawCity(fb, scroll);
  for (const [id, x, y] of sc.pickups) fb.blit(id, x, y, 'full');
  if (sc.carrier) drawCarrier(fb, sc.carrier[0], sc.carrier[1]);
  if (sc.boss) drawBoss(fb, sc.boss[0], sc.boss[1]);
  for (const [id, x, y] of sc.enemies) fb.blit(id, x, y, 'full');
  for (const [id, x, y] of sc.shots) fb.blit(id, x, y, 'full');
  fb.blit('ship-basic', sc.player.x, sc.player.y, sc.player.state === 'blink' ? 'dither' : 'full');
  for (const [id, x, y] of sc.fire) fb.blit(id, x, y, 'full');
  drawHud(fb, sc.hud);
  return fb;
}

// Every collider in the scene, for the hitbox overlay. It is drawn over the scaled canvas rather
// than into the framebuffer: it is instrumentation, not art, and it must not pretend to be pixels.
function colliders(key) {
  const sc = SCENES[key], out = [];
  for (const [id, x, y] of sc.enemies) out.push({ x, y, r: SPRITES[id].r, kind: 'enemy' });
  for (const [id, x, y] of sc.shots) out.push({ x, y, r: SPRITES[id].r, kind: 'player' });
  for (const [id, x, y] of sc.fire) out.push({ x, y, r: SPRITES[id].r, kind: 'hostile' });
  for (const [id, x, y] of sc.pickups) out.push({ x, y, r: SPRITES[id].r, kind: 'pickup' });
  if (sc.carrier) out.push({ x: sc.carrier[0], y: sc.carrier[1], r: 15, kind: 'enemy' });
  if (sc.boss) {
    const [bx, by] = sc.boss;
    out.push({ x: bx, y: by, r: 18, kind: 'enemy' });
    out.push({ x: bx - 34, y: by - 6, r: 12, kind: 'enemy' });
    out.push({ x: bx + 34, y: by - 6, r: 12, kind: 'enemy' });
    out.push({ x: bx - 44, y: by + 18, r: 14, kind: 'enemy' });
    out.push({ x: bx + 44, y: by + 18, r: 14, kind: 'enemy' });
  }
  out.push({ x: sc.player.x, y: sc.player.y, r: SPRITES['ship-basic'].r, kind: 'player' });
  return out;
}
