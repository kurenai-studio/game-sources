const state = { view: 'normal', zoom: 4, hitbox: true, silhouette: false };

const TOGGLES = [
  ['hitbox', 'Colliders', 'what the code sees'],
  ['silhouette', 'Silhouettes', 'R16, flat black']
];

// Grouped by role rather than by size, because that is how the art lane works through them: the
// player first, then what it shoots, then what shoots back.
const SHEET = [
  ['Player', [
    { id: 'ship-basic', label: 'Ship', note: 'the 6 px circle is the fuselage, not the wings' },
    { id: 'icon-module', label: 'Attachment icon', note: 'HUD only, no collider' }
  ]],
  ['Player fire', [
    { id: 'shot-p1', label: 'Shot, level 1-2', note: 'one, then two of them' },
    { id: 'shot-p2', label: 'Shot, level 3-4', note: 'the wide one joins at level 3' }
  ]],
  ['Enemies', [
    { id: 'enemy-basic', label: 'Basic', note: '' },
    { id: 'enemy-light', label: 'Fast light', note: '' },
    { id: 'enemy-shooter', label: 'Evolved / shooter', note: '' },
    { id: 'enemy-rush', label: 'Super-fast', note: '' },
    { id: 'enemy-tank', label: 'Tank', note: 'a different class of problem on sight' },
    { proc: 'carrier', w: 39, h: 31, r: 15, label: 'Heavy carrier', note: 'the outer 4 px each side are wing, and must be drawn as wing' },
    { proc: 'boss', w: 119, h: 87, label: 'Boss', note: 'five colliders, not one', parts: [[0, 0, 18], [-34, -6, 12], [34, -6, 12], [-44, 18, 14], [44, 18, 14]] }
  ]],
  ['Enemy fire', [
    { id: 'shot-e-small', label: 'Bullet, small', note: 'never smaller than this' },
    { id: 'shot-e-heavy', label: 'Bullet, heavy', note: '' },
    { id: 'shot-e-bolt', label: 'Aimed bolt', note: '' }
  ]],
  ['Pickups and HUD', [
    { id: 'pickup-weapon', label: 'Power-up capsule', note: 'collides larger than it looks, on purpose' },
    { id: 'icon-life', label: 'Life slot', note: '' },
    { id: 'icon-bomb', label: 'Bomb slot', note: '' },
    { id: 'icon-shield', label: 'Shield', note: '' },
    { id: 'icon-invuln', label: 'Invulnerability', note: '' }
  ]]
];

const RAMPS = [
  ['Human metal', [3, 18, 19, 20]],
  ['Alien hull', [14, 15, 28]],
  ['Fire and explosion', [10, 11, 23, 24, 25]],
  ['Player energy', [21, 22]],
  ['Pickup', [12, 26, 27]],
  ['Enemy fire — reserved', [29, 30, 31]],
  ['Night and depth', [5, 6, 7]],
  ['Structure', [0, 1, 2, 3, 4]]
];

function fbFor(item) {
  if (item.proc) return state.silhouette ? proceduralSilhouette(item.proc) : proceduralFb(item.proc);
  return state.silhouette ? silhouetteFb(item.id) : spriteFb(item.id);
}

function sizeOf(item) {
  return item.proc ? { w: item.w, h: item.h, r: item.r } : SPRITES[item.id];
}

function card(item) {
  const size = sizeOf(item);
  const wrap = document.createElement('div');
  wrap.className = 'card';

  const canvas = document.createElement('canvas');
  blitTo(canvas, fbFor(item), state.view, state.zoom);
  if (state.hitbox) {
    const ctx = canvas.getContext('2d');
    ctx.lineWidth = Math.max(1, state.zoom * 0.4);
    ctx.strokeStyle = 'rgba(255,201,74,.95)';
    const cx = ((size.w - 1) / 2 + 0.5) * state.zoom, cy = ((size.h - 1) / 2 + 0.5) * state.zoom;
    const parts = item.parts || (size.r ? [[0, 0, size.r]] : []);
    for (const [ox, oy, r] of parts) {
      ctx.beginPath();
      ctx.arc(cx + ox * state.zoom, cy + oy * state.zoom, r * state.zoom, 0, Math.PI * 2);
      ctx.stroke();
    }
  }

  const shell = document.createElement('div');
  shell.className = 'art';
  shell.appendChild(canvas);
  wrap.appendChild(shell);

  const meta = document.createElement('div');
  meta.className = 'meta';
  const radius = item.parts ? '5 parts' : (size.r ? 'r ' + size.r.toFixed(1) : 'no collider');
  meta.innerHTML = '<b>' + item.label + '</b><code>' + size.w + '×' + size.h + '</code>' +
    '<code>' + radius + '</code>' + (item.note ? '<small>' + item.note + '</small>' : '');
  wrap.appendChild(meta);
  return wrap;
}

function buildSheet() {
  const host = document.getElementById('sheet');
  host.textContent = '';
  for (const [group, items] of SHEET) {
    const section = document.createElement('div');
    section.className = 'sheet-group';
    const heading = document.createElement('span');
    heading.className = 'group-label';
    heading.textContent = group;
    section.appendChild(heading);
    const grid = document.createElement('div');
    grid.className = 'grid';
    for (const item of items) grid.appendChild(card(item));
    section.appendChild(grid);
    host.appendChild(section);
  }
}

function buildSilhouettes() {
  const host = document.getElementById('silhouettes');
  host.textContent = '';
  const ids = ['enemy-basic', 'enemy-light', 'enemy-shooter', 'enemy-rush', 'enemy-tank'];
  for (const id of ids) {
    const wrap = document.createElement('div');
    wrap.className = 'shot';
    const canvas = document.createElement('canvas');
    blitTo(canvas, silhouetteFb(id), state.view, 3);
    wrap.appendChild(canvas);
    const label = document.createElement('span');
    label.textContent = id.replace('enemy-', '');
    wrap.appendChild(label);
    host.appendChild(wrap);
  }
  for (const proc of ['carrier', 'boss']) {
    const wrap = document.createElement('div');
    wrap.className = 'shot';
    const canvas = document.createElement('canvas');
    blitTo(canvas, proceduralSilhouette(proc), state.view, proc === 'boss' ? 1 : 3);
    wrap.appendChild(canvas);
    const label = document.createElement('span');
    label.textContent = proc;
    wrap.appendChild(label);
    host.appendChild(wrap);
  }
}

function buildPalette() {
  const groups = [['Background-legal', BACKGROUND], ['Gameplay-only', GAMEPLAY],
    ['Reserved — enemy fire', HOSTILE], ['Shared outline', OUTLINE]];
  document.getElementById('palette').innerHTML = groups.map(([label, kind]) => {
    const cells = PALETTE.map((hex, i) => i).filter(i => CLASSES[i] === kind).map(i =>
      '<div class="chip"><i style="background:' + PALETTE[i] + '"></i>' +
      '<b>' + NAMES[i] + '</b><code>' + PALETTE[i] + '</code>' +
      '<small>L* ' + LSTAR[i].toFixed(1) + '</small></div>').join('');
    return '<div class="sheet-group"><span class="group-label">' + label +
      '</span><div class="chips">' + cells + '</div></div>';
  }).join('');
}

function buildRamps() {
  document.getElementById('ramps').innerHTML = RAMPS.map(([label, ids]) =>
    '<div class="ramp-row"><span>' + label + '</span><div class="ramp-strip">' +
    ids.map(i => '<i style="background:' + PALETTE[i] + '" title="' + NAMES[i] + ' ' +
      PALETTE[i] + '"></i>').join('') + '</div><code>' +
    ids.map(i => NAMES[i]).join(' → ') + '</code></div>').join('');
}

function buildFonts() {
  const host = document.getElementById('fonts');
  host.textContent = '';
  const specs = [
    ['mini', 'font-mini', '5×7 glyph, 6 px advance, 10 px line, descenders 2 px'],
    ['title', 'font-title', '7×11 glyph, 8 px advance, digits only in the HUD']
  ];
  for (const [which, name, note] of specs) {
    const wrap = document.createElement('div');
    wrap.className = 'font-block';
    const canvas = document.createElement('canvas');
    blitTo(canvas, fontSheetFb(which), state.view, 4);
    wrap.innerHTML = '<b>' + name + '</b><small>' + note + '</small>';
    wrap.appendChild(canvas);
    host.appendChild(wrap);
  }
}

// The sheet is generated from the same tables the game will be drawn from, so the thing worth
// checking is that those tables are still internally consistent.
function sheetChecks() {
  const rows = validateSprites().map(p => ({ ok: false, text: p }));
  if (!rows.length) {
    rows.push({ ok: true, text: Object.keys(SPRITES).length + ' sprites match their declared size and use only palette colours' });
  }
  const evens = Object.entries(SPRITES).filter(([, s]) => s.w % 2 === 0 || s.h % 2 === 0);
  rows.push({ ok: evens.length === 0, text: evens.length === 0
    ? 'every dimension is odd, so a centred sprite has a single-column axis'
    : evens.map(([id]) => id).join(', ') + ' have an even dimension' });

  for (const [, items] of SHEET) {
    for (const item of items) {
      if (item.proc || !SPRITES[item.id] || !SPRITES[item.id].r) continue;
      const s = SPRITES[item.id];
      const coverage = (2 * s.r) / Math.min(s.w, s.h);
      if (item.id === 'ship-basic' || item.id.startsWith('pickup')) continue;
      rows.push({ ok: coverage >= 0.8, text: item.label + ': collider covers ' +
        Math.round(coverage * 100) + '% of the smaller dimension' });
    }
  }
  const ship = SPRITES['ship-basic'];
  rows.push({ ok: true, text: 'ship: collider covers ' + Math.round(200 * ship.r / ship.w) +
    '% of its width, which is the "smaller than the sprite, not a point" rule as a number' });
  return rows;
}

function draw() {
  renderOptions(document.getElementById('view-opts'), VIEW_OPTS,
    k => state.view === k, k => { state.view = k; draw(); }, 'radio');
  renderOptions(document.getElementById('toggle-opts'), TOGGLES,
    k => state[k], k => { state[k] = !state[k]; draw(); }, 'toggle');
  renderOptions(document.getElementById('zoom-opts'), [[2, '×2', 'dense'], [4, '×4', 'default'], [6, '×6', 'pixel by pixel']],
    z => state.zoom === z, z => { state.zoom = z; draw(); }, 'radio');

  buildSheet();
  buildSilhouettes();
  buildPalette();
  buildRamps();
  buildFonts();
  checksInto(document.getElementById('checks'), sheetChecks());
}

draw();
