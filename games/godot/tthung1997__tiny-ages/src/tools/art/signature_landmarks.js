// @open art/reference/signature_landmarks.png
// @canvas 384x80
// The signature building of each age (docs/ages.md, "One signature building per age"): the camp's big
// landmark in the back lane, drawn in the cave's own footprint (a 100x54 piece with its foot on row 66,
// x 0..99, entrance near x 34) so the age turning swaps the whole silhouette. The Cave Age's is the
// cave itself (cave_strip.js). Each later age redraws `static_back` (this landmark, the lone pine and the
// mammoth, the same three pieces in the same places) and the four `fire_pit_*` frames (the fire pit
// without the firelight in the cave's mouth, which would show through a wall) in its own folder
// (WorldLayout.piece_path). All pieces are full 384x80 transparent PNGs already at their final position.
//   Settled     game/assets/world/settled/   a communal longhouse: a long thatched hall of posts and daub
//   Bronze      game/assets/world/bronze/    a gatehouse: mud-brick towers round a bronze-capped arch
//   Iron        game/assets/world/iron/      a hill-fort hall: a slate footing, timber and limewash, an
//                                            iron-bound door between palisade ends
//   Classical   game/assets/world/classical/ a civic hall: a limestone porch of columns under a terracotta
//                                            pediment, a tiled hall beside it
// The slots are mirrored in game/scripts/view/world_layout.gd (SIGNATURE_RECT) and world_landmarks.gd.
// Previews: art/reference/signature_<age>.png.
seed = 91;
var W = 384, H = 80;
var IMG = SPR.layer(0).cel(0).image;
var FIREPIT = [16, 14, 72, 78];

function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, sh: o.sh, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb);
  blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

var DARK = '#2a2433', GLOWIN = '#3a3040', SMOKE = '#cfd4da', SMOKEL = '#e6e9ed';
var OAK = '#5b3d27', OAKL = '#7d5634', OAKD = '#3e281a', OAKH = '#9a6c40';

// Courses of dressed blocks: 3 rows each (two of block, one of joint), a block `bw` wide, every other
// course shifted by half a block; the tone of a block comes from its place, so it needs no random numbers.
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

// A roof that is a trapezoid in profile: the ridge from x `rl` to `rr` on row `top`, the eaves from
// `el` to `er` on row `bot`; each row is filled by `paint(x, y, t)` (t runs 0 at the ridge to 1 at the eaves).
function roof(b, top, bot, rl, rr, el, er, paint) {
  var y, x, t, l, r;
  for (y = top; y <= bot; y++) {
    t = (y - top) / (bot - top);
    l = Math.round(rl + (el - rl) * t); r = Math.round(rr + (er - rr) * t);
    for (x = l; x <= r; x++) paint(x, y, t, x == l, x == r);
  }
}

// ---- Settled: the communal longhouse -----------------------------------------------------------------------------
function longhouse(b) {
  var THAT = ['#cfa94c', '#c39b3f', '#d9b858'], THATD = '#9c7a30', STRAWL = '#ebd07a', STRAWD = '#b8923f';
  var DAUB = '#dccba0', DAUBL = '#efe2bd', DAUBD = '#b8a57a', FOOT = ['#8a8792', '#7c7986', '#9a97a0'], FOOTD = '#5f5c68';
  var x, y;
  // a low footing of fieldstone and the wattle-and-daub wall between its posts
  courses(b, 2, 49, 96, 5, FOOT, FOOTD, 6);
  b.rect(4, 34, 92, 15, DAUB);
  for (y = 36; y < 49; y += 4) for (x = 5; x < 95; x += 3) if (((x + y) % 7) == 0) b.px(x, y, DAUBD);
  for (x = 4; x < 96; x += 11) { b.rect(x, 34, 2, 15, OAK); b.px(x, 34, OAKH); b.rect(x, 34, 1, 15, OAKL); }
  b.rect(4, 41, 92, 1, OAKD); b.rect(4, 41, 92, 1, OAK);
  // the roof: a deep thatch, ridge to eaves, with the shadow of the eaves on the wall under it
  roof(b, 13, 34, 18, 82, 0, 99, function (px, py, t, left, right) {
    var c = THAT[((py >> 1) + (px >> 3)) % 3];
    if (((py * 5 + px * 3) % 11) == 0) c = THATD;
    if (py >= 33) c = THATD; else if (py >= 32) c = STRAWD;
    if (left || right) c = STRAWD;
    b.px(px, py, c);
  });
  for (x = 18; x <= 82; x++) { b.px(x, 12, STRAWL); b.px(x, 13, '#d9b858'); }
  b.rect(16, 11, 3, 3, OAKL); b.rect(81, 11, 3, 3, OAKL); // the crossed ridge-ends
  b.px(15, 9, OAKH); b.px(19, 9, OAKH); b.px(80, 9, OAKH); b.px(84, 9, OAKH);
  b.px(16, 10, OAK); b.px(18, 10, OAK); b.px(81, 10, OAK); b.px(83, 10, OAK);
  // the smoke-hole in the ridge and the smoke that finds it
  b.rect(56, 8, 9, 5, THAT[0]); b.rect(56, 8, 9, 1, STRAWL); b.rect(58, 10, 5, 3, DARK);
  b.ell(60, 5, 3, 1.8, SMOKE); b.ell(62, 3, 2.4, 1.4, SMOKEL); b.px(58, 2, SMOKEL);
  // the great door, between two carved posts, with a lintel over it and the hall's light inside
  b.rect(25, 35, 19, 3, OAK); b.rect(25, 35, 19, 1, OAKH); b.px(31, 36, DAUBL); b.px(34, 36, DAUBL); b.px(37, 36, DAUBL);
  b.rect(27, 38, 15, 15, OAKD); b.rect(28, 39, 13, 14, DARK);
  b.rect(30, 44, 9, 9, GLOWIN); b.rect(32, 47, 5, 6, '#4a3a4a');
  b.rect(26, 38, 2, 15, OAKL); b.rect(41, 38, 2, 15, OAK);
  b.px(26, 40, OAKH); b.px(41, 40, OAKH);
  // narrow slits for light, each with a sill
  for (x = 52; x < 90; x += 12) { b.rect(x, 43, 3, 5, DARK); b.rect(x - 1, 48, 5, 1, OAKL); }
  // a stack of firewood at the near end
  for (y = 44; y < 49; y += 2) b.rect(5, y, 14, 1, y % 4 == 0 ? OAKL : OAK);
  for (y = 45; y < 49; y += 2) for (x = 6; x < 18; x += 3) b.px(x, y, OAKH);
}

// ---- Bronze: the gatehouse -----------------------------------------------------------------------------------------
function gatehouse(b) {
  var BR = ['#c98f5a', '#bf8350', '#d49a64'], BRD = '#8f5f3a', BRL = '#e0ad78', MORT = '#a56e45';
  var x, y, k;
  function bricks(x0, y0, w, h) {
    courses(b, x0, y0, w, h, BR, MORT, 5);
    b.rect(x0, y0, w, 1, BRL);
  }
  // the long wings, a parapet of notches on each, and the gate tower between them
  bricks(3, 31, 19, 22); bricks(48, 29, 42, 24);
  for (x = 3; x < 22; x += 4) { b.rect(x, 28, 3, 3, BR[0]); b.rect(x, 28, 3, 1, BRL); }
  for (x = 48; x < 90; x += 4) { b.rect(x, 26, 3, 3, BR[0]); b.rect(x, 26, 3, 1, BRL); }
  bricks(20, 14, 29, 39);
  for (x = 20; x < 49; x += 5) { b.rect(x, 11, 4, 3, BR[1]); b.rect(x, 11, 4, 1, BRL); b.px(x + 3, 12, BRD); }
  b.rect(20, 14, 29, 1, BRD); b.rect(20, 25, 29, 1, BRD);
  // the shaded right side of the tower and the footing
  for (y = 15; y < 53; y++) { b.px(47, y, BRD); b.px(48, y, BRD); }
  b.rect(3, 51, 87, 2, '#8a6038');
  // the arch: bricks round a dark opening with the hall's glow, bronze caps on the jambs
  for (y = 38; y < 53; y++) {
    k = Math.max(0, 41 - y);
    for (x = 26 + k; x <= 42 - k; x++) b.px(x, y, DARK);
  }
  b.rect(29, 46, 11, 7, GLOWIN); b.rect(31, 49, 7, 4, '#4a3a4a');
  b.rect(24, 38, 2, 15, BRONZE_D); b.rect(43, 38, 2, 15, BRONZE_D);
  b.rect(24, 36, 2, 3, BRONZE); b.rect(43, 36, 2, 3, BRONZE); b.px(24, 36, BRONZE_L); b.px(43, 36, BRONZE_L);
  // arrow slits and a timber balcony on the right wing
  b.rect(30, 20, 2, 5, DARK); b.rect(37, 20, 2, 5, DARK);
  for (x = 56; x < 86; x += 10) { b.rect(x, 36, 3, 6, DARK); b.rect(x - 1, 42, 5, 1, BRD); }
  b.rect(52, 31, 3, 1, OAKL); b.rect(52, 32, 1, 3, OAK);
  b.rect(10, 38, 3, 6, DARK); b.rect(9, 44, 5, 1, BRD);
  // the standard over the gate: a bronze disc on a dark pole with a red tail
  b.rect(34, 4, 1, 8, OAKD); b.ell(34, 4, 3.5, 3.5, BRONZE); b.ell(33, 3, 1.6, 1.6, BRONZE_L); b.px(34, 4, BRONZE_D);
  b.rect(35, 7, 4, 1, '#c0392b'); b.px(39, 8, '#8f2a20');
}

// ---- Iron: the hill-fort hall ------------------------------------------------------------------------------------
// 72 wide (x 0..72): the Bloomery stands against its flank (x 73..97), so the hall must not run under it.
function hillhall(b) {
  var SL = ['#7c879a', '#6f7a8c', '#8793a6'], SLD = '#4d5667', SLL = '#a3aebf';
  var LM = '#ece6d6', LML = '#f8f4e8', LMD = '#cfc7b0';
  var THAT = ['#cfa94c', '#c39b3f', '#d9b858'], THATD = '#9c7a30', STRAWL = '#ebd07a', STRAWD = '#b8923f';
  var x, y;
  // the slate footing, then limewash laced with oak, and an iron-bound entrance between oak posts
  courses(b, 2, 42, 68, 11, SL, SLD, 6);
  b.rect(2, 42, 68, 1, SLL);
  b.rect(2, 30, 68, 12, LM); b.rect(2, 30, 68, 1, LML); b.rect(2, 41, 68, 1, LMD);
  for (x = 2; x < 70; x += 9) { b.rect(x, 30, 2, 12, OAK); b.px(x, 30, OAKH); }
  for (x = 2; x < 62; x += 9) { b.line(x + 2, 40, x + 8, 31, OAKL); }
  b.rect(2, 36, 68, 1, OAKD);
  // a steep hipped roof of thatch, an iron-capped ridge
  roof(b, 13, 30, 12, 58, 0, 70, function (px, py, t, left, right) {
    var c = THAT[((py >> 1) + (px >> 3)) % 3];
    if (((py * 7 + px * 3) % 13) == 0) c = THATD;
    if (py >= 29) c = THATD; else if (py >= 28) c = STRAWD;
    if (left || right) c = STRAWD;
    b.px(px, py, c);
  });
  for (x = 12; x <= 60; x++) { b.px(x, 12, IRON_M); b.px(x, 13, IRON_L); }
  b.rect(10, 8, 2, 5, IRON_M); b.rect(61, 8, 2, 5, IRON_M); b.px(10, 7, IRON_L); b.px(62, 7, IRON_L); b.px(11, 6, IRON_L); b.px(61, 6, IRON_L);
  // the smoke vent and its smoke
  b.rect(46, 8, 9, 5, THAT[0]); b.rect(48, 10, 5, 3, DARK); b.ell(50, 5, 3, 1.8, SMOKE); b.ell(52, 3, 2.4, 1.4, SMOKEL);
  // the door: two iron-bound leaves under a stone lintel, a lantern at the left post
  b.rect(24, 31, 21, 3, SL[2]); b.rect(24, 31, 21, 1, SLL);
  b.rect(26, 34, 17, 19, OAKD);
  for (x = 27; x < 42; x += 3) b.rect(x, 35, 2, 18, x % 2 ? OAK : OAKL);
  b.rect(34, 34, 1, 19, DARK);
  for (y = 38; y < 52; y += 6) { b.rect(27, y, 15, 1, IRON_D); b.px(28, y, IRON_L); b.px(34, y, IRON_L); b.px(40, y, IRON_L); }
  b.rect(24, 34, 2, 19, OAKL); b.rect(43, 34, 2, 19, OAK);
  b.px(22, 38, IRON_M); b.rect(21, 39, 3, 4, IRON_D); b.px(22, 40, '#f59e2b'); b.px(22, 41, '#ffd86a');
  // the palisade ends: iron-banded stakes at each end of the hall, and a slit
  for (x = 0; x < 5; x++) { b.rect(x * 2, 38 - (x % 2) * 3, 2, 15 + (x % 2) * 3, x % 2 ? OAK : OAKL); b.px(x * 2, 37 - (x % 2) * 3, OAKH); }
  for (x = 0; x < 3; x++) { b.rect(63 + x * 3, 36 - (x % 2) * 3, 3, 17 + (x % 2) * 3, x % 2 ? OAK : OAKL); }
  b.rect(52, 33, 3, 6, DARK); b.rect(51, 39, 5, 1, OAKL);
  // the iron-framed banner, slate with an ochre band
  b.rect(30, 6, 1, 7, IRON_D); b.rect(31, 7, 6, 5, '#6f7a8c'); b.rect(33, 7, 2, 5, '#b8573a'); b.px(30, 5, IRON_L);
}

// ---- Classical: the civic hall ------------------------------------------------------------------------------------
// 72 wide (x 2..72), the same reason as the hill-fort hall: a porch of columns and a short tiled wing.
function civichall(b) {
  var STONE = ['#e4dccb', '#ddd4c0', '#ebe4d4'], STONED = '#b7ad96', STONEL = '#f7f2e6', STONES = '#a29a85';
  var TERR = ['#c8663f', '#b85a36', '#d4764a'], TERRD = '#8f3f26', TERRL = '#e69468';
  var PLASTER = '#f1ead8', PLASTERD = '#d8cfb6';
  var x, y, t, i;
  // the stepped base, running the whole front
  courses(b, 2, 49, 68, 4, STONE, STONED, 7);
  b.rect(2, 49, 68, 1, STONEL); b.rect(2, 52, 68, 1, STONES);
  // the short wing on the right: plastered, a tiled roof, one arched window
  b.rect(62, 29, 8, 20, PLASTER); b.rect(62, 29, 8, 1, STONEL); b.rect(69, 29, 1, 20, PLASTERD);
  b.rect(65, 34, 3, 7, DARK); b.rect(64, 33, 5, 1, STONED); b.rect(64, 41, 5, 1, STONED);
  roof(b, 23, 29, 64, 67, 61, 70, function (px, py, t2, left, right) {
    var c = TERR[((px >> 1) + py) % 3];
    if (py == 23) c = TERRL; else if (py >= 29) c = TERRD;
    if (left || right) c = TERRD;
    b.px(px, py, c);
  });
  // the porch: a pediment on columns. A tympanum of plaster with a seal, a raking cornice, tiles above.
  roof(b, 13, 22, 33, 35, 4, 64, function (px, py, t2, left, right) {
    var c = PLASTER;
    if (left || right || py == 22) c = STONEL;
    if (py == 21) c = STONED;
    b.px(px, py, c);
  });
  for (y = 11; y <= 13; y++) for (x = 31 + (y - 11); x <= 37 - (y - 11); x++) b.px(x, y, TERR[1]); // an acroterion
  for (x = 3; x <= 65; x++) { t = Math.abs(x - 34) / 31; y = Math.round(13 + t * 9.5) - 1; b.px(x, y, TERR[x % 3]); b.px(x, y - 1, TERRD); }
  b.ell(34, 19, 3, 3, STONED); b.ell(34, 19, 2, 2, TERRL); b.px(34, 19, TERR[0]);
  // the entablature, then the columns, and the dark doorway between the middle ones
  b.rect(4, 22, 60, 5, STONE[0]); b.rect(4, 22, 60, 1, STONEL); b.rect(4, 26, 60, 1, STONED);
  for (x = 6; x < 62; x += 4) b.px(x, 24, STONED);
  var cols = [7, 15, 23, 45, 53, 61];
  b.rect(8, 29, 56, 17, '#8c8573');
  for (x = 8; x < 64; x += 4) b.px(x, 33, '#7a7360');
  b.rect(27, 31, 15, 18, STONED); b.rect(28, 32, 13, 17, DARK); b.rect(30, 38, 9, 11, GLOWIN); b.rect(32, 42, 5, 7, '#4a3a4a');
  b.rect(26, 29, 17, 2, STONE[0]); b.rect(26, 29, 17, 1, STONEL);
  for (i = 0; i < cols.length; i++) {
    x = cols[i];
    b.rect(x - 1, 27, 6, 2, STONE[2]); b.rect(x, 29, 4, 17, STONE[0]); b.rect(x, 29, 1, 17, STONEL); b.rect(x + 3, 29, 1, 17, STONED);
    for (y = 31; y < 46; y += 3) b.px(x + 1, y, STONED);
    b.rect(x - 1, 46, 6, 3, STONE[2]); b.rect(x - 1, 48, 6, 1, STONED);
  }
  // the town's banner, red and white, on a pole over the pediment
  b.rect(34, 1, 1, 11, IRON_M); b.rect(35, 2, 6, 5, '#b8402f'); b.rect(35, 4, 6, 1, '#efe6d0'); b.px(34, 0, IRON_L);
}

// ---- Classical: a bronze brazier in place of the camp fire (16x14, foot row 78) ---------------------------------
function brazier(b, frame) {
  var fl = FLAMES[frame || 0], i, BD = '#6e4a1a';
  b.line(4, 13, 7, 9, BD, 1); b.line(12, 13, 9, 9, BD, 1); b.rect(8, 9, 1, 5, BD); b.rect(5, 13, 7, 1, BD);
  b.tri(fl.cx, fl.top, fl.h - 2, 3, '#f59e2b', '#e5732b'); b.tri(fl.ix, 3, 4, 1, '#ffe27a', '#ffe27a');
  for (i = 0; i < fl.spark.length; i++) b.px(fl.spark[i][0], Math.max(0, fl.spark[i][1] - 1), fl.spark[i][2]);
  b.ell(8, 8, 5.5, 2.4, BRONZE_D); b.ell(8, 7.4, 5.2, 1.8, BRONZE); b.rect(4, 6, 9, 1, BRONZE_L);
  b.ell(8, 7, 3.6, 1, '#3a2a22'); b.rect(6, 7, 5, 1, '#e5732b'); b.px(8, 7, '#ffe27a');
}
function pineOnly() { return [obj(16, 26, 204, 65, pine, { sh: 6 })]; }

function flameFn(frame, kind) { return function (b) { (kind == 'classical' ? brazier : firepit)(b, frame); }; }

var AGES = [
  ['settled', longhouse], ['bronze', gatehouse], ['iron', hillhall], ['classical', civichall]
];
var ai, ap, i, back, count = 0;
for (ai = 0; ai < AGES.length; ai++) {
  ap = AGES[ai];
  var dir = DIR + 'game/assets/world/' + ap[0] + '/';
  back = layerOf(pineOnly().concat([obj(100, 54, 50, 66, ap[1], { sh: 34 })]));
  IMG.putImageData(back.d); SPR.saveAs(dir + 'static_back.png'); count++;
  if (ai == 0) SPR.saveAs(DIR + 'art/reference/signature_landmarks.png');
  IMG.putImageData(back.d); SPR.saveAs(DIR + 'art/reference/signature_' + ap[0] + '.png');
  for (i = 0; i < FLAMES.length; i++) {
    IMG.putImageData(layerOf([obj(FIREPIT[0], FIREPIT[1], FIREPIT[2], FIREPIT[3], flameFn(i, ap[0]), { sh: 8 })]).d);
    SPR.saveAs(dir + 'fire_pit_' + i + '.png'); count++;
  }
}
console.log('signature landmarks done, ' + count + ' game layers');
