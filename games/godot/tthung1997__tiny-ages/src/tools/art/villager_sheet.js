// @open art/reference/villager_A_sheet_v2.png
// @canvas 224x90
// Villager A sheet: 8 columns x 3 rows, 28x30 px cells.
// Row 1: walk x4, chop x3, hammer 0. Row 2: hammer 1, fish x2, idle, role overlays. Row 3: hair/palette variants.
seed = 9;
var SW = 224, SH = 90, Z = new Buf(SW, SH), x, y, i;
for (y = 0; y < SH; y++) for (x = 0; x < SW; x++) Z.px(x, y, (Math.floor(y / 30) & 1) ? '#78b653' : '#74b24f');
for (i = 0; i < 90; i++) Z.px(Math.floor(rnd() * SW), Math.floor(rnd() * SH), rnd() < .5 ? '#8fc95a' : '#5e9a43');
var R = PAL.red;
var cells = [
  { pal: R, pose: 'walk', f: 0 }, { pal: R, pose: 'walk', f: 1 }, { pal: R, pose: 'walk', f: 2 }, { pal: R, pose: 'walk', f: 3 },
  { pal: PAL.green, role: 'woodcutter', pose: 'chop', f: 0 }, { pal: PAL.green, role: 'woodcutter', pose: 'chop', f: 1 }, { pal: PAL.green, role: 'woodcutter', pose: 'chop', f: 2 }, { pal: PAL.yellow, role: 'builder', pose: 'hammer', f: 0 },
  { pal: PAL.yellow, role: 'builder', pose: 'hammer', f: 1 }, { pal: PAL.purple, role: 'fisher', pose: 'fish', f: 0 }, { pal: PAL.purple, role: 'fisher', pose: 'fish', f: 1 }, { pal: R, pose: 'idle' },
  { pal: R, role: 'farmer', pose: 'idle' }, { pal: PAL.yellow, role: 'builder', pose: 'idle' }, { pal: PAL.blue, role: 'explorer', pose: 'idle' }, { pal: PAL.green, role: 'woodcutter', pose: 'idle' },
  { pal: PAL.red, pose: 'idle', hair: 'short' }, { pal: PAL.blue, pose: 'idle', hair: 'tuft' }, { pal: PAL.teal, pose: 'idle', hair: 'long' }, { pal: PAL.orange, pose: 'idle', hair: 'bun' },
  { pal: PAL.pink, pose: 'idle', hair: 'pony' }, { pal: PAL.purple, pose: 'idle', hair: 'long' }, { pal: PAL.green, pose: 'idle', hair: 'tuft' }, { pal: PAL.yellow, pose: 'idle', hair: 'bun' }
];
for (i = 0; i < cells.length; i++) {
  var col_ = i % 8, row = Math.floor(i / 8), tb = new Buf(27, 27);
  vil(cells[i])(tb);
  var ox = col_ * 28, oy = row * 30;
  Z.ell(ox + 14, oy + 27, 5, 1.3, '#4a8a38');
  blit(Z, outlined(tb, OUT), ox, oy);
}
SPR.layer(0).cel(0).image.putImageData(Z.d);
SPR.save();
console.log('villager sheet done');
