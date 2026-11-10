// @open art/reference/iron_camp.png
// @canvas 384x80
// Iron Age world pieces (docs: ages "Iron Age", "What Iron tidies", V10): what the camp gains, or
// upgrades in place, once the dark stone is smelted. Cave, Settled and Bronze art is kept; a slot
// the Iron Age redraws uses the same layer name in its own folder (WorldLayout.piece_path). The look
// is forged iron, slate and limewash, oak laced with stone, a little rust: dark and cool where the
// Bronze Age was warm mud-brick and copper. Game assets (game/assets/world/iron/), each a full
// 384x80 transparent PNG, every piece already at its final position (page-local x; world x =
// local - 384 on the west page, + 384 on the east):
//   camp page   building_bloomery, site_bloomery (a tall clay-and-stone furnace with a bellows and
//               charcoal sacks, against the cave's flank), building_granary, site_granary (a raised
//               timber store on stone staddles, in front of the mammoth), slag_heap (cave yard),
//               standing_stone (the crossing's near bank); the Hut's slot and the Lookout's slot
//               redrawn in place under the same names: building_hut / site_hut (timber and daub under
//               a deep thatch), building_lookout / site_lookout (an iron-bound gate tower)
//   west page   rampart (the Bronze town wall redrawn: oak-laced stone, a palisade and an
//               iron-bound gate tower, same span x 59..383 and gate x 203..231), plough_team,
//               shearing_pen (at the farmstead and the sheepfold), coin_tray (a trestle beside the
//               market, at the village's edge), writing_post (a tablet on a post at the market's left edge, in
//               place of the tally post), west_roof_a / west_roof_b (timber-and-daub houses)
//   east page   east_deep_ship (replaces the trading ship), east_beacon (a fire on a cairn),
//               east_beacon_1..3 (its other flame frames), east_beacon_glow (its night light, drawn additively by WorldView)
// Slots are mirrored in game/scripts/view/world_layout.gd (BUILDINGS) and scene_props.gd.
// Previews: art/reference/iron_camp.png, iron_west.png, iron_east.png.
seed = 71;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/iron/';
var IMG = SPR.layer(0).cel(0).image;

function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, raw: o.raw, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  if (ob.raw) blit(buf, tb, ob.x, ob.y); else blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

// forged iron, slate, limewash, oak, rust, thatch
var IRD = IRON_D, IRM = IRON_M, IRL = IRON_L, IRH = '#cfd7e2';
var SL = ['#7c879a', '#6f7a8c', '#8793a6'], SLD = '#4d5667', SLM = '#5f6a7c', SLL = '#a3aebf';
var LM = '#ece6d6', LML = '#f8f4e8', LMD = '#cfc7b0', LMS = '#a8a08a';
var RU = '#a8552e', RUL = '#c9743c', RUD = '#7a3a20';
var OAK = '#5b3d27', OAKL = '#7d5634', OAKD = '#3e281a', OAKH = '#9a6c40';
var CLAYI = '#a9674a', CLAYIL = '#c58a68', CLAYID = '#7e4a37', CI = ['#a9674a', '#9c5d42', '#b4714f'];
var GLOW = '#f59e2b', GLOWL = '#ffd86a', EMBER = '#e0614a', DARK = '#2a2433', SMOKE = '#cfd4da', SMOKEL = '#e6e9ed';
var STRAW = '#d9b858', STRAWL = '#ebd07a', STRAWD = '#b8923f', THAT = ['#cfa94c', '#c39b3f', '#d9b858'], THATD = '#9c7a30';
var CLOTH = '#efe6cf', CLOTHD = '#cdc0a0', RED = '#c0504a', REDD = '#8f3a2d', CORD = '#f0e4c0';
var WATER = '#4f93c4', WATERL = '#8cc8e8', EARTH = '#8a5a36', EARTHD = '#6f4528';
var SILVER = '#e6edf5', SILVERD = '#aab6c6';

// Courses of dressed slate or clay-and-stone, 3 rows each (two of block, one of joint), a block 5 wide,
// every other course shifted half a block; the tone of a block comes from its place.
function blocks(b, x, y, w, h, pal, joint) {
  var r, xx, yy, x0, x1, tone, bh;
  b.rect(x, y, w, h, joint);
  for (r = 0; y + r * 3 < y + h; r++) {
    yy = y + r * 3; bh = Math.min(2, y + h - yy);
    for (xx = x - (r % 2) * 3; xx < x + w; xx += 6) {
      tone = (xx * 7 + r * 13 + ((xx * r) % 5)) % 3; if (tone < 0) tone += 3;
      x0 = Math.max(xx, x); x1 = Math.min(xx + 5, x + w);
      if (x1 > x0) b.rect(x0, yy, x1 - x0, bh, pal[tone]);
    }
  }
}

// ---- the Bloomery (camp slot, 22x34) --------------------------------------------------------------
// A tall conical furnace of clay and stone in courses, bound with three iron hoops, a rim at the top
// with smoke, an arched mouth glowing at the foot, a leather bellows on a lever at the left and a
// stack of charcoal sacks at the right, on a slate plinth.
function bloomery(b) {
  var x, y, hw, dx, cx = 11, i, hoops = [12, 18, 24], c;
  for (y = 5; y <= 30; y++) {
    hw = 3.4 + (y - 5) * (4.2 / 25);
    for (x = Math.ceil(cx - hw); x <= Math.floor(cx + hw); x++) {
      dx = (x - cx) / hw;
      if (y % 3 == 0 || (x + (y % 2) * 3) % 6 == 0) c = CLAYID;
      else c = dx < -0.35 ? CLAYIL : (dx > 0.45 ? CLAYID : CI[(x + y) % 3]);
      if (c == CLAYID && dx < -0.35 && y % 3 != 0) c = CI[1];
      b.px(x, y, c);
    }
  }
  b.rect(cx - 5, 3, 11, 2, CLAYID); b.rect(cx - 5, 3, 11, 1, CLAYIL); b.px(cx - 5, 4, CLAYI); b.px(cx + 5, 3, CLAYI);
  b.rect(cx - 3, 3, 7, 1, DARK); b.rect(cx - 2, 3, 5, 1, EMBER); b.px(cx, 3, GLOW);
  b.ell(cx + 1, 1.2, 2.6, 1.3, SMOKE); b.px(cx - 1, 0, SMOKEL); b.px(cx + 2, 0, SMOKEL);
  for (i = 0; i < hoops.length; i++) {
    y = hoops[i]; hw = 3.4 + (y - 5) * (4.2 / 25) + 0.8;
    b.rect(Math.round(cx - hw), y, Math.round(hw * 2) + 1, 1, IRM); b.rect(Math.round(cx - hw), y + 1, Math.round(hw * 2) + 1, 1, IRD);
    for (x = Math.round(cx - hw) + 1; x < cx + hw; x += 4) b.px(x, y, IRL);
  }
  // the mouth: an arch of dark iron-bound stone, glowing inside
  b.rect(cx - 4, 23, 9, 8, IRD); b.rect(cx - 3, 22, 7, 1, IRD);
  b.rect(cx - 3, 24, 7, 7, DARK); b.rect(cx - 2, 23, 5, 1, DARK);
  b.rect(cx - 3, 27, 7, 4, EMBER); b.rect(cx - 2, 28, 5, 3, GLOW); b.rect(cx - 1, 29, 3, 2, GLOWL);
  b.px(cx - 4, 23, IRM); b.px(cx + 4, 23, IRM); b.rect(cx - 4, 24, 1, 7, IRM);
  // the plinth
  b.rect(1, 31, 20, 3, SLM); b.rect(1, 31, 20, 1, SLL); b.rect(1, 33, 20, 1, SLD);
  for (x = 4; x < 20; x += 5) b.px(x, 32, SLD);
  // the bellows on its lever at the left: leather ribs between two oak boards, a nozzle into the furnace
  var bx, top;
  for (bx = 0; bx < 6; bx++) {
    top = 24 + Math.round(bx * 0.5);
    b.rect(bx, top, 1, 30 - top, ((bx % 2) ? '#8a5f33' : '#b8864f'));
    b.px(bx, top, OAKH); b.px(bx, top + 1, bx % 2 ? '#a07040' : '#d9a86a');
  }
  b.rect(0, 30, 6, 1, OAKL); b.px(0, 30, OAKD); b.rect(0, 23, 1, 7, OAKL); b.px(0, 23, OAKH);
  b.line(5, 28, 7, 28, IRM, 1); b.px(6, 28, IRL); b.rect(5, 27, 1, 2, IRD);
  b.line(1, 23, 1, 17, OAK, 1); b.px(1, 16, OAKH); b.px(0, 16, OAKL); b.px(2, 16, OAKL); b.px(2, 18, CORD); b.px(2, 19, CORD);
  // charcoal sacks at the right: two below, one on top, a tie and spilled lumps
  b.ell(18.5, 27.5, 2.6, 3.2, '#3a3640'); b.px(17, 25, '#575263'); b.px(18, 24, '#575263'); b.rect(18, 23, 2, 1, CORD); b.px(19, 24, '#2a2630');
  b.ell(20, 30, 2.4, 2.4, '#34303a'); b.px(19, 29, '#575263'); b.rect(19, 27, 2, 1, CORD);
  b.ell(14.5, 30, 2.4, 2.2, '#3f3b48'); b.px(13, 29, '#5f5a6a'); b.px(14, 27, CORD); b.rect(14, 28, 2, 1, CORD);
  b.px(16, 32, '#2a2630'); b.px(12, 32, '#2a2630'); b.px(17, 32, '#575263');
}
// The site, 24x12: a ring of clay-and-stone half raised, a heap of clay, a sack and two stakes with a bellows board.
function bloomerysite(b) {
  b.ell(11, 8.5, 9, 2.8, '#7a6048');
  blocks(b, 3, 6, 11, 3, CI, CLAYID); b.rect(3, 6, 11, 1, CLAYIL);
  blocks(b, 2, 8, 5, 3, CI, CLAYID); b.rect(2, 8, 5, 1, CLAYIL);
  blocks(b, 9, 9, 7, 3, CI, CLAYID); b.rect(9, 9, 7, 1, CLAYIL);
  b.ell(19, 9, 3.2, 2.4, CLAYI); b.ell(18, 8, 2, 1.2, CLAYIL); b.px(21, 10, CLAYID);
  b.ell(5, 4, 2.5, 3, '#3a3640'); b.px(4, 2, '#575263'); b.px(5, 0, CORD); b.rect(4, 1, 2, 1, CORD);
  b.rect(20, 3, 1, 6, OAK); b.px(20, 3, OAKL); b.rect(22, 4, 1, 5, OAK); b.line(20, 5, 22, 5, CORD, 1);
  b.rect(8, 3, 5, 1, OAKL); b.px(8, 3, OAKH);
}

// ---- the Granary (camp slot, 26x30) -----------------------------------------------------------------
// A raised timber store on stone staddles (mushroom stones against rats), oak-framed limewashed
// walls with a brace, a hatch door at the head of a ladder, and a deep thatched roof.
function granary(b) {
  var x, r, hw, i, st = [2, 9, 15];
  // staddles: a stem and a flat cap each
  for (i = 0; i < st.length; i++) {
    x = st[i];
    b.rect(x + 1, 25, 3, 5, SL[1]); b.rect(x + 1, 25, 1, 5, SL[2]); b.rect(x + 3, 25, 1, 5, SLD);
    b.rect(x, 24, 5, 2, SL[2]); b.rect(x, 24, 5, 1, SLL); b.rect(x, 25, 5, 1, SLM);
    b.px(x + 2, 28, SLD);
  }
  b.rect(1, 29, 20, 1, SLD);
  // floor beams, walls
  b.rect(1, 22, 22, 2, OAKL); b.rect(1, 22, 22, 1, OAKH); b.rect(1, 23, 22, 1, OAKD);
  for (x = 4; x < 22; x += 6) b.px(x, 22, OAKD);
  b.rect(2, 12, 20, 10, LM); b.rect(2, 12, 20, 1, LMD);
  b.rect(2, 12, 2, 10, OAK); b.rect(20, 12, 2, 10, OAK); b.rect(2, 12, 1, 10, OAKL);
  b.rect(10, 12, 2, 10, OAK); b.rect(10, 12, 1, 10, OAKL);
  b.rect(2, 12, 20, 1, OAK); b.rect(2, 21, 20, 1, OAK);
  b.line(4, 20, 9, 14, OAK, 1); b.line(12, 20, 12, 14, LMD, 1);
  for (x = 5; x < 9; x += 2) b.px(x, 18, LMD);
  b.rect(13, 14, 7, 1, OAKD); b.rect(14, 15, 5, 7, OAKD); b.rect(15, 16, 3, 6, OAKL); b.rect(16, 16, 1, 6, OAKD);
  b.px(17, 19, IRL); b.line(15, 17, 17, 17, IRD, 1); b.line(15, 20, 17, 20, IRD, 1);
  // the porch plank and the ladder leaning on it
  b.rect(13, 22, 9, 1, OAKH);
  b.line(23, 29, 20, 22, OAK, 1); b.line(25, 29, 22, 22, OAKL, 1);
  for (i = 0; i < 4; i++) b.line(22 - Math.round(i * 0.8) + 0, 28 - i * 2, 24 - Math.round(i * 0.8), 28 - i * 2, OAKH, 1);
  b.px(25, 29, OAKD); b.px(23, 29, OAKD);
  // the deep thatch
  for (r = 0; r < 12; r++) {
    hw = Math.min(13, 1.5 + r * 1.1);
    for (x = Math.ceil(13 - hw); x < 13 + hw; x++) {
      b.px(x, r, ((r >> 1) % 2) ? THAT[(x + r) % 3] : (x < 13 - hw * 0.4 ? STRAWL : (x > 13 + hw * 0.4 ? THAT[1] : THAT[2])));
    }
    if (r % 2 == 1) for (x = Math.ceil(13 - hw) + 1; x < 13 + hw; x += 4) b.px(x, r, THATD);
  }
  b.rect(0, 11, 26, 1, THATD); b.rect(2, 12, 22, 1, LMS);
  b.px(12, 0, OAKL); b.px(14, 0, OAKL); b.px(13, 1, OAKD); b.px(12, 1, OAKL); b.px(14, 1, OAKL);
  b.px(10, 4, STRAWL); b.px(16, 7, STRAWL); b.px(8, 8, STRAWD);
}
// The site, 24x12: three staddle stones set, two floor beams laid across them, a stack of planks and a bundle of thatch.
function granarysite(b) {
  var i, x, st = [2, 9, 16];
  for (i = 0; i < st.length; i++) { x = st[i]; b.rect(x + 1, 8, 3, 3, SL[1]); b.rect(x, 7, 5, 1, SLL); b.rect(x, 8, 5, 1, SLM); b.rect(x + 3, 9, 1, 2, SLD); }
  b.rect(0, 5, 22, 1, OAKH); b.rect(0, 6, 22, 1, OAKL); b.rect(2, 3, 18, 1, OAKL); b.rect(2, 4, 18, 1, OAKD);
  b.rect(0, 11, 22, 1, SLD);
  b.rect(19, 7, 5, 1, OAKL); b.rect(19, 8, 5, 1, OAKD); b.rect(19, 9, 5, 1, OAKL); b.rect(19, 10, 5, 2, OAKD);
  b.ell(6, 2, 3, 1.6, STRAW); b.rect(4, 2, 5, 1, STRAWL); b.px(6, 1, STRAWD); b.px(7, 3, STRAWD);
}

// ---- the rampart (west page, replaces the Bronze town wall: page-local x 59..383, y 38..63) -------------
// A rampart of slate courses laced with oak, a palisade of pointed stakes bound with an iron strap, a
// squat stone pier at the forest's end, a slate-capped corner tower at the cave's flank, oak posts with
// iron caps and, at x 203..231, an iron-bound gate tower: limewashed lower stage, a boarded oak
// chamber that juts out over it, a hipped slate roof, and an open arch with a half-raised portcullis.
function shifted(b, ox, oy) {
  return {
    rect: function (x, y, w, h, c) { b.rect(x - ox, y - oy, w, h, c); },
    px: function (x, y, c) { b.px(x - ox, y - oy, c); },
    clear: function (x, y, w, h) {
      var i, j, X, Y;
      for (j = 0; j < h; j++) for (i = 0; i < w; i++) { X = x - ox + i; Y = y - oy + j; if (X >= 0 && Y >= 0 && X < b.w && Y < b.h) b.d[(Y * b.w + X) * 4 + 3] = 0; }
    }
  };
}
function slateroof(T, cx, top, h, hw, flat) { // a hipped slate roof: courses of scales, lit from the left
  var r, w, x;
  for (r = 0; r < h; r++) {
    w = Math.round(hw * (r + 1) / h);
    for (x = cx - w; x <= cx + w; x++) T.px(x, top + r, r % 2 == 0 ? (x < cx ? SL[2] : SL[0]) : (x < cx ? SL[0] : SLM));
    if (r % 2 == 1) for (x = cx - w + 1 + (r % 4 == 1 ? 0 : 2); x <= cx + w; x += 4) T.px(x, top + r, SLD);
  }
  T.rect(cx - hw - 1, top + h, hw * 2 + 3, 1, SLD);
  T.rect(cx - hw - 1, top + h - 1, hw * 2 + 3, 1, SLL);
}
function rampart(b) {
  var T = shifted(b, 59, 37), x, i, c, segs = [[59, 202], [232, 383]], pst = [75, 107, 139, 171, 249, 281, 313, 345];
  segs.forEach(function (s) {
    var w = s[1] - s[0] + 1, px;
    // the palisade on top: pointed oak stakes, alternate ones a little shorter, bound by an iron strap
    for (px = s[0]; px + 1 <= s[1]; px += 3) {
      T.rect(px, 50 + (((px - s[0]) / 3) % 2), 2, 3, OAK); T.px(px, 49 + (((px - s[0]) / 3) % 2), OAKL); T.rect(px, 50 + (((px - s[0]) / 3) % 2), 1, 3, OAKL);
    }
    T.rect(s[0], 52, w, 1, IRD); T.rect(s[0], 53, w, 1, IRM);
    // the body: slate courses laced with two oak beams
    blocks(T, s[0], 54, w, 10, SL, SLD);
    T.rect(s[0], 54, w, 1, LM); T.rect(s[0], 55, w, 1, LMD);
    T.rect(s[0], 58, w, 1, OAK); T.rect(s[0], 59, w, 1, OAKD);
    T.rect(s[0], 61, w, 1, OAKL); T.rect(s[0], 62, w, 1, OAK);
    for (px = s[0] + 2; px < s[1]; px += 12) { T.px(px, 58, OAKH); T.px(px + 6, 61, OAKH); }
    T.rect(s[0], 63, w, 1, SLD);
  });
  // oak posts with iron caps, standing out of the wall
  for (i = 0; i < pst.length; i++) {
    c = pst[i];
    T.rect(c - 1, 48, 4, 16, OAK); T.rect(c - 1, 48, 1, 16, OAKL); T.rect(c + 2, 48, 1, 16, OAKD);
    T.rect(c - 2, 46, 6, 2, IRD); T.rect(c - 2, 46, 6, 1, IRM); T.px(c, 45, IRM); T.px(c + 1, 45, IRD);
    T.rect(c - 2, 56, 6, 1, IRD); T.px(c - 1, 56, IRL); T.px(c + 2, 56, IRL);
    T.rect(c - 2, 63, 6, 1, SLD);
  }
  // the pier against the forest
  blocks(T, 59, 46, 8, 18, SL, SLD); T.rect(59, 46, 8, 1, LM); T.rect(59, 47, 8, 1, LMD);
  T.rect(59, 52, 8, 1, OAK); T.rect(59, 53, 8, 1, OAKD); T.rect(59, 58, 8, 1, OAK); T.rect(59, 59, 8, 1, OAKD);
  T.rect(59, 48, 1, 15, SLL); T.rect(65, 48, 2, 15, SLD);
  slateroof(T, 62, 41, 5, 3);
  T.px(62, 40, IRM); T.px(62, 39, IRD);
  // the corner tower against the cliff
  blocks(T, 372, 46, 12, 18, SL, SLD); T.rect(372, 46, 12, 1, LM); T.rect(372, 47, 12, 1, LMD);
  T.rect(372, 52, 12, 1, OAK); T.rect(372, 53, 12, 1, OAKD); T.rect(372, 58, 12, 1, OAK); T.rect(372, 59, 12, 1, OAKD);
  T.rect(372, 48, 2, 15, SLL); T.rect(380, 48, 4, 15, SLD);
  T.rect(376, 49, 2, 3, DARK); T.rect(375, 48, 4, 1, LMD);
  slateroof(T, 378, 40, 6, 5);
  T.px(378, 39, IRM); T.px(378, 38, IRD); T.rect(379, 38, 3, 1, RED); T.px(381, 39, REDD);
  // the gate tower
  blocks(T, 203, 53, 29, 11, SL, SLD);
  T.rect(203, 53, 29, 1, LM); T.rect(203, 54, 29, 1, LMD); T.rect(203, 63, 29, 1, SLD);
  T.rect(203, 58, 29, 1, OAK); T.rect(203, 59, 29, 1, OAKD);
  T.rect(203, 54, 2, 9, SLL); T.rect(229, 54, 3, 9, SLD);
  // limewashed upper stage laced with oak, a boarded gallery that juts out above it, a slate roof
  T.rect(204, 49, 27, 4, LM); T.rect(204, 49, 27, 1, LML); T.rect(204, 52, 27, 1, LMD);
  for (x = 204; x <= 228; x += 6) { T.rect(x, 49, 2, 4, OAK); T.rect(x, 49, 1, 4, OAKL); }
  T.rect(230, 49, 1, 4, OAKD); T.rect(206, 50, 3, 2, DARK); T.rect(227, 50, 3, 2, DARK);
  T.rect(202, 47, 31, 2, OAKL); T.rect(202, 47, 31, 1, OAKH); T.rect(202, 48, 31, 1, OAKD);
  for (x = 203; x < 232; x += 3) T.px(x, 48, OAK);
  T.rect(203, 45, 29, 2, OAK); T.rect(203, 45, 29, 1, OAKL);
  for (x = 204; x < 231; x += 3) T.px(x, 46, OAKD);
  T.px(209, 46, DARK); T.px(210, 46, DARK); T.rect(214, 46, 3, 1, DARK); T.rect(218, 46, 2, 1, DARK); T.rect(224, 46, 2, 1, DARK);
  slateroof(T, 217, 38, 6, 15);
  T.rect(217, 37, 1, 1, IRL); T.rect(218, 37, 4, 1, RED);
  // the open arch, framed in iron-banded oak; a portcullis half raised
  T.clear(212, 52, 11, 12);
  T.rect(209, 50, 17, 1, IRD); T.rect(209, 51, 17, 1, IRM);
  T.rect(210, 52, 2, 12, OAKL); T.rect(223, 52, 2, 12, OAK); T.rect(210, 52, 1, 12, OAKH);
  T.rect(210, 55, 2, 1, IRD); T.rect(223, 55, 2, 1, IRD); T.rect(210, 60, 2, 1, IRD); T.rect(223, 60, 2, 1, IRD);
  T.px(210, 55, IRL); T.px(223, 60, IRL); T.px(211, 60, IRL); T.px(224, 55, IRL);
  T.rect(212, 52, 2, 1, OAK); T.rect(221, 52, 2, 1, OAK); T.rect(212, 53, 1, 1, OAK); T.rect(222, 53, 1, 1, OAK);
  for (x = 213; x < 222; x += 2) { T.rect(x, 52, 1, 4, IRM); T.px(x, 55, IRL); }
  T.rect(210, 62, 2, 1, SLD); T.rect(223, 62, 2, 1, SLD);
}

// ---- the slag heap (camp page, cave yard, 17x9) -------------------------------------------------------
// A heap of dark glassy slag: black lumps with a blue-violet gloss, a few rust-brown crusts.
function slagheap(b) {
  var L = '#2a2d38', M = '#3d4352', H = '#7f8fb0', V = '#6d5a8f';
  b.ell(8.5, 6, 7.8, 3, L); b.ell(7.5, 4.6, 6, 3, M); b.ell(6.5, 3.4, 3.6, 2, '#4b5266');
  b.ell(3.5, 6.4, 2.4, 1.8, M); b.ell(13.5, 6.6, 2.4, 1.7, L);
  b.px(5, 2, H); b.px(6, 2, H); b.px(8, 4, V); b.px(9, 4, V); b.px(4, 5, H); b.px(11, 5, H); b.px(12, 6, V); b.px(3, 6, H);
  b.px(7, 6, RU); b.px(8, 6, RUD); b.px(10, 3, RU); b.px(2, 7, RUD); b.px(14, 7, RU);
  b.rect(0, 8, 17, 1, '#1d1f28');
  // a few black lumps that rolled away
  b.rect(15, 7, 2, 2, M); b.px(15, 7, H); b.rect(0, 7, 2, 2, L); b.px(0, 7, M);
}

// ---- the plough team (west page, 31x12) ----------------------------------------------------------------
// An ox in a yoke hauling a wooden plough that ends in an iron share, a few dark furrows behind.
function oxplough(b) {
  var BR = '#8a5a36', BRL = '#a8703f', BRD = '#5f3d24', x;
  b.rect(0, 10, 9, 2, EARTHD); b.rect(1, 9, 3, 1, EARTH); b.rect(5, 9, 3, 1, EARTH); b.px(2, 8, EARTH); b.px(6, 8, EARTHD);
  for (x = 1; x < 9; x += 3) b.px(x, 11, EARTH);
  // the plough: a beam, two handles, a coulter and the iron share
  b.line(9, 4, 15, 4, OAKL, 1); b.line(9, 5, 15, 5, OAK, 1);
  b.line(10, 5, 5, 10, OAK, 1); b.line(11, 5, 7, 10, OAKL, 1);
  b.line(7, 4, 2, 0, OAK, 1); b.line(8, 5, 4, 1, OAKL, 1); b.px(2, 0, OAKH); b.px(4, 1, OAKH);
  b.line(4, 6, 4, 8, OAKD, 1);
  b.rect(5, 10, 5, 2, IRM); b.px(5, 11, IRL); b.px(9, 10, IRL); b.px(10, 11, IRD); b.px(4, 12 - 1, IRD); b.rect(6, 10, 3, 1, IRL);
  // the ox
  b.rect(16, 3, 11, 5, BR); b.rect(16, 3, 11, 1, BRL); b.rect(16, 7, 11, 1, BRD);
  b.rect(15, 4, 1, 3, BRD); b.px(15, 3, BR); b.line(15, 4, 14, 8, BRD, 1);
  b.rect(26, 2, 4, 5, BR); b.rect(29, 4, 2, 3, BRL); b.px(30, 5, DARK); b.px(28, 3, DARK); b.rect(26, 2, 2, 1, BRL);
  b.px(26, 1, CLOTH); b.px(27, 0, CLOTH); b.px(29, 1, CLOTH); b.px(30, 0, CLOTH); b.px(28, 1, CLOTHD);
  b.rect(17, 8, 2, 4, BRD); b.rect(21, 8, 2, 4, BRD); b.rect(24, 8, 2, 4, BR); b.rect(28, 8, 1, 4, BR);
  b.px(17, 11, IRD); b.px(18, 11, IRD); b.px(21, 11, IRD); b.px(22, 11, IRD); b.px(24, 11, IRD); b.px(25, 11, IRD); b.px(28, 11, IRD);
  b.rect(16, 2, 11, 1, OAK); b.rect(23, 1, 5, 1, OAKL); b.px(23, 2, IRL); b.px(27, 1, IRM);
  b.px(20, 5, BRL); b.px(22, 6, BRL);
  b.line(15, 4, 12, 4, CORD, 1);
}

// ---- the shearing pen (west page, 28x12) ------------------------------------------------------------------
// A low hurdle pen, a sheep held on a stool half shorn (bare and pink behind, wool in front), a heap of
// fleece and a pair of iron shears leaning on the rail.
function shearpen(b) {
  var x, SH = '#e8d0bc', SHD = '#c9a794';
  for (x = 0; x < 28; x += 9) { b.rect(x, 2, 1, 9, OAK); b.px(x, 2, OAKL); }
  b.rect(0, 3, 28, 1, OAKL); b.rect(0, 6, 28, 1, OAK); b.rect(0, 10, 28, 1, OAKL);
  b.rect(0, 11, 28, 1, EARTHD);
  for (x = 2; x < 27; x += 3) b.px(x, 8, EARTH);
  // the sheep: the rear shorn, the front still in wool
  b.ell(12, 7, 4.6, 2.8, '#f6f6f0'); b.ell(14, 6.3, 3, 2, '#fbfbf5'); b.rect(8, 6, 4, 3, SH); b.rect(8, 8, 4, 1, SHD); b.px(9, 7, '#d9b8a0');
  b.ell(17.5, 6.5, 1.6, 1.8, '#4a4150'); b.px(18, 5, '#ffffff'); b.px(16, 4, '#4a4150'); b.px(19, 7, '#4a4150');
  b.rect(10, 9, 1, 2, '#4a4150'); b.rect(14, 9, 1, 2, '#4a4150'); b.rect(8, 8, 1, 3, '#4a4150');
  // the heap of fleece and a bundle tied up
  b.ell(4, 9, 3.2, 2, '#f6f6f0'); b.ell(4, 8, 2.4, 1.4, '#fbfbf5'); b.px(2, 9, '#d6d6cc'); b.px(5, 10, '#d6d6cc');
  b.ell(23.5, 8.5, 2.4, 2, '#e9e4d2'); b.px(23, 6, CORD); b.px(24, 6, CORD); b.px(22, 8, CLOTHD);
  // the shears: two iron blades and a bow, leaning on the near rail
  b.line(25, 10, 27, 5, IRL, 1); b.line(27, 10, 25, 5, IRM, 1); b.px(26, 10, IRD); b.px(25, 4, IRD); b.px(27, 4, IRD);
}

// ---- the coin tray (west page, 10x12) ------------------------------------------------------------------------
// A small trestle table beside the market, in the gap between the stalls (or the council ring, or the
// tally post: all end at x 55) and the weavers' row (from x 68), so it lies on none of them: a forged
// anvil with a die and a hammer and a tray heaped with silver coins.
function cointray(b) {
  // the trestle
  b.rect(0, 8, 10, 2, OAKL); b.rect(0, 8, 10, 1, OAKH); b.rect(0, 9, 10, 1, OAKD);
  b.rect(1, 10, 2, 2, OAK); b.rect(7, 10, 2, 2, OAK); b.rect(1, 10, 1, 2, OAKL); b.rect(3, 11, 4, 1, OAKD);
  // the anvil: a flat iron top, a narrow waist; a die and a hammer on it
  b.rect(0, 5, 5, 1, IRL); b.rect(0, 6, 5, 1, IRM); b.rect(1, 7, 3, 1, IRD); b.px(4, 6, IRD);
  b.rect(1, 3, 2, 2, IRH); b.px(1, 4, IRM); b.px(2, 4, IRD);
  b.line(3, 2, 4, 4, OAK, 1); b.rect(3, 1, 2, 1, IRD); b.px(3, 1, IRL);
  // the tray: a shallow oak box and a heap of silver coins
  b.rect(5, 6, 5, 2, OAK); b.rect(5, 6, 5, 1, OAKH); b.rect(5, 7, 5, 1, OAKD);
  b.rect(6, 4, 3, 2, SILVER); b.px(6, 4, SILVERD); b.px(8, 5, SILVERD); b.px(7, 3, SILVER); b.px(7, 2, SILVERD);
  b.px(9, 5, SILVER); b.px(7, 5, SILVERD);
}

// ---- the writing post (west page, 10x18; the tally post's place at the market's left edge) -------------------------
// A post carrying a slate tablet scored with rows of letters. It stands beside the stalls or the council
// ring (the tally post's bench and cords are gone), its foot behind the cart's load.
function glyphs(b, x0, y0, w, rows) {
  var r, x, k;
  for (r = 0; r < rows; r++) {
    for (x = 0; x < w; x += 2) {
      k = (x * 5 + r * 3) % 4;
      b.px(x0 + x, y0 + r * 2, LM);
      if (k == 0) b.px(x0 + x, y0 + r * 2 + 1, LMD);
      if (k == 2) b.px(x0 + x + 1, y0 + r * 2, LMD);
    }
  }
}
function writingpost(b) {
  // the post on its foot stones, the tablet at its head: a slate cap, an oak frame round a slate face
  // scored with rows of letters, iron bolts at the corners
  b.rect(4, 10, 2, 8, OAK); b.rect(4, 10, 1, 8, OAKL);
  b.rect(2, 16, 6, 2, SLM); b.rect(2, 16, 6, 1, SLL); b.px(7, 17, SLD); b.px(4, 17, SLD);
  b.rect(0, 0, 10, 2, SL[1]); b.rect(0, 0, 10, 1, SLL); b.rect(0, 1, 10, 1, SLD);
  b.rect(0, 2, 10, 8, OAKD); b.rect(0, 2, 1, 8, OAKL); b.rect(9, 2, 1, 8, OAK);
  b.rect(1, 3, 8, 6, SLD); b.rect(1, 3, 8, 1, SLM);
  glyphs(b, 2, 4, 6, 3);
  b.px(0, 2, IRL); b.px(9, 2, IRM); b.px(0, 9, IRM); b.px(9, 9, IRM);
  b.rect(0, 10, 10, 1, OAK);
}

// ---- the standing stone (camp page, near bank, 10x12) ---------------------------------------------------------------
// A slate stone, narrower at the top, with a spiral, a row of cut letters and a zig-zag, a few small
// stones heaped round its foot.
function standingstone(b) {
  var y, x, hw, c;
  for (y = 0; y < 10; y++) {
    hw = 2.6 - (y < 2 ? (2 - y) * 0.7 : 0) + (y > 6 ? (y - 6) * 0.3 : 0);
    for (x = Math.ceil(4.5 - hw); x <= Math.floor(4.5 + hw); x++) {
      c = x < 4.5 - hw * 0.35 ? SLL : (x > 4.5 + hw * 0.35 ? SLD : SL[1]);
      b.px(x, y, c);
    }
  }
  b.px(4, 0, SL[2]); b.px(5, 0, SL[1]);
  // carving: a spiral, letters, a zig-zag
  b.px(4, 2, LMD); b.px(5, 2, LMD); b.px(5, 3, LMD); b.px(3, 3, LMD); b.px(4, 4, LMD); b.px(4, 3, SLM);
  b.px(3, 6, LM); b.px(5, 6, LM); b.px(4, 6, LMD); b.px(6, 6, LM);
  b.px(3, 8, LMD); b.px(4, 7, LMD); b.px(5, 8, LMD); b.px(6, 7, LMD);
  b.ell(4.5, 10, 4.2, 1.5, ROCK); b.ell(3, 9.8, 1.8, 1.1, ROCKL); b.ell(7, 10.3, 1.8, 1, ROCKD); b.px(8, 10, ROCK);
  b.rect(0, 11, 10, 1, '#5a6a46'); b.px(1, 10, '#8fb843'); b.px(9, 9, '#8fb843');
}

// ---- the deep ship (east page, 24x20) -------------------------------------------------------------------------------
// A deep-keeled ship with a high carved prow, a row of round shields along the rail and one square sail of
// checked wool, to ride the open sea where the trading ship was.
function deepship(b) {
  var x, y, i, hw, sh = [RED, IRL, '#c9a548', IRL, RED, IRL];
  // the sail and its yard and mast
  b.rect(11, 1, 1, 12, OAKD); b.rect(4, 1, 16, 1, OAKL);
  for (y = 2; y < 10; y++) for (x = 5; x < 19; x++) b.px(x, y, ((x + 1) % 4 < 2) ? CLOTH : '#8c9bb3');
  for (x = 5; x < 19; x++) { b.px(x, 5, '#566a8a'); b.px(x, 6, (x % 2) ? '#566a8a' : '#b8903f'); }
  b.rect(17, 2, 2, 8, CLOTHD); b.rect(17, 5, 2, 2, '#566a8a');
  b.rect(11, 2, 1, 8, OAK); b.rect(4, 10, 16, 1, OAKL);
  b.px(3, 1, IRM); b.px(20, 1, IRM);
  // the hull: a deep curved shape, prow raised at the right, stern raised at the left
  for (y = 11; y < 18; y++) {
    hw = [11.6, 11.8, 11, 9.8, 8, 5.8, 3.4][y - 11];
    for (x = 0; x < 24; x++) if (Math.abs(x - 11.5) <= hw) b.px(x, y, ['#7d5634', '#6a4528', '#7d5634', '#5b3d27', '#6a4528', '#4a3020', '#3e281a'][y - 11]);
  }
  b.rect(0, 9, 2, 3, OAKL); b.px(0, 9, OAKH); b.px(1, 10, OAK); b.rect(22, 7, 2, 5, OAKL); b.px(23, 6, OAKH); b.px(22, 6, OAK); b.px(23, 5, IRM); b.px(22, 5, IRL);
  b.px(21, 8, IRD); b.px(21, 9, IRL);
  b.rect(2, 11, 20, 1, IRM);
  for (i = 0; i < 6; i++) { x = 4 + i * 3; b.rect(x, 12, 2, 2, sh[i]); b.px(x, 12, i % 2 ? IRH : (i == 2 ? '#f0d878' : '#e8776f')); }
  b.rect(3, 15, 18, 1, '#8a5a36'); for (x = 5; x < 20; x += 4) b.px(x, 15, IRL);
  b.rect(8, 17, 8, 1, '#2f1f14');
}

// ---- the beacon (east page, 14x26) ------------------------------------------------------------------------------------
// An iron cage of fire on a cairn of slate stones heaped up on the headland, a thread of smoke above. The flame
// has four frames (the game swaps them like the camp fire's): east_beacon is frame 0, east_beacon_1..3 the others.
var BEACON_FLAME = [
  { top: 3, h: 9, cx: 7, ct: 6, ch: 6, tip: [[7, 2, '#f59e2b'], [7, 1, '#e5732b']], sp: [[5, 6, '#f59e2b'], [9, 7, '#e5732b'], [4, 8, '#e5732b']] },
  { top: 2, h: 10, cx: 7, ct: 5, ch: 7, tip: [[7, 1, '#f59e2b'], [7, 0, '#e5732b']], sp: [[5, 5, '#f59e2b'], [10, 6, '#e5732b'], [3, 8, '#e5732b']] },
  { top: 3, h: 9, cx: 8, ct: 6, ch: 6, tip: [[8, 2, '#f59e2b'], [9, 1, '#e5732b']], sp: [[5, 7, '#f59e2b'], [9, 6, '#e5732b'], [4, 9, '#e5732b']] },
  { top: 4, h: 8, cx: 7, ct: 6, ch: 6, tip: [[7, 3, '#f59e2b'], [6, 2, '#e5732b']], sp: [[5, 6, '#f59e2b'], [9, 8, '#e5732b'], [4, 7, '#e5732b']] }
];
function beacon(b, f) {
  var y, hw, x, c, i, fl = BEACON_FLAME[f || 0];
  // flames, tall and orange, a yellow core
  b.tri(fl.cx, fl.top, fl.h, 3, '#f59e2b', '#e5732b'); b.tri(7, fl.ct, fl.ch, 2, GLOWL, '#ffe27a');
  for (i = 0; i < fl.tip.length; i++) b.px(fl.tip[i][0], fl.tip[i][1], fl.tip[i][2]);
  for (i = 0; i < fl.sp.length; i++) b.px(fl.sp[i][0], fl.sp[i][1], fl.sp[i][2]);
  b.px(8, 0, SMOKE); b.px(9, 0, SMOKEL);
  // the iron basket: a bowl on a post with bars
  b.rect(3, 12, 9, 1, IRM); b.rect(4, 13, 7, 1, IRD); b.rect(5, 14, 5, 1, IRD); b.px(3, 11, IRL); b.px(11, 11, IRL);
  b.px(4, 11, IRD); b.px(10, 11, IRD); b.px(5, 12, EMBER); b.px(9, 12, EMBER);
  b.rect(7, 15, 1, 3, IRD);
  // the cairn: slate stones in rough courses, wider at the foot
  for (y = 16; y < 25; y++) {
    hw = 2 + (y - 16) * 0.65;
    for (x = Math.ceil(7 - hw); x <= Math.floor(7 + hw); x++) {
      c = (y % 3 == 0 || (x + y) % 5 == 0) ? SLD : (x < 7 - hw * 0.3 ? SLL : (x > 7 + hw * 0.4 ? SLM : SL[(x + y) % 3]));
      b.px(x, y, c);
    }
  }
  b.rect(1, 25, 13, 1, SLD);
}

// ---- the beacon's light (east page, full 384x80) ------------------------------------------------------------------
// The beacon burns all night, so its own light is a layer: dithered warm bands round the flame, brightest
// at its heart (no hard-edged core: it reads as a glass box). Semi-transparent orange; the game draws it additively (the night's tint would dim the
// flame itself) and fades it in as it darkens, only while the beacon is lit. Not a prop: it has no name.
function beaconglow() {
  var g = new Buf(W, H), gx, gy, dx, dy, dd, v, a, bi;
  var bands = [[0.4, 150], [0.65, 100], [0.85, 56], [1.0, 26]];
  for (gy = 0; gy < H; gy++) for (gx = 0; gx < W; gx++) {
    dx = (gx - 232) / 30; dy = (gy - 58) / 22; dd = Math.sqrt(dx * dx + dy * dy); v = 0;
    for (bi = 0; bi < bands.length; bi++) {
      if (dd < bands[bi][0]) { v = bands[bi][1]; if (bi + 1 < bands.length && bands[bi][0] - dd < 0.07 && ((gx + gy) & 1) == 0) v = bands[bi + 1][1]; break; }
    }
    a = (gy * W + gx) * 4;
    if (v > 0) { g.d[a] = 255; g.d[a + 1] = 154; g.d[a + 2] = 60; g.d[a + 3] = v; }
  }
  return g;
}

// ---- the timber-and-daub houses (the Hut's camp slot, 34x24; the village roofs, 26x19) -------------------------------
// The Bronze mud-brick houses redrawn in place (same footprint, same names): an oak frame filled with
// limewashed daub on a slate plinth, a deep thatched roof with an overhang, a plank door with iron
// straps, shuttered windows. The camp's house also has a slate chimney.
function thatch(b, cx, top, rows, hw0, grow, maxhw) {
  var r, x, hw;
  for (r = 0; r < rows; r++) {
    hw = Math.min(maxhw, hw0 + r * grow);
    for (x = Math.ceil(cx - hw); x < cx + hw; x++) {
      b.px(x, top + r, ((r >> 1) % 2) ? THAT[(x + r) % 3] : (x < cx - hw * 0.4 ? STRAWL : (x > cx + hw * 0.4 ? THAT[1] : THAT[2])));
    }
    if (r % 2 == 1) for (x = Math.ceil(cx - hw) + 1; x < cx + hw; x += 4) b.px(x, top + r, THATD);
  }
}
function daubwall(b, x0, y0, w, h) { // oak frame, limewashed infill, braces both ways
  var x;
  b.rect(x0, y0, w, h, LM); b.rect(x0, y0, w, 1, OAK); b.rect(x0, y0 + h - 1, w, 1, OAK);
  b.rect(x0, y0, 2, h, OAK); b.rect(x0 + w - 2, y0, 2, h, OAK); b.rect(x0, y0, 1, h, OAKL);
  b.line(x0 + 2, y0 + h - 2, x0 + 7, y0 + 1, OAK, 1); b.line(x0 + w - 3, y0 + h - 2, x0 + w - 8, y0 + 1, OAK, 1);
  for (x = x0 + 9; x < x0 + w - 9; x += 4) b.px(x, y0 + 2, LMD);
}
function ironhouse(b) {
  var x;
  thatch(b, 17, 0, 14, 6, 1.0, 17);
  b.rect(0, 13, 34, 1, THATD); b.rect(2, 14, 30, 1, LMS);
  daubwall(b, 3, 14, 28, 10);
  b.rect(3, 23, 28, 1, SLM); b.rect(3, 23, 28, 1, SLD);
  b.rect(13, 16, 8, 8, OAKD); b.rect(14, 17, 6, 7, OAKL); b.rect(16, 17, 1, 7, OAKD); b.rect(13, 16, 8, 1, OAK);
  b.rect(14, 19, 6, 1, IRD); b.rect(14, 22, 6, 1, IRD); b.px(15, 19, IRL); b.px(18, 22, IRL); b.px(19, 21, IRM);
  b.rect(6, 17, 5, 4, DARK); b.rect(5, 17, 1, 4, OAKL); b.rect(11, 17, 1, 4, OAK); b.rect(6, 21, 5, 1, LMD);
  b.rect(23, 17, 5, 4, DARK); b.rect(22, 17, 1, 4, OAKL); b.rect(28, 17, 1, 4, OAK); b.rect(23, 21, 5, 1, LMD);
  b.rect(25, 17, 1, 4, OAK);
  b.rect(24, 1, 4, 8, SLM); b.rect(24, 1, 1, 8, SLL); b.rect(27, 1, 1, 8, SLD); b.rect(23, 0, 6, 2, SLD); b.rect(23, 0, 6, 1, SLL);
  b.rect(25, 3, 2, 1, SLD); b.ell(26, -0.5, 1.6, 1, SMOKE);
  b.px(10, 4, STRAWL); b.px(14, 9, STRAWL); b.px(6, 11, STRAWD);
}
function ironhousesite(b) {
  b.rect(0, 11, 24, 1, SLD);
  b.rect(2, 9, 20, 2, SLM); b.rect(2, 9, 20, 1, SLL);
  b.rect(2, 2, 2, 8, OAK); b.rect(20, 2, 2, 8, OAK); b.rect(11, 1, 2, 9, OAK); b.rect(2, 2, 20, 1, OAKL);
  b.line(4, 9, 10, 3, OAK, 1); b.rect(4, 6, 6, 3, LM); b.px(5, 7, LMD);
  b.rect(14, 5, 6, 4, LM); b.px(16, 6, LMD);
  b.ell(5, 9.5, 3, 1.5, STRAW); b.rect(3, 9, 5, 1, STRAWL);
  b.px(1, 4, OAKH); b.px(21, 3, OAKH);
}
function smallironhouse(b) {
  thatch(b, 13, 0, 10, 4, 0.95, 13);
  b.rect(0, 9, 26, 1, THATD); b.rect(2, 10, 22, 1, LMS);
  daubwall(b, 3, 10, 20, 9);
  b.rect(3, 18, 20, 1, SLD);
  b.rect(9, 12, 7, 7, OAKD); b.rect(10, 13, 5, 6, OAKL); b.rect(12, 13, 1, 6, OAKD); b.rect(9, 12, 7, 1, OAK);
  b.rect(10, 15, 5, 1, IRD); b.px(11, 15, IRL); b.px(14, 17, IRM);
  b.rect(17, 13, 4, 3, DARK); b.rect(16, 13, 1, 3, OAKL); b.rect(21, 13, 1, 3, OAK);
  b.rect(5, 13, 3, 3, DARK); b.rect(4, 13, 1, 3, OAKL); b.rect(8, 13, 1, 3, OAK);
  b.px(8, 3, STRAWL); b.px(15, 5, STRAWD);
}

// ---- the iron-bound gate tower (camp slot of the Lookout, 28x31) ------------------------------------------------------
// The Bronze mud-brick tower redrawn to match the rampart's gate: a slate base laced with oak and an
// iron-bound gate, a limewashed stage, a boarded oak gallery with slits and a hipped slate roof with a
// red pennant.
function irontower(b) {
  var x;
  blocks(b, 1, 20, 26, 11, SL, SLD);
  b.rect(1, 20, 26, 1, LM); b.rect(1, 21, 26, 1, LMD); b.rect(1, 25, 26, 1, OAK); b.rect(1, 26, 26, 1, OAKD);
  b.rect(1, 21, 2, 9, SLL); b.rect(24, 21, 3, 9, SLD);
  b.rect(1, 29, 26, 2, SLD);
  // the iron-bound gate
  b.rect(8, 22, 12, 9, IRD); b.rect(9, 23, 10, 8, OAKL); b.rect(13, 23, 2, 8, OAKD);
  b.rect(9, 25, 10, 1, IRD); b.rect(9, 28, 10, 1, IRD); b.px(10, 25, IRL); b.px(17, 28, IRL); b.px(10, 28, IRM); b.px(17, 25, IRM);
  b.rect(8, 22, 12, 1, IRM); b.px(11, 24, IRL); b.px(16, 24, IRL); b.px(12, 27, IRL); b.px(15, 27, IRL);
  b.rect(7, 22, 1, 9, SLM); b.rect(20, 22, 1, 9, SLM);
  // the limewashed stage, with a window each side
  b.rect(2, 13, 24, 7, LM); b.rect(2, 13, 24, 1, LML); b.rect(2, 19, 24, 1, LMD);
  for (x = 2; x <= 22; x += 7) { b.rect(x, 13, 2, 7, OAK); b.rect(x, 13, 1, 7, OAKL); }
  b.rect(24, 13, 2, 7, OAKD); b.rect(5, 15, 3, 3, DARK); b.rect(20, 15, 3, 3, DARK); b.rect(4, 15, 1, 3, OAKL); b.rect(8, 15, 1, 3, OAK);
  b.rect(13, 15, 2, 4, DARK); b.rect(12, 14, 4, 1, OAKL);
  // the gallery and its slits
  b.rect(0, 11, 28, 2, OAKL); b.rect(0, 11, 28, 1, OAKH); b.rect(0, 12, 28, 1, OAKD);
  for (x = 1; x < 28; x += 3) b.px(x, 12, OAK);
  b.rect(2, 8, 24, 3, OAK); b.rect(2, 8, 24, 1, OAKL);
  for (x = 4; x < 25; x += 3) b.px(x, 9, OAKD);
  b.px(7, 10, DARK); b.px(8, 10, DARK); b.rect(13, 9, 2, 2, DARK); b.px(19, 10, DARK); b.px(20, 10, DARK);
  slateroof(b, 14, 2, 6, 12);
  b.rect(14, 1, 1, 1, IRL); b.rect(15, 0, 6, 1, RED); b.rect(15, 1, 4, 1, RED); b.px(18, 2, REDD);
  b.rect(14, 0, 1, 1, IRM);
}
function irontowersite(b) {
  blocks(b, 2, 7, 15, 4, SL, SLD); b.rect(2, 7, 15, 1, LM);
  blocks(b, 2, 5, 5, 2, SL, SLD); b.rect(2, 5, 5, 1, LM);
  blocks(b, 12, 6, 5, 1, SL, SLD);
  b.rect(8, 3, 1, 8, OAK); b.rect(12, 3, 1, 8, OAK); b.rect(8, 3, 5, 1, OAKL); b.rect(9, 7, 3, 4, DARK);
  b.rect(1, 1, 1, 10, OAK); b.px(1, 1, OAKH); b.line(1, 4, 3, 4, CORD, 1);
  b.rect(18, 2, 1, 9, OAK); b.px(18, 2, OAKH); b.rect(16, 5, 3, 1, OAKL);
  blocks(b, 14, 8, 4, 3, SL, SLD); b.rect(14, 8, 4, 1, LM);
  b.px(19, 1, EMBER);
}

var layers = {};
layers.building_hut = layerOf([obj(34, 24, 268, 71, ironhouse, { sh: 14 })]);
layers.site_hut = layerOf([obj(24, 12, 268, 71, ironhousesite, { sh: 9 })]);
layers.west_roof_a = layerOf([obj(26, 19, 172, 72, smallironhouse, { sh: 11 })]);
layers.west_roof_b = layerOf([obj(26, 19, 148, 71, smallironhouse, { sh: 11, flip: 1 })]);
layers.building_lookout = layerOf([obj(28, 31, 300, 68, irontower, { sh: 0, z: 66 })]);
layers.site_lookout = layerOf([obj(20, 11, 300, 68, irontowersite, { sh: 0, z: 66 })]);
layers.building_bloomery = layerOf([obj(22, 34, 85, 67, bloomery, { sh: 11 })]);
layers.site_bloomery = layerOf([obj(24, 12, 85, 67, bloomerysite, { sh: 11 })]);
layers.building_granary = layerOf([obj(26, 30, 234, 67, granary, { sh: 0 })]);
layers.site_granary = layerOf([obj(24, 12, 234, 67, granarysite, { sh: 0 })]);
layers.rampart = layerOf([obj(325, 27, 221, 64, rampart, { sh: 0 })]);
layers.slag_heap = layerOf([obj(17, 9, 195, 77, slagheap, { sh: 0 })]);
layers.shearing_pen = layerOf([obj(28, 12, 267, 78, shearpen, { sh: 0 })]);
layers.coin_tray = layerOf([obj(10, 12, 62, 67, cointray, { sh: 0 })]);
layers.writing_post = layerOf([obj(10, 18, 6, 65, writingpost, { sh: 0 })]);
layers.standing_stone = layerOf([obj(10, 12, 282, 79, standingstone, { sh: 0 })]);
layers.east_deep_ship = layerOf([obj(24, 18, 305, 62, deepship, { sh: 0 })]);
layers.east_beacon = layerOf([obj(14, 26, 232, 77, beacon, { sh: 0 })]);
for (var bf = 1; bf < BEACON_FLAME.length; bf++) layers['east_beacon_' + bf] = layerOf([obj(14, 26, 232, 77, (function (n) { return function (b) { beacon(b, n); }; })(bf), { sh: 0 })]);
layers.east_beacon_glow = beaconglow();

// previews: the camp pieces on a plain meadow, the west ones and the east one apart
var groups = [
  ['iron_camp', ['building_bloomery', 'site_bloomery', 'building_granary', 'site_granary', 'slag_heap', 'standing_stone', 'building_hut', 'site_hut', 'building_lookout', 'site_lookout']],
  ['iron_west', ['rampart', 'shearing_pen', 'coin_tray', 'writing_post', 'west_roof_a', 'west_roof_b']],
  ['iron_east', ['east_deep_ship', 'east_beacon'], 'sea']
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
console.log('iron camp done, ' + count + ' game layers');
