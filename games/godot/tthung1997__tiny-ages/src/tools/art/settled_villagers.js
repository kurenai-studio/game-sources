// @open art/reference/settled_villagers.png
// @canvas 308x30
// The Settled Age villager sheets (docs: ages V10): the same three villagers in woven tunics
// instead of furs, same layout as cave_villagers.js: one 308x30 PNG per villager, eleven 28x30
// cells (0 idle | 1-4 walk | 5-7 chop | 8-9 hammer | 10 spear), facing right, feet on cell row 27,
// centre column 14, a grass-coloured shadow baked under the feet. The game swaps a villager's sheet
// for this one once the group has woven cloth (achievement woven_cloth). Written to
// game/assets/world/settled/villagers/<id>.png. Hair, build and tools match the Cave sheets.
// The same script draws the field clothes the group wears from the turn of the age until it weaves
// cloth (docs: ages B8): plain undyed hemp, a rope belt, rolled sleeves, bare feet, a leather scrap
// sewn on. Written to game/assets/world/settled/villagers/field/<id>.png.
seed = 3;
var OUTDIR = DIR + 'game/assets/world/settled/villagers/';
var IMG = SPR.layer(0).cel(0).image;
var OUTFITS = [
  { dir: OUTDIR, cast: {
    mira: { pal: PAL.clothMira, cloth: true, stone: true, hair: 'bun' },
    theo: { pal: PAL.clothTheo, cloth: true, stone: true, hair: 'tuft' },
    wren: { pal: PAL.clothWren, cloth: true, stone: true, hair: 'long', role: 'gatherer' }
  } },
  { dir: OUTDIR + 'field/', cast: {
    mira: { pal: PAL.fieldMira, outfit: 'field', stone: true, hair: 'bun' },
    theo: { pal: PAL.fieldTheo, outfit: 'field', stone: true, hair: 'tuft' },
    wren: { pal: PAL.fieldWren, outfit: 'field', stone: true, hair: 'long', role: 'gatherer' }
  } }
];
var FRAMES = [
  { pose: 'idle' }, { pose: 'walk', f: 0 }, { pose: 'walk', f: 1 }, { pose: 'walk', f: 2 }, { pose: 'walk', f: 3 },
  { pose: 'chop', f: 0 }, { pose: 'chop', f: 1 }, { pose: 'chop', f: 2 }, { pose: 'hammer', f: 0 }, { pose: 'hammer', f: 1 },
  { pose: 'spear' }
];
for (var s = 0; s < OUTFITS.length; s++) {
  var CAST = OUTFITS[s].cast;
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
    SPR.saveAs(OUTFITS[s].dir + who + '.png');
  }
}
console.log('settled villager sheets done');
