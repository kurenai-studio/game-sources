// @open art/reference/bronze_villagers.png
// @canvas 308x30
// The Bronze Age villager sheets (docs: ages B8): the same three villagers, same layout as
// cave_villagers.js (one 308x30 PNG per villager, eleven 28x30 cells: 0 idle | 1-4 walk | 5-7 chop |
// 8-9 hammer | 10 spear; facing right, feet on cell row 27, centre column 14, a grass-coloured shadow
// under the feet). Two outfits, only the clothes change (hair, build and tools match the other ages):
//   town      the age outfit, worn from the turn: a long belted tunic with a red hem, a hooded wool
//             cloak, calf-high leather boots -> game/assets/world/bronze/villagers/town/<id>.png
//   fittings  the finer outfit, once the first casting is earned: the town clothes plus a cloak pin,
//             a belt buckle and arm rings in bright bronze -> .../bronze/villagers/fittings/<id>.png
// The red trim is drawn for everyone, dyed cloth or not: there is no per-flag clothing to draw.
seed = 3;
var OUTDIR = DIR + 'game/assets/world/bronze/villagers/';
var IMG = SPR.layer(0).cel(0).image;
var LOOKS = {
  mira: { pal: PAL.townMira, stone: true, hair: 'bun' },
  theo: { pal: PAL.townTheo, stone: true, hair: 'tuft' },
  wren: { pal: PAL.townWren, stone: true, hair: 'long', role: 'gatherer' }
};
var OUTFITS = { town: 'town/', fittings: 'fittings/' };
var FRAMES = [
  { pose: 'idle' }, { pose: 'walk', f: 0 }, { pose: 'walk', f: 1 }, { pose: 'walk', f: 2 }, { pose: 'walk', f: 3 },
  { pose: 'chop', f: 0 }, { pose: 'chop', f: 1 }, { pose: 'chop', f: 2 }, { pose: 'hammer', f: 0 }, { pose: 'hammer', f: 1 },
  { pose: 'spear' }
];
for (var kind in OUTFITS) {
  for (var who in LOOKS) {
    var sheet = new Buf(308, 30);
    for (var i = 0; i < FRAMES.length; i++) {
      var o = { outfit: kind }, k;
      for (k in LOOKS[who]) o[k] = LOOKS[who][k];
      for (k in FRAMES[i]) o[k] = FRAMES[i][k];
      var tb = new Buf(27, 27); vil(o)(tb);
      sheet.ell(i * 28 + 14, 28, 5, 1.3, '#5f8236');
      blit(sheet, outlined(tb, OUT), i * 28, 0);
    }
    IMG.putImageData(sheet.d);
    SPR.saveAs(OUTDIR + OUTFITS[kind] + who + '.png');
  }
}
console.log('bronze villager sheets done');
