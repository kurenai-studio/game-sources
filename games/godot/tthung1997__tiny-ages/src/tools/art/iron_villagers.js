// @open art/reference/iron_villagers.png
// @canvas 308x30
// The Iron Age villager sheets (docs: ages I9): the same three villagers, same layout as
// cave_villagers.js (one 308x30 PNG per villager, eleven 28x30 cells: 0 idle | 1-4 walk | 5-7 chop |
// 8-9 hammer | 10 spear; facing right, feet on cell row 27, centre column 14, a grass-coloured shadow
// under the feet). Two outfits, only the clothes change (hair, build and tools match the other ages):
//   checked   the age outfit, worn from the turn: a long checked wool tunic (slate, indigo and
//             ochre, nothing red) over trousers, a cloak pinned at the shoulder with a plain
//             brooch, laced shoes -> game/assets/world/iron/villagers/checked/<id>.png
//   fittings  the finer outfit, once the first bloom is earned: the checked clothes plus a dark
//             iron brooch, belt buckle and boot studs -> .../iron/villagers/fittings/<id>.png
seed = 3;
var OUTDIR = DIR + 'game/assets/world/iron/villagers/';
var IMG = SPR.layer(0).cel(0).image;
var LOOKS = {
  mira: { pal: PAL.checkedMira, stone: true, hair: 'bun' },
  theo: { pal: PAL.checkedTheo, stone: true, hair: 'tuft' },
  wren: { pal: PAL.checkedWren, stone: true, hair: 'long', role: 'gatherer' }
};
var OUTFITS = { checked: { dir: 'checked/', kind: 'checked' }, fittings: { dir: 'fittings/', kind: 'iron' } };
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
console.log('iron villager sheets done');
