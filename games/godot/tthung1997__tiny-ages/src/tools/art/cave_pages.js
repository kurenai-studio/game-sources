// @open art/reference/cave_west.png
// @canvas 384x80
// Cave Age world, the two side pages (docs: engine-and-art A8, ages V5). The camp page is
// cave_strip.js; this draws the page to its west (a pine forest rising to a snowy ridge: the
// hunting grounds) and the page to its east (the camp's river, a spit that runs from grass into
// a wide sandy beach with palms, and the open sea off the right edge; issue #17).
//
// Seams: every curve is a function of the WORLD x (camp page is 0..384, west is -384..0, east is
// 384..768), so the hills, sky bands and tree line meet the camp's edges without a jump.
//
// Previews: art/reference/cave_west.png, cave_east.png. Game assets (game/assets/world/cave/),
// each a full 384x80 transparent PNG:
//   west_<layer>, east_<layer>   sky, far_hills, near_hills, trees, ground
//   west_static_back/_mid, east_static_back/_mid   always-present props (back is behind villagers)
//   east_sea_0.._2   the sea alone (transparent elsewhere) in three surf and swell phases; the
//                    game swaps them over east_ground, which carries phase 0 itself
//   east_sea_choppy_0.._2, east_sea_rough_0.._2   the same water in rougher sea states (rain and
//                    flood, storm): wider surf and white caps; same pixels as the calm phases
// Layout notes are mirrored in game/scripts/view/world_layout.gd.
seed = 31;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/cave/';
var IMG = SPR.layer(0).cel(0).image;

function smooth(a, b, v) { var t = (v - a) / (b - a); t = t < 0 ? 0 : (t > 1 ? 1 : t); return t * t * (3 - 2 * t); }
function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, shc: o.shc, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, ob.shc || '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }
// Decor (stumps, bushes, rocks) is placed by the game in a prop space like any prop; this only picks where
// each piece is drawn at home (near the middle of a building space, x = -358 + 28 k).
function snapDecor(list, off) {
  var taken = {}, k, n, ob;
  for (var i = 0; i < list.length; i++) {
    ob = list[i];
    k = Math.round((ob.cx + off + 358) / 28);
    for (n = 0; taken[k]; n++) k += (n % 2 == 0 ? 1 : -1) * (n + 1);
    taken[k] = true;
    ob.cx = -358 + 28 * k - off; ob.x = ob.cx - Math.floor(ob.w / 2);
  }
}

// ---- shared pieces, in the camp's palette -----------------------------------------------
var skyCols = ['#86b4d6', '#9cc4de', '#b4d4e6', '#cde2ee', '#e4eef3'];
function drawSky(S) {
  for (var y = 0; y < G; y++) {
    var bi = Math.min(4, Math.floor(y / 11)), t = y % 11;
    for (var x = 0; x < W; x++) { var c = skyCols[bi]; if (t >= 9 && bi < 4 && ((x + y) & 1) == 0) c = skyCols[bi + 1]; S.px(x, y, c); }
  }
}
function drawFar(F, off, bump) { // snow-capped far range; `bump(wx)` raises (negative) or sinks it
  for (var x = 0; x < W; x++) {
    var wx = x + off, r1 = Math.round(33 + 6 * Math.sin(wx / 41) + 3 * Math.sin(wx / 15 + 1) + bump(wx));
    for (var y = Math.max(r1, 0); y < G; y++) {
      var snow = r1 < 34 && y < r1 + 3;
      F.px(x, y, snow ? (y < r1 + 1 ? '#f4f8fb' : '#dbe6ee') : (y < r1 + 1 ? '#b3c4d1' : '#9fb2c2'));
    }
  }
}
function drawNear(N, off, bump) {
  for (var x = 0; x < W; x++) {
    var wx = x + off, r2 = Math.round(46 + 4 * Math.sin(wx / 29 + 2) + 1.5 * Math.sin(wx / 11) + bump(wx));
    for (var y = r2; y < G; y++) N.px(x, y, y < r2 + 1 ? '#a9c49c' : '#8eab85');
  }
}
function clearBelowGround(T) { for (var y = G; y < H; y++) for (var x = 0; x < W; x++) T.d[(y * W + x) * 4 + 3] = 0; }
function landBands(Gd, from, to, x0, x1) {
  for (var y = G; y < H; y++) { var gc = y < G + 2 ? '#a4c35c' : (y < G + 13 ? '#86a94c' : '#789a43'); for (var x = x0; x < x1; x++) Gd.px(x, y, gc); }
}

// ---- the west page: forest and ridge -------------------------------------------------------
function westPage() {
  var L = { sky: new Buf(W, H), far_hills: new Buf(W, H), near_hills: new Buf(W, H), trees: new Buf(W, H), ground: new Buf(W, H) };
  var x, y, i, off = -384;
  drawSky(L.sky);
  cloud(L.sky, 90, 14, 1.1); cloud(L.sky, 235, 9, 0.8); cloud(L.sky, 320, 21, 1.3);
  drawFar(L.far_hills, off, function (wx) { return -16 * smooth(-150, -340, wx); }); // a taller snowy ridge in the far west
  drawNear(L.near_hills, off, function (wx) { return 0; });
  // trees: a dark back row, then a front row that is dense in the west and thins towards the camp
  for (x = -4; x < W + 4; x += 5) {
    var tb = x / W, hb = Math.round(21 - 8 * tb) + Math.floor(rnd() * 4);
    if (tb > 0.8 && rnd() < (tb - 0.8) * 4) continue;
    L.trees.tri(x + 2, G - hb, hb, 3, '#2f6244', '#265238');
  }
  for (x = -2; x < W + 4; x += 3) {
    var t = (x + 2) / W, th = Math.round(15 - 7 * t) + Math.floor(rnd() * 5), dense = t < 0.75;
    if (!dense && rnd() < (t - 0.75) * 2.4) continue;
    L.trees.tri(x + 2, G - th, th, 3 + (t < 0.5 ? 1 : 0), dense ? '#37704a' : '#3f7a52', dense ? '#2c5c3d' : '#336544');
  }
  clearBelowGround(L.trees);
  // forest floor: the camp's grass, shaded under the trees, with needles and leaf litter
  landBands(L.ground, 0, 0, 0, W);
  for (i = 0; i < 220; i++) { x = Math.floor(rnd() * W); y = G + 2 + Math.floor(rnd() * (H - G - 2)); var lt = rnd() < 0.5; L.ground.px(x, y, lt ? '#9bbb55' : '#5f8236'); if (rnd() < 0.5) L.ground.px(x, y - 1, lt ? '#9bbb55' : '#5f8236'); }
  for (i = 0; i < 70; i++) {
    x = Math.floor(rnd() * 330); y = G + 3 + Math.floor(rnd() * (H - G - 5));
    if (rnd() < (x / 330) * 0.7) continue; // fewer patches near the camp
    L.ground.ell(x, y, 3 + Math.floor(rnd() * 5), 1.2, '#6d8f3b');
    for (var n = 0; n < 4; n++) L.ground.px(x - 3 + Math.floor(rnd() * 7), y + Math.floor(rnd() * 2), rnd() < 0.5 ? '#a98a58' : '#8f7447');
  }
  for (i = 0; i < 24; i++) { x = Math.floor(rnd() * W); y = G + 4 + Math.floor(rnd() * (H - G - 6)); L.ground.px(x, y, ['#ffffff', '#ffe27a', '#c9a0ff'][Math.floor(rnd() * 3)]); L.ground.px(x, y + 1, '#3a7a3a'); }
  // props: pines in a few lanes (the back lanes sit behind villagers), stumps, a log, bushes
  var backP = [], midP = [], k = 0, lanes = [62, 66, 70, 64, 74, 68, 78, 72];
  for (var px = 10; px < 352; px += 11 + Math.floor(rnd() * 8)) {
    var foot = lanes[k % lanes.length]; k++;
    if (rnd() < (px / W) * 0.7) continue; // sparser towards the camp
    // The village stands in the forest's edge on the front rows, so every pine stands behind it, on
    // the back lanes (and behind the wall from x = 52 on): a tree is never drawn in front of a house.
    if (px >= 52) foot = 56 + (k % 4) * 2; else if (foot > 66) foot -= 12;
    backP.push(obj(16, 26, px, foot, pine, { sh: 6 }));
  }
  var decor = [obj(10, 8, 318, 77, stump, { sh: 4 }), obj(10, 8, 262, 75, stump, { sh: 4 }), obj(18, 7, 158, 76, fallenlog, { sh: 6 }),
    obj(12, 8, 96, 76, bush, { sh: 5 }), obj(12, 8, 212, 77, bush, { sh: 5 }), obj(12, 8, 346, 77, bush, { sh: 5 }),
    obj(10, 6, 128, 78, rocks, { sh: 4 }), obj(10, 6, 288, 79, rocks, { sh: 4 })];
  snapDecor(decor, -384);
  // Each piece of decor is its own layer (west_decor_<n>): the game can take it away when props need the room.
  for (i = 0; i < decor.length; i++) L['decor_' + i] = layerOf([decor[i]]);
  L.static_back = layerOf(backP);
  L.static_mid = layerOf(midP);
  return L;
}

// ---- the east page: the camp's river, a spit of grass that runs into a beach, and the sea ----
// The river's far bank is 30 px nearer than the first sketch so a crossing is believable and the
// spit has room for props (issue #9); the sea takes the rest of the page.
var SEA_FRAMES = 3;
function riverEdge(y) { return 66 + Math.round((y - G) * 1.2); }                        // where the far bank starts
function shoreEdge(y) { return 205 + (y - G) * 2 + Math.round(Math.sin(y * 1.7)); }      // where the sea starts
var SAND = '#e2d3a6', SAND_MID = '#d8c9a0', SAND_PACK = '#cdbd92', SAND_WET = '#b3a47e';
var BAYER = [0, 2, 3, 1];
// What lies at a land pixel: grass far from the shore, a dithered band where grass and sand mix,
// then dry sand, packed sand and a wet edge.
function landColor(x, y) {
  var re = riverEdge(y), d = shoreEdge(y) - x;
  var gc = y < G + 2 ? '#a4c35c' : (y < G + 13 ? '#86a94c' : '#789a43');
  if (x < re) return SAND_MID;
  if (d <= 2) return (x + y) % 3 == 0 ? '#a69773' : SAND_WET;
  if (d <= 9) return rnd() < 0.12 ? SAND : SAND_PACK;
  if (d <= 30) { var r = rnd(); return r < 0.06 ? '#efe3bb' : (r < 0.14 ? '#d3c394' : SAND); }
  if (d <= 44) { // 25% / 50% / 75% sand, ordered dither
    var level = d <= 35 ? 0.75 : (d <= 40 ? 0.5 : 0.25);
    return level > (BAYER[(x & 1) + 2 * (y & 1)] + 0.5) / 4 ? (rnd() < 0.5 ? SAND : '#cfc58f') : gc;
  }
  return gc;
}
function swellList() { // long, low swell marks (never a vertical or a triangle: nothing that reads as a sail)
  var list = [], i, y, x, len;
  for (i = 0; i < 42; i++) {
    y = G + 2 + Math.floor(rnd() * (H - G - 3)); len = 5 + Math.floor((y - G) / 4) + Math.floor(rnd() * 5);
    x = shoreEdge(y) + 12 + Math.floor(rnd() * (W - shoreEdge(y) - 12 - len - 6));
    if (x + len + 6 < W) list.push({ x: x, y: y, len: len, i: i });
  }
  return list;
}
// Draws the sea (x >= shoreEdge) in surf and swell phase `f` into `B`. Every phase covers the same
// pixels, so the animation never changes what is land. `state` is the sea state: 0 calm, 1 choppy
// (rain, a flood), 2 rough (a storm): wider surf, bigger travel and white caps on some swells. The
// caps are picked by `i`, not by rnd(), so the other states never move anything drawn after them.
var SEA_STATES = ['', 'choppy_', 'rough_'];
var SEA_TRAVEL = [2, 3, 4];
function paintSea(B, f, swells, state) {
  var y, x, k, st = state || 0;
  var foam = [1 + f, 2 + f, 3 + f * 2][st], wash = [6 + f * 2, 7 + f * 2, 10 + f * 3][st];
  for (y = G; y < H; y++) {
    var s = shoreEdge(y);
    for (x = s; x < W; x++) {
      var d = x - s, c = y == G ? '#6da9d2' : (d < 3 ? '#7cc0d8' : (d < 9 ? '#4f9fc9' : (y < G + 5 ? '#3a80b7' : (y < G + 15 ? '#2f6fa8' : '#2a639b'))));
      if (d >= 3 && d < 9 && ((x + y) & 1) == 0) c = '#3f8fbf';
      if (d < foam) c = '#f2fafc';
      else if (d == foam && ((x + y) & 1) == 0) c = '#bfe4ee';
      else if (d == wash && (x + y) % 3 != 0 && y > G) c = '#cfe9f2';
      B.px(x, y, c);
    }
  }
  for (k = 0; k < swells.length; k++) {
    var w = swells[k], ox = w.x + ((f + w.i) % SEA_FRAMES) * SEA_TRAVEL[st];
    var cap = st == 2 ? w.i % 2 == 0 : (st == 1 && w.i % 5 == 0);
    ox = Math.min(ox, W - 1 - w.len);
    B.rect(ox, w.y, w.len, 1, '#5a9fd0');
    if (w.y + 1 < H) B.rect(ox + 1, w.y + 1, w.len - 2, 1, '#25608f');
    if (cap && w.y > G) { // a white cap on the crest, broken at the ends
      B.rect(ox + 1, w.y - 1, Math.max(2, w.len - 3), 1, '#eef8fb');
      if (st == 2) B.rect(ox + 2, w.y, Math.max(1, w.len - 5), 1, '#bfe4ee');
    }
  }
}
function palm(b) { // 22x24: a leaning trunk and drooping fronds
  b.line(7, 23, 8, 17, WOOD, 2); b.line(8, 17, 10, 12, WOOD, 2); b.line(10, 12, 12, 8, WOOD, 2);
  b.px(7, 20, WOODL); b.px(8, 15, WOODL); b.px(10, 11, WOODL);
  var d = '#2f8545', g = '#3f9a52', t = '#58b05f';
  b.line(12, 9, 6, 5, d, 1); b.line(6, 5, 2, 9, d, 1); b.line(12, 9, 18, 5, d, 1); b.line(18, 5, 21, 9, d, 1);
  b.line(12, 9, 8, 11, d, 1); b.line(12, 9, 17, 11, d, 1);
  b.line(12, 8, 6, 4, g, 1); b.line(6, 4, 2, 8, g, 1); b.line(12, 8, 18, 4, g, 1); b.line(18, 4, 21, 8, g, 1);
  b.line(12, 8, 9, 1, g, 1); b.line(12, 8, 15, 1, g, 1); b.line(12, 8, 8, 10, g, 1); b.line(12, 8, 16, 10, g, 1);
  b.px(2, 8, t); b.px(21, 8, t); b.px(9, 1, t); b.px(15, 1, t); b.px(6, 4, t); b.px(18, 4, t);
  b.px(11, 10, '#6a4326'); b.px(13, 10, '#6a4326');
}
function driftwood(b) { // 11x4 bleached log
  b.rect(0, 1, 11, 2, '#b9a88a'); b.rect(0, 1, 11, 1, '#d8cbb0'); b.px(3, 0, '#b9a88a'); b.px(8, 3, '#9a8a6e'); b.px(10, 1, '#9a8a6e');
}
function eastPage() {
  var L = { sky: new Buf(W, H), far_hills: new Buf(W, H), near_hills: new Buf(W, H), trees: new Buf(W, H), ground: new Buf(W, H) };
  var x, y, i, off = 384;
  drawSky(L.sky);
  cloud(L.sky, 60, 11, 1.0); cloud(L.sky, 190, 20, 1.2); cloud(L.sky, 310, 8, 0.8);
  drawFar(L.far_hills, off, function (wx) { return 14 * smooth(470, 760, wx); });     // the range sinks towards the open water
  drawNear(L.near_hills, off, function (wx) { return 12 * smooth(540, 680, wx); });   // and the near hills vanish at the horizon
  for (x = -2; x < W + 4; x += 4) {
    if (x > 130 && rnd() < smooth(130, 190, x)) continue; // the tree line thins out and stops before the beach
    var th = 6 + Math.floor(rnd() * 5);
    L.trees.tri(x + 2, G - th, th, 2 + Math.floor(rnd() * 2), '#3f7a52', '#336544');
  }
  clearBelowGround(L.trees);
  // ground: the camp's grass where there is land, river and sea elsewhere, sand along every shore
  for (y = G; y < H; y++) {
    var re = riverEdge(y);
    for (x = 0; x < re; x++) {
      var wc = '#4f93c4'; // the same water as the camp's river, so there is no seam at x = 384
      L.ground.px(x, y, x < re - 2 ? wc : SAND_MID);
    }
    for (x = re; x < shoreEdge(y); x++) L.ground.px(x, y, landColor(x, y));
  }
  var swells = swellList();
  paintSea(L.ground, 0, swells);
  for (i = 0; i < 160; i++) { // grass tufts, on grass only
    y = G + 2 + Math.floor(rnd() * (H - G - 2)); x = Math.floor(rnd() * W);
    if (x < riverEdge(y) + 2 || x >= shoreEdge(y) - 45) continue;
    var lt = rnd() < 0.5; L.ground.px(x, y, lt ? '#9bbb55' : '#5f8236'); if (rnd() < 0.5) L.ground.px(x, y - 1, lt ? '#9bbb55' : '#5f8236');
  }
  for (i = 0; i < 70; i++) { // dune grass: thick where the grass gives out, thinning towards the water
    y = G + 2 + Math.floor(rnd() * (H - G - 2)); var dd = 12 + Math.floor(rnd() * 32); x = shoreEdge(y) - dd;
    if (x < riverEdge(y) + 2 || rnd() > (dd - 12) / 32) continue;
    var dc = rnd() < 0.5 ? '#9aa85a' : '#74883f'; L.ground.px(x, y, dc); L.ground.px(x, y - 1, dc); if (rnd() < 0.4) L.ground.px(x + 1, y - 2, dc);
  }
  for (i = 0; i < 90; i++) { // river ripples
    y = G + 1 + Math.floor(rnd() * (H - G - 1)); x = Math.floor(rnd() * (W - 3));
    if (x > 1 && x + 2 < riverEdge(y) - 3) L.ground.rect(x, y, 3, 1, rnd() < 0.6 ? '#8cc8e8' : '#3b79ad');
  }
  for (i = 0; i < 14; i++) { // wildflowers on the bank
    y = G + 4 + Math.floor(rnd() * (H - G - 6)); x = riverEdge(y) + 4 + Math.floor(rnd() * 40);
    if (x < shoreEdge(y) - 48) { L.ground.px(x, y, ['#ffffff', '#ffe27a', '#c9a0ff'][Math.floor(rnd() * 3)]); L.ground.px(x, y + 1, '#3a7a3a'); }
  }
  for (var st = 0; st < SEA_STATES.length; st++) {
    for (i = 0; i < SEA_FRAMES; i++) { L['sea_' + SEA_STATES[st] + i] = new Buf(W, H); paintSea(L['sea_' + SEA_STATES[st] + i], i, swells, st); }
  }
  // props: reeds on the river bank, a bush and rocks on the grass, driftwood on the sand; the pines
  // and palms stand in a row behind everything (`static_back`, like the west forest), never in front
  // of what the group builds on the spit.
  var midP = [], backP = [], onSand = { sh: 4, shc: '#bfae83' }, reedTops = [];
  for (i = 0; i < 8; i++) {
    y = 58 + Math.floor(rnd() * 20);
    var rx = riverEdge(y) + 3 + Math.floor(rnd() * 8);
    midP.push(obj(8, 13, rx, y + 2, reeds, { sh: 3 }));
    reedTops.push({ x: rx - 4, top: y + 2 - 13 }); // the clump's top-left, for the birds
  }
  var decor = [obj(10, 6, 96, 72, rocks, { sh: 4 }), obj(10, 6, 134, 76, rocks, { sh: 4 }),
    obj(12, 8, 156, 71, bush, { sh: 5 }), obj(12, 8, shoreEdge(75) - 52, 75, bush, { sh: 5 }),
    obj(11, 4, shoreEdge(64) - 6, 64, driftwood, { sh: 3, shc: '#bfae83' }),
    obj(11, 4, shoreEdge(75) - 7, 75, driftwood, { sh: 3, shc: '#bfae83', flip: true })];
  snapDecor(decor, 384);
  for (i = 0; i < decor.length; i++) L['decor_' + i] = layerOf([decor[i]]);
  var pineAt = [[100, 58], [118, 56], [136, 60], [154, 62]];
  for (i = 0; i < pineAt.length; i++) backP.push(obj(16, 26, pineAt[i][0], pineAt[i][1], pine, { sh: 5 }));
  var palmAt = [[58, 26], [60, 28], [59, 8]];
  for (i = 0; i < palmAt.length; i++) backP.push(obj(22, 24, shoreEdge(palmAt[i][0]) - palmAt[i][1], palmAt[i][0], palm, onSand));
  L.static_back = layerOf(backP);
  L.static_mid = layerOf(midP);
  riverLife(L, reedTops);
  tideFlats(L);
  return L;
}

// ---- river life (issue #9): fish rising, birds on the reeds, a deer at the water, the flats ------
// Every frame of a set covers the same pixels but for the small moving parts, so the click region
// built from the first does not change as they swap. No random numbers here: nothing drawn above
// moves if this changes.
function hash(x, y) { return ((x * 73856093) ^ (y * 19349663)) & 255; }
var RINGS = [[20, 64], [47, 71], [33, 77], [60, 67], [14, 74]]; // fish rise here (page-local x, y)
function ripple(B, x, y, phase) {
  if (phase == 0) { B.px(x, y - 2, '#e8f4f8'); B.px(x - 1, y - 1, '#cfd8e0'); B.px(x + 1, y - 1, '#cfd8e0'); B.px(x, y, '#d7eefa'); }
  else if (phase == 1) { B.rect(x - 2, y, 5, 1, '#d7eefa'); B.px(x, y - 1, '#d7eefa'); }
  else { B.rect(x - 4, y, 9, 1, '#a9d6ee'); B.rect(x - 2, y + 1, 5, 1, '#8cc8e8'); }
}
function bird(b, f) { // 8x9 white egret on a reed top, facing right; the head dips on frame 1
  var d = f == 1 ? 1 : 0;
  b.rect(1, 4, 5, 3, '#f7fbf7'); b.rect(1, 6, 5, 1, '#c9d3dc'); b.rect(0, 4 - (f == 2 ? 1 : 0), 1, 2, '#e4ebf0');
  b.rect(5, 1 + d, 1, 4 - d, '#f7fbf7'); b.rect(6, 0 + d, 2, 2, '#f7fbf7'); b.px(7, 1 + d, '#2a2433');
  b.px(8, 1 + d, '#f0a030'); b.px(8, 2 + d, '#f0a030');
  b.px(2, 7, '#3a3a40'); b.px(4, 7, '#3a3a40'); b.px(2, 8, '#3a3a40'); b.px(4, 8, '#3a3a40');
}
function deer(b, up) { // 22x17 doe, facing left; the head is raised or lowered towards the water
  var C = '#a8703f', CD = '#7a4c28', CL = '#d9a566';
  b.ell(14, 7, 6.5, 3.2, C); b.rect(8, 9, 13, 1, CD); b.rect(9, 6, 11, 1, CL);
  b.rect(8, 10, 1, 6, CD); b.rect(10, 10, 1, 6, CD); b.rect(17, 10, 1, 6, CD); b.rect(19, 10, 1, 6, CD);
  b.px(8, 15, '#2a2433'); b.px(10, 15, '#2a2433'); b.px(17, 15, '#2a2433'); b.px(19, 15, '#2a2433');
  b.px(20, 4, '#f7fbf7'); b.px(21, 5, '#f7fbf7');
  if (up) {
    b.line(8, 5, 5, 1, C, 2); b.rect(2, 0, 4, 3, C); b.px(1, 2, '#2a2433'); b.px(5, 0, CD); b.px(3, 0, CD); b.px(3, 1, '#1c1917');
  } else {
    b.line(8, 6, 4, 11, C, 2); b.rect(0, 11, 5, 3, C); b.px(0, 13, '#2a2433'); b.px(4, 11, CD); b.px(2, 11, CD); b.px(3, 12, '#1c1917');
  }
}
function riverLife(L, reedTops) {
  var f, k, b, n = reedTops.length, i;
  reedTops.sort(function (p, q) { return p.top - q.top; });
  for (f = 0; f < 3; f++) {
    b = new Buf(W, H);
    for (k = 0; k < RINGS.length; k++) ripple(b, RINGS[k][0], RINGS[k][1], (f + k) % 3);
    for (i = 0; i < Math.min(2, n); i++) { // the two tallest clumps each have a bird on top
      var tb = new Buf(9, 9); bird(tb, (f + i) % 3); if (i == 1) tb = mirror(tb);
      blit(b, outlined(tb, OUT), reedTops[i].x + 3 - 1 - 4, reedTops[i].top - 9);
    }
    L['life_' + f] = b;
  }
  for (f = 0; f < 2; f++) {
    var db = new Buf(22, 17); deer(db, f == 1);
    b = new Buf(W, H);
    b.ell(100, 79, 9, 1.5, '#5f8236');
    blit(b, outlined(db, OUT), 100 - 11 - 1, 79 - 17);
    L['deer_' + f] = b;
  }
}
// Low tide leaves the shore bare: a band of wet sand, pools, shells and a pale line of foam where the
// sea now ends. As the tide falls the band widens in TIDE_STEPS steps (1 thin, 3 fully out), and each
// step has TIDE_PHASES frames in which the foam laps in and out a pixel or two. Drawn over the sea and
// swapped on the sea's clock (WorldView); TideLook picks the step.
var TIDE_STEPS = [0, 0.35, 0.65, 1], TIDE_PHASES = 3;
function tideFlats(L) {
  var step, f;
  for (step = 1; step < TIDE_STEPS.length; step++)
    for (f = 0; f < TIDE_PHASES; f++) L['tide_flats_' + step + '_' + f] = flatsFrame(TIDE_STEPS[step], f);
}
function flatsFrame(frac, f) {
  var B = new Buf(W, H), x, y, s, w, d, r, c;
  for (y = G; y < H; y++) {
    s = shoreEdge(y); w = Math.max(4, Math.round((9 + Math.floor((y - G) / 3)) * frac) + f - 1);
    for (x = s; x < s + w; x++) {
      d = x - s; r = hash(x, y);
      c = d < 2 ? '#b3a47e' : (d < w - 3 ? (r < 40 ? '#a69773' : '#cdbd92') : '#bfae83');
      if (d >= w - 2) c = (x + y) % 2 == 0 ? '#f2fafc' : '#bfe4ee';
      B.px(x, y, c);
    }
    for (x = s + 2; x < s + w - 4; x++) { // small pools and shells
      r = hash(x * 3, y * 7);
      if (r < 5) { B.px(x, y, '#7cc0d8'); B.px(x + 1, y, '#9fd6e6'); }
      else if (r < 9) B.px(x, y, '#f7fbf7');
      else if (r < 12) B.px(x, y, '#e8b8a8');
    }
  }
  if (frac == 1) { B.rect(shoreEdge(72) + 3, 72, 6, 2, '#b9a88a'); B.rect(shoreEdge(72) + 3, 72, 6, 1, '#d8cbb0'); }
  return B;
}

// ---- render ---------------------------------------------------------------------------------
function composite(L) {
  var C = new Buf(W, H), stack = [L.sky, L.far_hills, L.near_hills, L.trees, L.ground, L.static_back, L.static_mid];
  for (var i = 0; i < stack.length; i++) if (stack[i]) blit(C, stack[i], 0, 0);
  for (var key in L) if (key.indexOf('decor_') == 0) blit(C, L[key], 0, 0);
  return C;
}
var west = westPage(), east = eastPage();
IMG.putImageData(composite(west).d); SPR.save();
IMG.putImageData(composite(east).d); SPR.saveAs(DIR + 'art/reference/cave_east.png');
var count = 0, sides = { west: west, east: east };
for (var side in sides) {
  for (var name in sides[side]) { IMG.putImageData(sides[side][name].d); SPR.saveAs(GAME + side + '_' + name + '.png'); count++; }
}
console.log('cave pages done, ' + count + ' game layers');
