// @open game/assets/world/roles/smith.png
// @canvas 308x30
// Role overlays (docs: ages V10, "Roles are overlays on whatever is worn"): one transparent 308x30
// PNG per profession with the same layout as the villager sheets (eleven 28x30 cells: 0 idle |
// 1-4 walk | 5-7 chop | 8-9 hammer | 10 spear; facing right, feet on cell row 27, centre column 14)
// holding ONLY the pixels a role adds, so the game can draw it over any villager, in any look
// (mira/theo/wren share one body) and any outfit, at the same position and flip:
//   smith    dark leather apron with a belt, a bronze hammer hung at the belt, a soot-stained
//            brick-red headband with its tails flying behind
//   trader   a big leather pack on the back under a bright rolled blanket, a pouch on the belt
//   forager  a woven back-basket of greens on a strap
//   scout    a teal scarf at the neck, its tails streaming behind, and a small pack
// -> game/assets/world/roles/<profession>.png. The preview art/reference/role_overlays.png is made
// by tools/art/role_preview.py (bundle.py runs it after this script): the four overlays on real
// bodies, three outfits and looks, at 8x.
//
// Where the body is, in a cell (drawing buffer = cell minus 1px, vil()'s 27x27 buffer; BT is the top
// row of the torso). The body is the same in every outfit and look:
//   torso x 10..15, rows BT..BT+4 (the hem is BT+5); the head covers its top rows, so only
//   BT+2..BT+5 show; head centre (14, BT-3), radius 5; the back is the LEFT (x < 10); legs from BT+5.
//   BT = 19 everywhere except the walk frames 2 and 4 (cells 2 and 4), where the body bobs up: 18.
// Pieces that sit on the body (apron, scarf, headband) get no outline: the body already has one.
// Pieces that stick out (pack, basket, tails, hammer) are outlined like the villagers.
seed = 5;
var OUTDIR = DIR + 'game/assets/world/roles/';
var IMG = SPR.layer(0).cel(0).image;
var CELLS = 11, CW = 28, CH = 30;
var BOB = [0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0]; // how far the body is raised in each cell

var LD = '#5a3a28', LM = '#7a4c28', LL = '#a8703f', LH = '#c9a06a', STRAP = '#6b4a2f';
var CREAM = '#f4ecd8', GOLD = '#e8c46a';

// outer: drawn outlined (sticks out of the body); inner: drawn as is (sits on the body)
var ROLES = {
  smith: function (inn, out, BT, i) {
    // the headband: two rows on the hair line, soot-stained, its tails knotted behind
    inn.rect(10, BT - 6, 9, 1, '#a8452f'); inn.rect(10, BT - 5, 9, 1, '#7a2f26');
    inn.px(12, BT - 6, '#7a2f26'); inn.px(15, BT - 5, '#4e2420'); inn.px(16, BT - 5, '#4e2420');
    out.px(9, BT - 5, '#7a2f26'); out.px(9, BT - 4, '#a8452f'); out.px(8, BT - 4, '#a8452f');
    out.px(8, BT - 3, '#7a2f26'); out.px(7, BT - 3, '#7a2f26');
    // the apron: a bib, a belt with a buckle, the skirt with a lighter front edge and soot smears
    inn.rect(11, BT + 2, 3, 1, '#43291c');
    inn.rect(10, BT + 3, 6, 1, '#8a5a36'); inn.px(13, BT + 3, BRONZE_L); inn.px(14, BT + 3, BRONZE);
    inn.rect(10, BT + 4, 6, 2, '#43291c'); inn.rect(15, BT + 4, 1, 2, LM);
    inn.px(11, BT + 4, '#6b5a52'); inn.px(13, BT + 5, '#6b5a52'); inn.px(12, BT + 4, '#5a3a28');
    // a hammer hung at the belt behind the hip: a bright bronze head on a short wooden handle
    out.rect(7, BT + 3, 3, 2, BRONZE); out.rect(7, BT + 3, 3, 1, BRONZE_L); out.px(9, BT + 4, BRONZE_D);
    out.rect(8, BT + 5, 1, 2, WOOD);
  },
  trader: function (inn, out, BT, i) {
    var x, y;
    // the pack: a rounded leather bag with a flap, a strap and a buckle
    var bag = [[5, 9], [4, 9], [4, 9], [4, 9], [4, 9], [5, 9]];
    for (y = 0; y < bag.length; y++) for (x = bag[y][0]; x <= bag[y][1]; x++) out.px(x, BT + 1 + y, y < 2 ? LH : LL);
    for (y = 0; y < bag.length; y++) out.px(bag[y][0], BT + 1 + y, LM);
    out.rect(5, BT + 3, 5, 1, LD); out.rect(5, BT + 6, 5, 1, LD);
    out.rect(7, BT + 1, 1, 6, LD); out.px(7, BT + 4, GOLD);
    // the blanket rolled on top, bright, with cream stripes
    out.rect(5, BT - 2, 4, 1, '#f5a95a'); out.rect(4, BT - 1, 6, 1, '#e8873a'); out.rect(4, BT, 6, 1, '#c46a22');
    out.rect(5, BT - 1, 1, 2, CREAM); out.rect(8, BT - 1, 1, 2, CREAM); out.px(6, BT - 2, CREAM);
    // a pouch hung from a belt at the hip
    inn.rect(10, BT + 4, 6, 1, LD);
    out.rect(11, BT + 5, 3, 3, LM); out.rect(11, BT + 5, 3, 1, LH); out.px(12, BT + 6, GOLD);
  },
  forager: function (inn, out, BT, i) {
    var x, y;
    // greens heaped over the rim
    var G = [[4, -2, '#2f8a55'], [5, -3, '#4fb06a'], [6, -2, '#7ad88a'], [7, -3, '#4fb06a'], [8, -2, '#2f8a55'],
             [5, -1, '#2f8a55'], [7, -1, '#7ad88a'], [4, -1, '#4fb06a'], [9, -1, '#4fb06a'], [6, -4, '#7ad88a']];
    for (var g = 0; g < G.length; g++) out.px(G[g][0], BT + G[g][1], G[g][2]);
    out.px(6, BT - 1, '#e8504a'); out.px(8, BT - 1, '#e8504a');
    // the basket: a rim, a woven body that narrows to the base
    out.rect(3, BT, 7, 1, '#8a5a36');
    var rows = [[3, 9], [3, 9], [4, 9], [4, 9], [5, 9], [5, 9]];
    for (y = 0; y < rows.length; y++) for (x = rows[y][0]; x <= rows[y][1]; x++)
      out.px(x, BT + 1 + y, ((x + y) % 2) ? '#e8c46a' : '#c99a3d');
    out.rect(5, BT + 6, 5, 1, '#8a5a36');
    for (y = 1; y <= 5; y++) out.px(rows[y - 1][0], BT + y, '#a8763e');
    // the strap over the shoulder and across the chest
    inn.px(10, BT + 2, STRAP); inn.px(11, BT + 3, STRAP); inn.px(12, BT + 3, STRAP); inn.px(13, BT + 4, STRAP); inn.px(14, BT + 4, STRAP);
    inn.px(15, BT + 5, STRAP); inn.px(10, BT + 3, '#3a281a'); inn.px(12, BT + 4, '#3a281a'); inn.px(14, BT + 5, '#3a281a');
  },
  scout: function (inn, out, BT, i) {
    var x;
    // the pack: small, brown, with a tan flap and a bright buckle
    out.rect(6, BT + 3, 4, 4, LM); out.rect(6, BT + 3, 4, 2, LL);
    out.rect(6, BT + 6, 4, 1, LD); out.px(8, BT + 5, GOLD); out.rect(6, BT + 5, 1, 2, LD);
    // the scarf round the neck, over the chin, with a knot and a short end at the front
    inn.rect(11, BT + 1, 6, 1, '#74d0c8');
    inn.rect(10, BT + 2, 6, 1, '#3fa7a0');
    inn.px(16, BT + 2, '#2d827c'); inn.px(16, BT + 3, '#3fa7a0'); inn.px(16, BT + 4, '#2d827c');
    // its tails stream out behind and rise a little; they ripple while the scout walks
    var walk = i >= 1 && i <= 4, ph = walk ? i * 1.3 : 0, amp = walk ? 1.0 : 0.4;
    for (x = 3; x <= 9; x++) {
      var k = 9 - x, y = BT + 2 - Math.round(k * 0.3 + Math.sin(k * 0.9 + ph) * amp);
      if (!walk) y = BT + 1 + (k >= 3 ? 1 : 0) + (k >= 5 ? 1 : 0); // at rest the tails hang a little
      out.px(x, y, '#3fa7a0'); out.px(x, y + 1, '#2d827c');
      if (k <= 3) out.px(x, y - 1, '#74d0c8');
    }
  }};

// per-profession sheets, written at 308x30 (the open document is the smith's own sheet)
var SHEETS = {};
for (var role in ROLES) {
  var sheet = new Buf(CELLS * CW, CH);
  for (var i = 0; i < CELLS; i++) {
    var BT = 19 - BOB[i];
    var inn = new Buf(27, 27), out = new Buf(27, 27);
    ROLES[role](inn, out, BT, i);
    blit(sheet, outlined(out, OUT), i * CW, 0);
    blit(sheet, inn, i * CW + 1, 1);
  }
  SHEETS[role] = sheet;
  IMG.putImageData(sheet.d);
  SPR.saveAs(OUTDIR + role + '.png');
}
console.log('role overlays done');
