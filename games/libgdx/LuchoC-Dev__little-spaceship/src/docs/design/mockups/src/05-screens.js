// The five screens of the flow in 02-mvp-functional-spec.md, laid out on the full 480x270 with the
// shared frame fixed in 04-hud-layout.md: title at 40,32, 10 px lines, 16 px between entries,
// W4 for the selected entry with a marker 12 px to its left, and a 24 px safe area.
const SAFE = 24, TITLE_X = 40, TITLE_Y = 32;

function w5(str) { return str.length * 6; }
function w7(str) { return str.length * 8; }

// An indexed framebuffer has no alpha, so "the parallax at 30 %" is a checker that keeps three
// pixels in ten. It communicates the same thing and stays inside the palette.
function dim(fb, keep) {
  for (let y = 0; y < fb.h; y++) {
    for (let x = 0; x < fb.w; x++) {
      if ((x * 7 + y * 3) % 10 >= keep) fb.px(x, y, 1);
    }
  }
}

function screenFrame(fb, title) {
  fb.rect(0, 0, fb.w, fb.h, 1);
  fb.text7(title, TITLE_X, TITLE_Y, 20);
  fb.rect(TITLE_X, TITLE_Y + 15, w7(title), 1, 3);
}

// One entry of a menu. Selected entries carry both the colour and the marker, so the choice is
// never communicated by hue alone - R4 applies to the menus too.
function entry(fb, label, x, y, mode) {
  const colour = mode === 'selected' ? 24 : mode === 'disabled' ? 3 : 20;
  if (mode === 'selected') fb.text5('>', x - 12, y, 24);
  fb.text5(label, x, y, colour);
}

function plate(fb, x, y, w, h) {
  fb.rect(x, y, w, h, 2);
  fb.frame(x, y, w, h, 3);
}

function slider(fb, x, y, value) {
  fb.rect(x, y + 3, 80, 3, 2);
  fb.rect(x, y + 3, Math.round(80 * value), 3, 21);
  fb.rect(x + Math.round(80 * value) - 2, y, 5, 9, 19);
  fb.frame(x + Math.round(80 * value) - 2, y, 5, 9, 0);
}

function statBar(fb, x, y, label, filled, total) {
  fb.text5(label, x, y, 4);
  for (let i = 0; i < total; i++) {
    const bx = x + 60 + i * 8;
    if (i < filled) { fb.rect(bx, y, 6, 7, 21); fb.rect(bx, y, 6, 1, 22); }
    else { fb.rect(bx, y, 6, 7, 2); fb.frame(bx, y, 6, 7, 3); }
  }
}

const SCREENS = {
  menu: {
    label: 'Main menu',
    note: 'Play, Options, Quit. No locked modes and no "coming soon" - the spec excludes them, so they are not drawn.',
    draw(fb) {
      drawCity(fb, 180);
      dim(fb, 3);
      fb.text7('LITTLE SPACESHIP', TITLE_X, TITLE_Y, 20);
      fb.rect(TITLE_X, TITLE_Y + 15, w7('LITTLE SPACESHIP'), 1, 3);
      fb.text5('AN EXPERIMENTAL SHIP AGAINST THE FIRST WAVE', TITLE_X, TITLE_Y + 22, 4);
      entry(fb, 'PLAY', 56, 120, 'selected');
      entry(fb, 'OPTIONS', 56, 136, 'normal');
      entry(fb, 'QUIT', 56, 152, 'normal');
      fb.text5('MVP BUILD', TITLE_X, 236, 3);
    }
  },
  ship: {
    label: 'Ship selection',
    note: 'One selectable ship and its characteristics. The empty slot is optional in the spec and kept, because it says the system grows without promising anything.',
    draw(fb) {
      screenFrame(fb, 'SELECT SHIP');
      plate(fb, 40, 70, 120, 130);
      // Drawn at x3 inside the framebuffer, which is still an integer factor of a logical pixel.
      const s = SPRITES['ship-basic'];
      for (let j = 0; j < s.h; j++) {
        for (let i = 0; i < s.w; i++) {
          const c = CHARS[s.art[j][i]];
          if (c < 0) continue;
          fb.rect(78 + i * 3, 96 + j * 3, 3, 3, c);
        }
      }
      fb.text5('PROTOTYPE X-1', 40, 210, 20);
      fb.text5('SUSTAINED SHOT, BOMB, SLOW MODE', 40, 224, 4);
      statBar(fb, 180, 80, 'SPEED', 3, 5);
      statBar(fb, 180, 96, 'FIRE', 3, 5);
      statBar(fb, 180, 112, 'BOMBS', 2, 5);
      statBar(fb, 180, 128, 'LIVES', 3, 5);
      fb.text5('THE ONLY SHIP THAT ANSWERED', 180, 152, 4);
      fb.text5('THE LAUNCH ORDER IN TIME.', 180, 164, 4);
      plate(fb, 380, 70, 60, 60);
      fb.text5('EMPTY', 392, 96, 3);
      entry(fb, 'LAUNCH', 192, 210, 'selected');
      entry(fb, 'BACK', 192, 226, 'normal');
    }
  },
  options: {
    label: 'Options',
    note: 'Three volumes and the mouse switch. No key remapping and no difficulty: both are explicit MVP exclusions.',
    draw(fb) {
      screenFrame(fb, 'OPTIONS');
      const rows = [['MASTER VOLUME', 0.8], ['MUSIC VOLUME', 0.6], ['EFFECTS VOLUME', 0.9]];
      rows.forEach(([label, value], i) => {
        const y = 80 + i * 24;
        fb.text5(label, 56, y + 1, i === 0 ? 24 : 20);
        if (i === 0) fb.text5('>', 44, y + 1, 24);
        slider(fb, 220, y - 1, value);
        fb.text5(String(Math.round(value * 100)), 316, y + 1, 4);
      });
      fb.text5('MOUSE CONTROL', 56, 160, 20);
      plate(fb, 220, 156, 60, 12);
      fb.text5('ON', 238, 159, 22);
      entry(fb, 'CREDITS AND LICENCES', 56, 190, 'normal');
      entry(fb, 'BACK', 56, 214, 'normal');
    }
  },
  pause: {
    label: 'Pause',
    note: 'A panel over a frozen playfield. The spec asks for a simple symbol or button, not a full menu, so it is two entries.',
    draw(fb) {
      const scene = renderScene('escalation', 0);
      fb.d.set(scene.d);
      dim(fb, 4);
      plate(fb, 160, 92, 160, 86);
      fb.text7('PAUSED', 160 + ((160 - w7('PAUSED')) >> 1), 108, 20);
      entry(fb, 'RESUME', 196, 140, 'selected');
      entry(fb, 'QUIT TO MENU', 196, 156, 'normal');
    }
  },
  victory: {
    label: 'Victory',
    note: 'The bonus for remaining lives and bombs from 10-mvp-initial-values.md, shown as the arithmetic it is.',
    draw(fb) {
      drawCity(fb, 420);
      dim(fb, 2);
      fb.text7('VICTORY', TITLE_X, TITLE_Y, 24);
      fb.rect(TITLE_X, TITLE_Y + 15, w7('VICTORY'), 1, 3);
      fb.text5('THE ATTACK ZONE IS CLEAR. THE INVASION IS NOT.', TITLE_X, TITLE_Y + 22, 4);
      const rows = [['SCORE', '0048300'], ['LIVES BONUS  2', '0002000'], ['BOMBS BONUS  1', '0000300']];
      rows.forEach(([label, value], i) => {
        fb.text5(label, 56, 100 + i * 16, 4);
        fb.text5(value, 240, 100 + i * 16, 20);
      });
      fb.rect(56, 150, 240, 1, 3);
      fb.text5('TOTAL', 56, 160, 20);
      fb.text7('0050600', 240, 156, 24);
      entry(fb, 'CONTINUE', 56, 210, 'selected');
    }
  },
  defeat: {
    label: 'Defeat',
    note: 'Retry and menu, and nothing else. There are no checkpoints in the MVP, so there is nothing else to offer.',
    draw(fb) {
      drawCity(fb, 60);
      dim(fb, 2);
      fb.text7('GAME OVER', TITLE_X, TITLE_Y, 23);
      fb.rect(TITLE_X, TITLE_Y + 15, w7('GAME OVER'), 1, 3);
      fb.text5('THE SHIP WAS LOST OVER THE CITY.', TITLE_X, TITLE_Y + 22, 4);
      fb.text5('SCORE', 56, 110, 4);
      fb.text7('0012500', 140, 106, 20);
      entry(fb, 'RETRY', 56, 170, 'selected');
      entry(fb, 'QUIT TO MENU', 56, 186, 'normal');
    }
  }
};

function renderScreen(key) {
  const fb = new Fb();
  SCREENS[key].draw(fb);
  return fb;
}

// The reference sheet needs each sprite on its own, at its own size, plus the two that are drawn
// from primitives and the flat-black silhouettes of R16.
function spriteFb(id) {
  const s = SPRITES[id];
  const fb = new Fb(s.w, s.h);
  fb.blit(id, (s.w - 1) >> 1, (s.h - 1) >> 1, 'full');
  return fb;
}

// R16: filled with flat black on a plain ground, so only the outline of the shape is left to
// judge. Two archetypes that are hard to tell apart here are hard to tell apart in play.
function silhouetteFb(id) {
  const s = SPRITES[id];
  const fb = new Fb(s.w, s.h);
  fb.rect(0, 0, s.w, s.h, 4);
  for (let j = 0; j < s.h; j++) {
    for (let i = 0; i < s.w; i++) if (CHARS[s.art[j][i]] >= 0) fb.px(i, j, 0);
  }
  return fb;
}

// Filled with N1 rather than the default N0 first: these two draw their own outline in N0, and the
// silhouette below has to be able to tell the outline from the void around it.
function proceduralFb(kind) {
  const fb = kind === 'carrier' ? new Fb(39, 31) : new Fb(119, 87);
  fb.rect(0, 0, fb.w, fb.h, 1);
  if (kind === 'carrier') drawCarrier(fb, 19, 15); else drawBoss(fb, 59, 43);
  return fb;
}

function proceduralSilhouette(kind) {
  const src = proceduralFb(kind);
  const fb = new Fb(src.w, src.h);
  for (let i = 0; i < src.d.length; i++) fb.d[i] = src.d[i] === 1 ? 4 : 0;
  return fb;
}

// The sheet layout both fonts ship in: 16 columns of ASCII 32-126, cell index = code - 32. Cells
// font-title does not cover stay empty, which is what lets one loader index either sheet.
const SHEET_COLUMNS = 16;
const SHEET_CELL = {
  mini: { cw: 6, ch: 10 },
  title: { cw: 8, ch: 13 }
};

function fontSheetFb(which) {
  const font = which === 'title' ? FONT7 : FONT5;
  const cell = which === 'title' ? SHEET_CELL.title : SHEET_CELL.mini;
  const rows = Math.ceil(95 / SHEET_COLUMNS);
  const fb = new Fb(SHEET_COLUMNS * cell.cw, rows * cell.ch);
  for (let code = 32; code <= 126; code++) {
    const ch = String.fromCharCode(code);
    if (!(ch in font)) continue;
    const i = code - 32;
    const x = (i % SHEET_COLUMNS) * cell.cw, y = Math.floor(i / SHEET_COLUMNS) * cell.ch;
    if (which === 'title') fb.text7(ch, x, y, 20); else fb.text5(ch, x, y, 20);
  }
  return fb;
}
