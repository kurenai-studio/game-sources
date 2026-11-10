// @open art/reference/classical_villagers.png
// @canvas 308x30
// The Classical Age villager sheets (docs: ages, "Classical Age"): the same three villagers, same layout
// as cave_villagers.js (one 308x30 PNG per villager, eleven 28x30 cells: 0 idle | 1-4 walk | 5-7 chop |
// 8-9 hammer | 10 spear; facing right, feet on cell row 27, centre column 14, a grass-coloured shadow
// under the feet). Two outfits, only the clothes change (hair, build and tools match the other ages):
//   linen   the age outfit, worn from the turn: a pale linen tunic to the knee with a coloured hem
//           band and a cord belt, a mantle draped over one shoulder, sandals
//           -> game/assets/world/classical/villagers/linen/<id>.png
//   civic   the finer outfit, once the Square is earned: the same clothes with a banded mantle and a
//           bronze brooch -> .../classical/villagers/civic/<id>.png
seed = 3;
var OUTDIR = DIR + 'game/assets/world/classical/villagers/';
var IMG = SPR.layer(0).cel(0).image;
var LOOKS = {
  mira: { pal: PAL.linenMira, stone: true, hair: 'bun' },
  theo: { pal: PAL.linenTheo, stone: true, hair: 'tuft' },
  wren: { pal: PAL.linenWren, stone: true, hair: 'long', role: 'gatherer' }
};
var OUTFITS = { linen: { dir: 'linen/', kind: 'linen' }, civic: { dir: 'civic/', kind: 'civic' } };
var FRAMES = [
  { pose: 'idle' }, { pose: 'walk', f: 0 }, { pose: 'walk', f: 1 }, { pose: 'walk', f: 2 }, { pose: 'walk', f: 3 },
  { pose: 'chop', f: 0 }, { pose: 'chop', f: 1 }, { pose: 'chop', f: 2 }, { pose: 'hammer', f: 0 }, { pose: 'hammer', f: 1 },
  { pose: 'spear' }
];
for (var name in OUTFITS) {
  for (var who in LOOKS) {
    var sheet = new Buf(308, 30);
    for (var i = 0; i < FRAMES.length; i++) {
      var o = { outfit: OUTFITS[name].kind }, k;
      for (k in LOOKS[who]) o[k] = LOOKS[who][k];
      for (k in FRAMES[i]) o[k] = FRAMES[i][k];
      var tb = new Buf(27, 27); vil(o)(tb);
      sheet.ell(i * 28 + 14, 28, 5, 1.3, '#5f8236');
      blit(sheet, outlined(tb, OUT), i * 28, 0);
    }
    IMG.putImageData(sheet.d);
    SPR.saveAs(OUTDIR + OUTFITS[name].dir + who + '.png');
  }
}
console.log('classical villager sheets done');
