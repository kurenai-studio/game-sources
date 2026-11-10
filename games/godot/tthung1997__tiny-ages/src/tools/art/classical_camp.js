// @open art/reference/classical_camp.png
// @canvas 384x80
// Classical Age world pieces (docs: ages, "Classical Age"): what the town gains, or upgrades in place, once
// it takes its seat among cities. Cave, Settled, Bronze and Iron art is kept; a slot the Classical Age
// redraws uses the same layer name in its own folder (WorldLayout.piece_path). The look is limestone and
// plaster, terracotta tile, columns and arches: pale and warm where the Iron Age was slate and thatch. The
// camp's big landmark is drawn by signature_landmarks.js. Game assets (game/assets/world/classical/), each
// a full 384x80 transparent PNG, every piece already at its final position (page-local x; world x =
// local - 384 on the west page, + 384 on the east):
//   camp page   building_hut (the Hut's slot redrawn in place: a plastered stone house under tile),
//               the street, laid in slabs from the west edge to the bridge in five pieces (paved_street_market and paved_street_west on the west page, paved_street_hall, paved_street, paved_street_bank on the camp page; one per place, in place of road_camp)
//   west page   west_roof_a / west_roof_b (the village's two small houses redrawn in place),
//               law_pillar (an inscribed pillar at the market's left edge), market_arcade (the square:
//               an arcade of arches under a tiled roof, which takes in the market stalls, the council
//               ring, the writing post and the coin tray), water_court (a basin under arches, in place
//               of the well)
//   east page   east_theatre (a two-storey arcade with stepped seats over it, on the back lane), east_harbour (a stone
//               mole with a lighthouse and moored ships, in place of the deep-keeled ship)
// Slots are mirrored in game/scripts/view/scene_props.gd and world_layout.gd.
// Previews: art/reference/classical_camp.png, classical_west.png, classical_east.png.
seed = 97;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/classical/';
var IMG = SPR.layer(0).cel(0).image;

function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, raw: o.raw, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  if (ob.raw) blit(buf, tb, ob.x, ob.y); else blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

var STONE = ['#e4dccb', '#ddd4c0', '#ebe4d4'], STONED = '#b7ad96', STONEL = '#f7f2e6', STONES = '#a29a85';
var TERR = ['#c8663f', '#b85a36', '#d4764a'], TERRD = '#8f3f26', TERRL = '#e69468';
var PLASTER = '#f1ead8', PLASTERD = '#d8cfb6', DARK = '#2a2433', GLOWIN = '#3a3040';
var OAK = '#5b3d27', OAKL = '#7d5634', OAKD = '#3e281a', OAKH = '#9a6c40';
var WATER = '#4f93c4', WATERL = '#8cc8e8', WATERD = '#2f6890';
var SIL = '#e6edf5';

function courses(b, x, y, w, h, pal, joint, bw) {
  var r, xx, yy, x0, x1, tone, bh;
  b.rect(x, y, w, h, joint);
  for (r = 0; y + r * 3 < y + h; r++) {
    yy = y + r * 3; bh = Math.min(2, y + h - yy);
    for (xx = x - (r % 2) * Math.floor(bw / 2); xx < x + w; xx += bw + 1) {
      tone = (xx * 7 + r * 13 + ((xx * r) % 5)) % 3; if (tone < 0) tone += 3;
      x0 = Math.max(xx, x); x1 = Math.min(xx + bw, x + w);
      if (x1 > x0) b.rect(x0, yy, x1 - x0, bh, pal[tone]);
    }
  }
}
function roof(b, top, bot, rl, rr, el, er, paint) {
  var y, x, t, l, r;
  for (y = top; y <= bot; y++) {
    t = (y - top) / (bot - top);
    l = Math.round(rl + (el - rl) * t); r = Math.round(rr + (er - rr) * t);
    for (x = l; x <= r; x++) paint(x, y, t, x == l, x == r);
  }
}
// A tiled roof: rows of terracotta, a lit ridge row, a dark eave row, and a darker edge.
function tiles(b, top, bot, rl, rr, el, er) {
  roof(b, top, bot, rl, rr, el, er, function (px, py, t, left, right) {
    var c = TERR[((px >> 1) + py) % 3];
    if (py == top) c = TERRL; else if (py >= bot) c = TERRD;
    if (left || right) c = TERRD;
    b.px(px, py, c);
  });
}

// ---- the Hut's slot (34x24, foot row 23): a plastered stone house with a tiled hip roof and a balcony -----------
function stonehouse(b) {
  var x, y;
  courses(b, 2, 18, 30, 6, STONE, STONED, 6); b.rect(2, 18, 30, 1, STONEL);
  b.rect(3, 10, 28, 8, PLASTER); b.rect(3, 10, 28, 1, STONEL); b.rect(3, 17, 28, 1, PLASTERD);
  b.rect(3, 10, 2, 14, STONE[2]); b.rect(29, 10, 2, 14, STONE[0]); // quoins at the corners
  tiles(b, 1, 10, 9, 24, 0, 33);
  b.rect(8, 0, 2, 3, STONE[1]); b.rect(8, 0, 2, 1, STONEL); // a chimney
  // a balcony over the door, a shuttered window beside it
  b.rect(12, 15, 10, 1, OAKL); b.rect(12, 14, 1, 2, OAK); b.rect(21, 14, 1, 2, OAK); b.rect(12, 16, 10, 1, OAKD);
  b.rect(7, 12, 4, 5, DARK); b.rect(6, 11, 6, 1, STONED); b.rect(6, 17, 6, 1, STONED); b.rect(6, 12, 1, 5, OAK); b.rect(11, 12, 1, 5, OAK);
  b.rect(23, 12, 4, 5, DARK); b.rect(22, 11, 6, 1, STONED); b.rect(22, 17, 6, 1, STONED); b.rect(22, 12, 1, 5, OAK); b.rect(27, 12, 1, 5, OAK);
  // the arched door under the balcony, and a flower box of red
  b.rect(14, 18, 6, 6, DARK); b.rect(15, 17, 4, 1, DARK); b.rect(13, 18, 1, 6, STONED); b.rect(20, 18, 1, 6, STONED); b.rect(14, 16, 6, 1, STONED);
  b.rect(6, 17, 6, 1, OAKL); for (x = 6; x < 12; x += 2) b.px(x, 16, '#d85a4a');
}

// ---- the village's two small houses (26x19, foot row 18) ------------------------------------------------------
function smallstonehouse(b) {
  var x;
  courses(b, 2, 14, 22, 5, STONE, STONED, 6); b.rect(2, 14, 22, 1, STONEL);
  b.rect(3, 8, 20, 6, PLASTER); b.rect(3, 8, 20, 1, STONEL); b.rect(3, 13, 20, 1, PLASTERD);
  b.rect(3, 8, 2, 11, STONE[2]); b.rect(21, 8, 2, 11, STONE[0]);
  tiles(b, 1, 8, 8, 17, 0, 25);
  b.rect(18, 0, 2, 3, STONE[1]); b.rect(18, 0, 2, 1, STONEL);
  b.rect(6, 10, 4, 4, DARK); b.rect(5, 9, 6, 1, STONED); b.rect(5, 13, 6, 1, STONED);
  b.rect(12, 14, 5, 5, DARK); b.rect(13, 13, 3, 1, DARK); b.rect(11, 14, 1, 5, STONED); b.rect(17, 14, 1, 5, STONED); b.rect(12, 12, 5, 1, STONED);
  b.rect(18, 11, 3, 3, DARK); b.rect(17, 10, 5, 1, STONED);
}

// ---- the square: an arcade of arches under a tiled roof (54x27, foot row 26) -----------------------------------
function arcade(b) {
  var x, y, k, goods = ['#c0504a', '#d9a23a', '#6a9a4a', '#4a7fa8'];
  // base steps
  courses(b, 0, 24, 54, 3, STONE, STONED, 7); b.rect(0, 24, 54, 1, STONEL); b.rect(0, 26, 54, 1, STONES);
  // the back wall in shadow, with the goods in each bay
  b.rect(2, 9, 50, 15, '#8c8573');
  for (x = 2; x < 52; x += 4) b.px(x, 13, '#7a7360');
  // roof: a tiled slope with a cornice under it
  tiles(b, 0, 6, 3, 50, 0, 53);
  b.rect(0, 7, 54, 2, STONE[0]); b.rect(0, 7, 54, 1, STONEL); b.rect(0, 8, 54, 1, STONED);
  // four bays between piers: a dark arch, an awning in each, and a few goods
  for (k = 0; k < 4; k++) {
    var x0 = 4 + k * 12;
    for (y = 10; y < 24; y++) {
      var inset = y < 13 ? 13 - y : 0;
      for (x = x0 + inset; x <= x0 + 8 - inset; x++) b.px(x, y, y < 22 ? '#3a3040' : '#6a6454');
    }
    b.rect(x0 + 1, 14, 7, 2, k % 2 ? '#c0504a' : '#efe6d0'); b.rect(x0 + 1, 16, 7, 1, k % 2 ? '#8f3a2d' : '#d8cdb0'); // an awning
    b.px(x0 + 2, 21, goods[k % 4]); b.px(x0 + 4, 22, goods[(k + 1) % 4]); b.px(x0 + 6, 21, goods[(k + 2) % 4]); b.rect(x0 + 1, 22, 7, 1, '#6a5238');
    b.rect(x0 - 2, 9, 3, 15, STONE[2]); b.rect(x0 - 2, 9, 1, 15, STONEL); b.rect(x0, 9, 1, 15, STONED); // the pier on the left
  }
  b.rect(50, 9, 3, 15, STONE[2]); b.rect(50, 9, 1, 15, STONEL); b.rect(52, 9, 1, 15, STONED);
  b.rect(26, 5, 2, 4, STONED); b.rect(26, 2, 2, 4, IRON_M); b.rect(27, 2, 6, 3, '#b8402f'); b.px(26, 1, IRON_L); // a banner at the roof
}
// ---- an inscribed pillar at the market's left edge (10x20, foot row 19) ------------------------------------------
function lawpillar(b) {
  var y;
  b.rect(0, 17, 10, 3, STONE[0]); b.rect(0, 17, 10, 1, STONEL); b.rect(1, 16, 8, 1, STONED);
  b.rect(2, 2, 6, 14, STONE[0]); b.rect(2, 2, 1, 14, STONEL); b.rect(7, 2, 1, 14, STONED);
  b.rect(1, 0, 8, 3, STONE[2]); b.rect(1, 0, 8, 1, STONEL); b.rect(1, 2, 8, 1, STONED);
  for (y = 4; y < 15; y += 2) { b.rect(3, y, 4, 1, '#6a5a3a'); if (y % 4 == 0) b.px(6, y, STONE[0]); }
  b.rect(3, 15, 4, 1, TERR[0]);
}

// ---- the water court (16x22, foot row 21): a basin under two arches --------------------------------------------
function watercourt(b) {
  var x, y;
  courses(b, 0, 14, 16, 8, STONE, STONED, 5); b.rect(0, 14, 16, 1, STONEL);
  b.rect(1, 16, 14, 3, WATER); b.rect(1, 16, 14, 1, WATERL); b.px(4, 17, WATERL); b.px(10, 18, WATERL);
  b.rect(0, 4, 16, 10, STONE[0]); b.rect(0, 4, 16, 1, STONEL);
  // one wide arch with a lion-head spout in its back wall, pilasters either side
  for (y = 6; y < 14; y++) { var inset = y < 9 ? 9 - y : 0; for (x = 3 + inset; x <= 12 - inset; x++) b.px(x, y, '#5e6a78'); }
  b.rect(0, 5, 2, 9, STONE[2]); b.rect(0, 5, 1, 9, STONEL); b.rect(14, 5, 2, 9, STONE[0]);
  b.rect(7, 9, 2, 2, STONES); b.px(7, 9, STONEL);
  b.rect(7, 11, 2, 3, WATERL);  b.rect(7, 14, 2, 1, WATER); b.px(7, 15, WATERL); b.px(8, 15, WATERL); // a spout and its fall
  b.rect(0, 2, 16, 3, STONE[2]); b.rect(0, 2, 16, 1, STONEL); b.rect(0, 4, 16, 1, STONED);
  b.rect(6, 0, 4, 2, TERR[0]); b.rect(6, 0, 4, 1, TERRL); // an amphora on the parapet
}

// ---- a paved street (w x 5, raw, on the front lane's top rows): set slabs with a lit curb ---------------------------
function pavedstreet(w) {
  return function (b) {
    var x, y;
    for (y = 0; y < 5; y++) for (x = 0; x < w; x++) {
      var off = (y % 2) * 3, edge = ((x + off) % 7) == 0;
      b.px(x, y, y == 0 ? '#e0dac9' : (edge ? '#8f8a7c' : (y == 4 ? '#a8a292' : '#bdb7a6')));
    }
    for (x = 1; x < w; x += 9) b.px(x, 2, '#cfc9b8');
  };
}
// ---- the theatre (46x25, foot row 66): a two-storey arcade round the stage, the stepped seats showing over it ----
function theatre(b) {
  var x, y, k, x0, inset;
  b.rect(0, 23, 46, 2, STONES); b.rect(0, 23, 46, 1, STONED);
  // the seats, in steps above the roof of the arcade
  b.rect(10, 0, 26, 1, STONEL); b.rect(6, 1, 34, 2, STONE[0]); b.rect(6, 1, 34, 1, STONEL); b.rect(2, 3, 42, 2, STONE[2]); b.rect(2, 3, 42, 1, STONEL);
  for (x = 8; x < 40; x += 6) { b.px(x, 2, STONED); b.px(x + 2, 4, STONED); }
  b.rect(8, 0, 1, 1, TERR[0]); b.rect(37, 0, 1, 1, TERR[0]); // two awning poles' tops
  // the upper arcade: small windows
  b.rect(1, 5, 44, 8, STONE[0]); b.rect(1, 5, 44, 1, STONEL);
  for (k = 0; k < 6; k++) { x0 = 4 + k * 7; b.rect(x0, 7, 3, 5, DARK); b.rect(x0 - 1, 6, 5, 1, STONED); b.rect(x0 - 1, 12, 5, 1, STONED); }
  b.rect(0, 13, 46, 1, STONEL); b.rect(0, 14, 46, 1, STONED);
  // the lower arcade: round arches on piers
  b.rect(1, 15, 44, 8, STONE[1]);
  for (k = 0; k < 6; k++) {
    x0 = 3 + k * 7;
    for (y = 16; y < 23; y++) { inset = y < 18 ? 18 - y : 0; for (x = x0 + inset; x <= x0 + 4 - inset; x++) b.px(x, y, y < 21 ? DARK : '#3a3040'); }
    b.rect(x0 - 2, 15, 2, 8, STONE[2]); b.rect(x0 - 2, 15, 1, 8, STONEL);
  }
  b.rect(43, 15, 2, 8, STONE[2]); b.rect(44, 15, 1, 8, STONED);
  // a red banner at one end
  b.rect(42, 0, 1, 5, IRON_M); b.rect(43, 0, 3, 3, '#b8402f');
}

// ---- the harbour (84x34, foot row 72): a stone mole running out from the shore with the lighthouse standing on its end ---
function harbour(b) {
  var x, y, hw;
  // the mole: ashlar along the water with mooring rings and a walkway on top; the shore end has a landing
  courses(b, 0, 21, 74, 8, STONE, STONED, 7); b.rect(0, 21, 74, 2, STONEL); b.rect(0, 22, 74, 1, STONE[0]);
  for (x = 6; x < 58; x += 14) { b.rect(x, 24, 2, 2, IRON_M); b.px(x, 24, IRON_L); }
  b.rect(0, 23, 3, 6, STONE[2]); b.rect(0, 23, 1, 6, STONEL);
  for (x = 0; x < 74; x++) { b.px(x, 29, WATERD); b.px(x, 30, (x % 6 < 3) ? WATER : WATERL); }
  // the lighthouse stands on the mole's end: a tapering shaft in courses, a gallery, a glass lantern and its flame
  for (y = 6; y < 22; y++) { hw = 3 + Math.floor((y - 6) / 6); courses(b, 66 - hw, y, hw * 2 + 1, 1, STONE, STONED, 4); }
  b.rect(61, 21, 11, 1, STONEL);
  b.rect(62, 12, 9, 1, TERR[1]); b.rect(63, 9, 7, 3, DARK);
  b.rect(64, 9, 5, 3, '#f59a3a'); b.rect(65, 10, 3, 2, '#ffe27a');
  tiles(b, 5, 8, 66, 66, 62, 70); b.px(66, 4, IRON_L);
}

// ---- a trading ship moored along the mole (26x18, outlined on its own so it reads against the stone) ------------
function ship(b) {
  var x;
  b.rect(2, 15, 22, 2, '#5a3a26'); b.rect(3, 17, 20, 1, '#3a281a'); b.rect(1, 14, 24, 1, OAKL);
  b.px(0, 13, OAKL); b.px(1, 13, OAKL); b.px(25, 12, OAKL); b.px(24, 13, OAKL); b.px(25, 13, OAKL); // a raised prow and stern
  b.rect(3, 15, 20, 1, '#e8dcb8');
  for (x = 5; x < 22; x += 4) b.px(x, 16, '#c9b88a'); // oar ports
  b.rect(13, 1, 1, 13, OAK);
  b.rect(5, 2, 17, 1, OAK);
  for (x = 7; x < 20; x++) for (var y = 3; y < 11; y++) b.px(x, y, (x % 4 < 2) ? '#c0504a' : '#f3e9d2');
  b.rect(7, 3, 13, 1, '#a8402f'); b.rect(7, 10, 13, 1, '#d8cdb0');
  b.rect(14, 0, 4, 2, '#b8402f');
}

// ---- the lighthouse's night light (east page, full 384x80): dithered warm bands round the lantern, drawn
// additively by the game like the Iron Age's beacon glow, and replacing it (same name) from the Classical Age on.
function lighthouseglow() {
  var g = new Buf(W, H), gx, gy, dx, dy, dd, v, a, bi;
  var bands = [[0.4, 150], [0.65, 100], [0.85, 56], [1.0, 26]];
  for (gy = 0; gy < H; gy++) for (gx = 0; gx < W; gx++) {
    dx = (gx - 303) / 34; dy = (gy - 48) / 24; dd = Math.sqrt(dx * dx + dy * dy); v = 0;
    for (bi = 0; bi < bands.length; bi++) {
      if (dd < bands[bi][0]) { v = bands[bi][1]; if (bi + 1 < bands.length && bands[bi][0] - dd < 0.07 && ((gx + gy) & 1) == 0) v = bands[bi + 1][1]; break; }
    }
    a = (gy * W + gx) * 4;
    if (v > 0) { g.d[a] = 255; g.d[a + 1] = 154; g.d[a + 2] = 60; g.d[a + 3] = v; }
  }
  return g;
}
var layers = {};
layers.building_hut = layerOf([obj(34, 24, 268, 71, stonehouse, { sh: 14 })]);
layers.west_roof_a = layerOf([obj(26, 19, 172, 72, smallstonehouse, { sh: 11 })]);
layers.west_roof_b = layerOf([obj(26, 19, 148, 71, smallstonehouse, { sh: 11, flip: 1 })]);
layers.market_arcade = layerOf([obj(54, 27, 28, 64, arcade, { sh: 0, z: 67 })]);
layers.law_pillar = layerOf([obj(10, 20, 6, 66, lawpillar, { sh: 0 })]);
layers.water_court = layerOf([obj(16, 22, 197, 75, watercourt, { sh: 0 })]);
layers.paved_street_market = layerOf([obj(56, 5, 28, 80, pavedstreet(56), { sh: 0, raw: true })]);
layers.paved_street_west = layerOf([obj(328, 5, 220, 80, pavedstreet(328), { sh: 0, raw: true })]);
layers.paved_street_hall = layerOf([obj(88, 5, 44, 80, pavedstreet(88), { sh: 0, raw: true })]);
layers.paved_street = layerOf([obj(176, 5, 176, 80, pavedstreet(176), { sh: 0, raw: true })]);
layers.paved_street_bank = layerOf([obj(40, 5, 284, 80, pavedstreet(40), { sh: 0, raw: true })]);
layers.east_theatre = layerOf([obj(46, 25, 138, 66, theatre, { sh: 0, z: 67 })]);
layers.east_harbour = layerOf([obj(84, 34, 279, 72, harbour, { sh: 0 }), obj(26, 18, 289, 75, ship, { sh: 0 })]);
layers.east_beacon_glow = lighthouseglow();

var groups = [
  ['classical_camp', ['building_hut', 'paved_street', 'paved_street_hall']],
  ['classical_west', ['paved_street_market', 'paved_street_west', 'market_arcade', 'law_pillar', 'water_court', 'west_roof_a', 'west_roof_b']],
  ['classical_east', ['east_theatre', 'east_harbour'], 'sea']
], gi, gj, P, name, x, y;
for (gi = 0; gi < groups.length; gi++) {
  P = new Buf(W, H);
  for (y = 0; y < G; y++) for (x = 0; x < W; x++) P.px(x, y, '#9cc4de');
  for (y = G; y < H; y++) for (x = 0; x < W; x++) P.px(x, y, y < G + 13 ? '#86a94c' : '#789a43');
  if (groups[gi][2] == 'sea') for (y = 57; y < H; y++) for (x = 200; x < W; x++) P.px(x, y, y < 60 ? '#3b79ad' : '#2f6890');
  for (gj = 0; gj < groups[gi][1].length; gj++) blit(P, layers[groups[gi][1][gj]], 0, 0);
  IMG.putImageData(P.d); if (gi == 0) SPR.save(); else SPR.saveAs(DIR + 'art/reference/' + groups[gi][0] + '.png');
}
var count = 0;
for (name in layers) { IMG.putImageData(layers[name].d); SPR.saveAs(GAME + name + '.png'); count++; }
console.log('classical camp done, ' + count + ' game layers');
