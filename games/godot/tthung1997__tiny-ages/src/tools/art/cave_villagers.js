// @open art/reference/cave_villagers.png
// @canvas 308x30
// Transparent villager sheets for the game: one 308x30 PNG per villager, eleven 28x30 cells:
//   0 idle | 1-4 walk | 5-7 chop (stone axe) | 8-9 hammer (stone hammer) | 10 spear (hunting)
// Facing right; mirror in the engine. Feet are on cell row 27, centre column 14. A grass-coloured
// shadow is baked under the feet. Written to game/assets/world/cave/villagers/<id>.png.
seed = 3;
var OUTDIR = DIR + 'game/assets/world/cave/villagers/';
var IMG = SPR.layer(0).cel(0).image;
var CAST = {
  mira: { pal: PAL.furTan, fur: true, stone: true, hair: 'bun' },
  theo: { pal: PAL.furOchre, fur: true, stone: true, hair: 'tuft' },
  wren: { pal: PAL.furGrey, fur: true, stone: true, hair: 'long', role: 'gatherer' }
};
var FRAMES = [
  { pose: 'idle' }, { pose: 'walk', f: 0 }, { pose: 'walk', f: 1 }, { pose: 'walk', f: 2 }, { pose: 'walk', f: 3 },
  { pose: 'chop', f: 0 }, { pose: 'chop', f: 1 }, { pose: 'chop', f: 2 }, { pose: 'hammer', f: 0 }, { pose: 'hammer', f: 1 },
  { pose: 'spear' }
];
for (var who in CAST) {
  var sheet = new Buf(308, 30);
  for (var i = 0; i < FRAMES.length; i++) {
    var o = {}, k;
    for (k in CAST[who]) o[k] = CAST[who][k];
    for (k in FRAMES[i]) o[k] = FRAMES[i][k];
    var tb = new Buf(27, 27); vil(o)(tb);
    sheet.ell(i * 28 + 14, 28, 5, 1.3, '#5f8236');
    blit(sheet, outlined(tb, OUT), i * 28, 0);
  }
  IMG.putImageData(sheet.d);
  SPR.saveAs(OUTDIR + who + '.png');
}
console.log('villager sheets done');
