// @open art/reference/cave_river.png
// @canvas 384x80
// The river in the Cave Age (issue #9; docs: ages V13). What the answers to "The hard crossing", the
// run of fish and the reed bedding put on the water and the bank. The river runs from about x = 302
// to x = 476 along the foot rows, so a crossing is drawn over both the camp page and the east page
// (two pieces with the same drawing, shifted). Game assets (game/assets/world/cave/), each a full
// 384x80 transparent PNG so every piece already sits at its final position:
//   crossing_stones, east_crossing_stones   stepping stones across the gaps between three gravel bars
//   crossing_log, east_crossing_log         felled trunks over the same gaps (the bars are the piers)
//   river_trap                              the willow fish trap in the shallows (camp page)
//   reed_bundles                            cut reeds stacked on the near bank (camp page)
// Positions are mirrored in game/scripts/view/world_layout.gd (CROSSING_X, FISH_SPOTS) and
// scene_props.gd: change them together. Preview: art/reference/cave_river.png.
seed = 52;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/cave/';
var IMG = SPR.layer(0).cel(0).image;

function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

var ROCK = '#8d8a93', ROCKD = '#6f6c78', ROCKL = '#a8a5ae';
var GRAVEL = '#cdbd92', GRAVELL = '#e2d3a6', GRAVELD = '#a69773';

// ---- the crossing --------------------------------------------------------------------------
var X0 = 302, X1 = 476, TOP = 70;           // the span in world x; the buffer's first row is world y 70
var BARS = [336, 388, 438];                 // gravel bars (centre x), 22 px wide
var GAPS = [[302, 325], [347, 377], [399, 427], [449, 476]]; // where the water has to be crossed

function bar(b, cx) {
  var x = cx - X0;
  b.ell(x, 6.5, 11, 2.6, GRAVEL); b.ell(x - 1, 5.5, 8, 1.6, GRAVELL);
  b.px(x - 6, 7, GRAVELD); b.px(x + 2, 8, GRAVELD); b.px(x + 7, 7, GRAVELD);
  b.px(x - 3, 6, ROCK); b.px(x + 4, 5, ROCKD); b.px(x + 8, 6, ROCK);
}
function stone(b, x, w) { b.rect(x, 7, w, 2, ROCK); b.rect(x, 7, w, 1, ROCKL); b.px(x + w - 1, 8, ROCKD); b.px(x, 8, ROCKD); }
function trunk(b, x, w) {
  b.rect(x, 5, w, 3, WOOD); b.rect(x, 5, w, 1, WOODL); b.rect(x + 3, 7, 1, 1, '#6a4326'); b.rect(x + w - 7, 6, 1, 1, '#6a4326');
  b.px(x, 6, '#d9a566'); b.px(x + w - 1, 6, '#d9a566'); b.px(x, 7, '#d9a566');
}
function stones(b) {
  var g, x;
  for (g = 0; g < BARS.length; g++) bar(b, BARS[g]);
  for (g = 0; g < GAPS.length; g++) {
    for (x = GAPS[g][0] + 2; x < GAPS[g][1] - 4; x += 9 + Math.floor(rnd() * 3)) stone(b, x - X0, 5 + Math.floor(rnd() * 2));
  }
}
function logs(b) {
  var g;
  for (g = 0; g < BARS.length; g++) bar(b, BARS[g]);
  for (g = 0; g < GAPS.length; g++) trunk(b, GAPS[g][0] - X0 - 2, GAPS[g][1] - GAPS[g][0] + 4);
}
// The span as one outlined sprite, placed on a page whose left edge is at world x `pageX`.
function crossing(fn, pageX) {
  var tb = new Buf(X1 - X0 + 1, 9), B = new Buf(W, H);
  fn(tb);
  blit(B, outlined(tb, OUT), X0 - 1 - pageX, TOP - 1);
  return B;
}

// ---- the trap and the bundles --------------------------------------------------------------
// A willow fish trap, 10x10: a woven cone lying in the channel, mouth to the stream, between two stakes.
function trap(b) {
  var r;
  for (r = 0; r < 8; r++) { b.rect(1 + Math.floor(r / 3), 2 + r, 8 - Math.floor(r / 3) * 2, 1, r % 2 ? '#8a5a36' : '#c58f50'); }
  b.rect(0, 0, 1, 10, WOOD); b.rect(9, 0, 1, 10, WOOD); b.px(0, 0, WOODL); b.px(9, 0, WOODL);
  b.rect(3, 9, 4, 1, '#3b79ad');
}
// Cut reeds, 16x8, in three bundles tied with sinew.
function bundles(b) {
  var i, y;
  for (i = 0; i < 3; i++) {
    y = 1 + i * 2;
    b.rect(i % 2, y, 15 - (i % 2), 2, i == 1 ? '#9bbb55' : '#86a94c'); b.rect(i % 2, y, 15 - (i % 2), 1, '#c4dc82');
    b.px(4 + i, y, '#8a5a36'); b.px(10 - i, y + 1, '#8a5a36');
  }
  b.rect(0, 7, 16, 1, '#5f8236');
}

var layers = {};
layers.crossing_stones = crossing(stones, 0);
seed = 52; // the same stones on both pages
layers.east_crossing_stones = crossing(stones, 384);
layers.crossing_log = crossing(logs, 0);
layers.east_crossing_log = crossing(logs, 384);
layers.river_trap = layerOf([obj(10, 10, 328, 72, trap, { sh: 0 })]);
layers.reed_bundles = layerOf([obj(16, 8, 297, 77, bundles, { sh: 8 })]);

// preview: the river between the banks, each piece in place
var P = new Buf(W, H), name, y, x;
for (y = 0; y < G; y++) for (x = 0; x < W; x++) P.px(x, y, '#9cc4de');
for (y = G; y < H; y++) for (x = 0; x < W; x++) P.px(x, y, (x > 300 && x < 478) ? '#4f93c4' : '#789a43');
for (name in layers) if (name.indexOf('east_') != 0 && name != 'crossing_log') blit(P, layers[name], 0, 0);
blit(P, layers.crossing_log, 0, 0);
IMG.putImageData(P.d); SPR.save();
SPR.saveAs(DIR + 'art/reference/cave_river.png');
var count = 0;
for (name in layers) { IMG.putImageData(layers[name].d); SPR.saveAs(GAME + name + '.png'); count++; }
console.log('cave river done, ' + count + ' game layers');
