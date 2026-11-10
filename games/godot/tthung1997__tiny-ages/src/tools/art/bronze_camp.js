// @open art/reference/bronze_camp.png
// @canvas 384x80
// Bronze Age world pieces (docs: ages "Bronze Age: design proposal", V10): what the camp gains, or
// upgrades in place, once metal, trade and walls arrive. Cave and Settled art is kept; a slot the
// Bronze Age redraws uses the same layer name in its own folder (WorldLayout.piece_path). Game
// assets (game/assets/world/bronze/), each a full 384x80 transparent PNG, every piece already at
// its final position (page-local x; world x = local - 384 on the west page, + 384 on the east):
//   camp page   building_smithy, site_smithy, building_trading_post, site_trading_post,
//               building_hut, site_hut (a mud-brick house), boat_dugout (a planked boat),
//               boat_raft (a reed ship under a sail)
//   west page   west_roof_a, west_roof_b (small mud-brick houses), potters_yard (the kiln, the
//               pots and the clay in one tidy piece), weavers_row (loom, cloth line, flax) with
//               weavers_row_dyed (just the dyed cloth, exactly over the line), town_wall
//   east page   east_sail (a trading ship on the horizon of the open sea)
// Later additions (trade, the quay, the road, the lookout's gate tower):
//   camp page   road_camp (a flat packed-earth backdrop strip in front of the trading post and smithy),
//               building_quay / site_quay (a timber pier into the river), quay_boats (a planked boat
//               and a reed boat tied up beside it; replaces the free-floating boats),
//               building_lookout / site_lookout (the Lookout redrawn as a mud-brick gate tower),
//               crossing_planks (a plank bridge on the Cave crossing's span, x 302..476 in world x)
//   west page   market_stalls (two striped stalls), cart, donkeys (a pack pair)
//   east page   east_crossing_planks (the rest of the plank bridge; one drawing, cut at the seam)
// Pieces named like a Settled one replace it; slots are mirrored in game/scripts/view/world_layout.gd
// and scene_props.gd. Previews: art/reference/bronze_camp.png, bronze_west.png, bronze_east.png.
seed = 61;
var W = 384, H = 80, G = 56;
var GAME = DIR + 'game/assets/world/bronze/';
var IMG = SPR.layer(0).cel(0).image;

// o.raw: no outline, drawn at the sprite's own place (an overlay that sits inside another piece's
// outline, like the dyed cloth over the undyed line)
function obj(w, h, cx, foot, fn, o) { o = o || {}; return { w: w, h: h, x: cx - Math.floor(w / 2), y: foot - h, fn: fn, flip: o.flip, sh: o.sh, raw: o.raw, fy: o.z || foot, foot: foot, cx: cx }; }
function drawObj(buf, ob) { // shadow, then the outlined sprite
  if (ob.sh) buf.ell(ob.cx, ob.foot, ob.sh, 1.5, '#5f8236');
  var tb = new Buf(ob.w, ob.h); ob.fn(tb); if (ob.flip) tb = mirror(tb);
  if (ob.raw) blit(buf, tb, ob.x, ob.y); else blit(buf, outlined(tb, OUT), ob.x - 1, ob.y - 1);
}
function layerOf(list) { var b = new Buf(W, H); list.sort(function (p, q) { return p.fy - q.fy; }); for (var k = 0; k < list.length; k++) drawObj(b, list[k]); return b; }

// mud-brick, metal, dark timber, a little patina
var MB = ['#d9b47c', '#cfa86f', '#e2be88'], MBL = '#ecd2a0', MBD = '#b88f5c', MBM = '#a07848', PLAS = '#e6d2a8';
var TIM = '#6a4529', TIMD = '#4a2f1d', TIML = '#8a5a36';
var CU = '#d9782f', CUL = '#f2a65a', CUD = '#a24f22', CUH = '#ffd27a', PAT = '#4fae8f', PATD = '#2f7e68';
var DARK = '#2a2433', GLOW = '#f59e2b', GLOWL = '#ffd86a', EMBER = '#e0614a', SMOKE = '#cfd4da', SMOKEL = '#e6e9ed';
var CLAY = '#c27a52', CLAYD = '#9a5a3a', CLAYL = '#d99466', CB = ['#c27a52', '#b86f48', '#cc8458'];
var POT = '#c96a42', POTL = '#e08a5c', POTD = '#8a3a22';
var CLOTH = '#efe6cf', CLOTHD = '#cdc0a0', RED = '#c0504a', REDD = '#8f3a2d', CORD = '#f0e4c0';
var WATER = '#4f93c4', WATERL = '#8cc8e8', STRAW = '#d9b858', STRAWL = '#ebd07a', STRAWD = '#b8923f';

// Courses of mud-brick, 3 rows each (two of brick, one of mortar), a brick 5 wide with a joint,
// every other course shifted half a brick; the tone of a brick comes from its place.
function bricks(b, x, y, w, h, pal) {
  var r, xx, yy, x0, x1, tone, bh;
  b.rect(x, y, w, h, MBM);
  for (r = 0; y + r * 3 < y + h; r++) {
    yy = y + r * 3; bh = Math.min(2, y + h - yy);
    for (xx = x - (r % 2) * 3; xx < x + w; xx += 6) {
      tone = (xx * 7 + r * 13 + ((xx * r) % 5)) % 3; if (tone < 0) tone += 3;
      x0 = Math.max(xx, x); x1 = Math.min(xx + 5, x + w);
      if (x1 > x0) b.rect(x0, yy, x1 - x0, bh, pal[tone]);
    }
  }
}

// ---- the Smithy (camp slot, 34x24) ----------------------------------------------------------------
// A low mud-brick workshop open at the front, a squat clay furnace with a chimney and a glowing
// mouth, a stone anvil in front, and ingots stacked under a bronze-red sign.
function smithy(b) {
  var x;
  bricks(b, 9, 10, 15, 14, MB);
  b.rect(7, 7, 19, 1, MBL); b.rect(7, 8, 19, 2, MB[0]); b.rect(7, 10, 19, 1, MBM);
  for (x = 10; x < 24; x += 5) { b.rect(x, 11, 2, 2, TIMD); b.px(x, 11, TIM); }
  b.rect(11, 13, 11, 10, DARK); b.rect(12, 12, 9, 1, DARK);
  b.rect(10, 12, 1, 12, TIM); b.rect(22, 12, 1, 12, TIM); b.rect(10, 11, 13, 1, TIM);
  b.px(19, 20, EMBER); b.px(20, 20, GLOW); b.px(20, 21, EMBER); // a spent coal at the back
  b.px(13, 15, ROCKL); b.px(13, 16, ROCK); b.px(14, 17, ROCK); // tongs on a hook
  b.rect(9, 23, 15, 1, MBD);
  // the furnace and its chimney
  b.rect(24, 15, 10, 9, CLAY);
  b.ell(28.5, 15.5, 5, 3.5, CLAY); b.rect(24, 16, 1, 8, CLAYL); b.rect(33, 16, 1, 8, CLAYD);
  b.rect(24, 23, 10, 1, CLAYD);
  bricks(b, 27, 4, 4, 9, CB); b.rect(26, 3, 6, 2, CLAYD); b.rect(26, 3, 6, 1, CLAYL);
  b.ell(29, 1.5, 2.2, 1.4, SMOKE);
  b.ell(29, 20, 3, 2.6, DARK); b.rect(26, 20, 6, 4, DARK);
  b.rect(27, 21, 4, 3, EMBER); b.rect(28, 22, 2, 2, GLOW); b.px(28, 23, GLOWL); b.px(29, 23, GLOWL);
  // the anvil stone, a lump of bronze on it
  b.rect(12, 20, 9, 1, ROCKL); b.rect(14, 21, 5, 2, ROCK); b.rect(13, 23, 7, 1, ROCKD);
  b.px(11, 20, ROCK); b.px(21, 20, ROCK);
  b.rect(15, 19, 3, 1, CU); b.px(15, 19, CUL);
  // ingots stacked under a bronze-red sign
  b.rect(1, 8, 1, 16, TIM); b.rect(0, 8, 8, 1, TIM);
  b.rect(2, 9, 5, 6, '#b8573a'); b.rect(2, 14, 5, 1, REDD); b.rect(3, 10, 3, 2, CUL); b.rect(3, 11, 3, 1, CU);
  b.rect(2, 22, 3, 2, CU); b.rect(5, 22, 3, 2, CU); b.rect(3, 20, 4, 2, CU);
  b.rect(2, 22, 3, 1, CUL); b.rect(5, 22, 3, 1, CUL); b.rect(3, 20, 4, 1, CUH);
  b.px(4, 23, CUD); b.px(7, 23, CUD); b.px(6, 21, CUD);
}
// The site, 24x12: a ring of bricks half laid and the rest stacked beside it.
function smithsite(b) {
  b.ell(11, 7.5, 9, 3.2, '#8a6a46');
  bricks(b, 3, 4, 9, 3, MB); b.rect(3, 4, 9, 1, MBL);
  bricks(b, 1, 5, 3, 5, MB); b.rect(1, 5, 3, 1, MBL);
  bricks(b, 1, 9, 9, 3, MB); b.rect(1, 9, 9, 1, MBL);
  b.rect(14, 8, 1, 4, TIM); b.rect(18, 7, 1, 5, TIM); b.px(14, 7, EMBER); b.px(18, 6, EMBER); b.line(14, 8, 18, 8, CORD, 1);
  bricks(b, 20, 6, 4, 6, MB); b.rect(20, 6, 4, 1, MBL);
}

// ---- the Trading Post (camp slot, 30x22) -----------------------------------------------------------
// An open timber stall under a striped awning of undyed and red cloth: crates, two pots and a
// balance hanging over the counter.
function tradingpost(b) {
  var x, r, x0, x1, c;
  b.rect(3, 9, 24, 7, '#4a3a30'); b.rect(3, 12, 24, 1, TIM); b.rect(3, 13, 24, 1, TIMD);
  b.px(5, 11, POT); b.px(7, 10, CUL); b.px(10, 10, PAT); b.px(11, 10, PATD); b.px(20, 11, POTL); b.px(23, 10, CLOTH);
  b.rect(1, 3, 2, 19, TIM); b.rect(27, 3, 2, 19, TIM); b.rect(1, 3, 1, 19, TIML); b.rect(27, 3, 1, 19, TIML);
  b.rect(3, 16, 24, 2, TIML); b.rect(3, 16, 24, 1, '#a6703f'); b.rect(3, 18, 24, 4, TIM);
  for (x = 5; x < 27; x += 5) b.rect(x, 18, 1, 4, TIMD);
  b.rect(3, 21, 24, 1, TIMD);
  // crates and pots on the counter
  b.rect(3, 10, 6, 6, TIML); b.rect(3, 10, 6, 1, '#a6703f'); b.line(3, 11, 8, 15, TIMD, 1); b.line(8, 11, 3, 15, TIMD, 1);
  b.rect(3, 15, 6, 1, TIMD);
  b.ell(21.5, 13, 2.2, 2.8, POT); b.rect(20, 10, 3, 1, POT); b.rect(20, 10, 3, 1, POTL); b.px(21, 10, POTD); b.px(22, 14, POTD);
  b.ell(25, 14, 1.8, 1.7, POT); b.rect(24, 12, 3, 1, POTL); b.px(24, 14, POTL); b.px(26, 15, POTD);
  // the balance
  b.px(14, 9, CORD); b.px(14, 10, CORD); b.rect(11, 11, 7, 1, CU); b.px(14, 11, CUH); b.px(10, 11, CUD); b.px(18, 11, CUD);
  b.px(11, 12, CORD); b.px(17, 12, CORD); b.px(11, 13, CORD); b.px(17, 13, CORD);
  b.rect(10, 14, 3, 1, CU); b.rect(16, 14, 3, 1, CU); b.px(10, 14, CUL); b.px(16, 14, CUL);
  b.px(11, 15, CLOTH); b.px(17, 15, CUH);
  // the awning, striped, wider at the bottom, with a scalloped hem
  for (r = 0; r < 7; r++) {
    x0 = 3 - Math.round(r * 3 / 6); x1 = 26 + Math.round(r * 3 / 6);
    for (x = x0; x <= x1; x++) {
      c = Math.floor(x / 3) % 2 == 0;
      b.px(x, 1 + r, r == 6 ? (c ? CLOTHD : REDD) : (c ? CLOTH : RED));
      if (r == 0) b.px(x, 1, c ? '#ffffff' : '#d9665e');
    }
  }
  for (x = 0; x < 30; x++) if (x % 3 == 1) b.px(x, 8, Math.floor(x / 3) % 2 == 0 ? CLOTHD : REDD);
  b.rect(0, 0, 30, 1, TIMD); b.rect(2, 0, 26, 1, TIM);
}
// The site, 24x12: posts and a crossbeam, half the awning hung, planks and folded cloth on the ground.
function tradesite(b) {
  var x, r;
  b.rect(1, 3, 2, 9, TIM); b.rect(21, 3, 2, 9, TIM); b.rect(4, 0, 2, 8, TIM); b.rect(18, 0, 2, 8, TIM);
  b.rect(1, 3, 22, 1, TIML); b.rect(4, 0, 16, 1, TIML);
  for (r = 0; r < 3; r++) for (x = 4; x <= 13 + r; x++) b.px(x, 1 + r, Math.floor(x / 3) % 2 == 0 ? CLOTH : RED);
  for (x = 14; x < 20; x += 2) b.rect(x, 1, 1, 3, TIMD);
  b.rect(8, 9, 8, 1, TIML); b.rect(9, 8, 6, 1, '#a6703f'); b.rect(8, 10, 8, 1, TIMD);
  b.rect(16, 8, 4, 3, CLOTH); b.rect(16, 9, 4, 1, RED); b.rect(16, 10, 4, 1, CLOTHD);
}

// ---- the mud-brick house (camp slot of the Hut, 34x24) ---------------------------------------------
// A brick-and-plaster house with a flat roof, a room on the roof, a plank door and two windows.
function mudhouse(b) {
  var x;
  bricks(b, 2, 10, 30, 14, MB);
  b.rect(1, 6, 32, 1, MBL); b.rect(1, 7, 32, 2, MB[0]); b.rect(1, 9, 32, 1, MBM);
  bricks(b, 21, 1, 10, 5, MB); b.rect(20, 0, 12, 1, MBL);
  b.rect(25, 2, 2, 3, DARK); b.rect(25, 2, 2, 1, TIM);
  for (x = 5; x < 32; x += 6) { b.rect(x, 10, 2, 2, TIMD); b.px(x, 10, TIM); }
  b.rect(2, 19, 6, 5, PLAS); b.rect(2, 19, 4, 1, MB[0]); b.px(7, 19, MB[1]); b.px(8, 21, MB[1]); b.rect(2, 20, 6, 1, '#d8c394');
  b.rect(24, 20, 7, 4, PLAS); b.px(24, 20, MB[2]); b.px(30, 20, MB[0]); b.rect(24, 21, 7, 1, '#d8c394');
  b.rect(13, 14, 8, 1, TIM); b.rect(14, 15, 6, 9, TIMD); b.rect(15, 16, 4, 8, TIML);
  b.rect(16, 16, 1, 8, TIMD); b.rect(15, 16, 4, 1, '#a6703f'); b.px(18, 20, CUH); b.px(18, 21, CU);
  b.rect(13, 15, 1, 9, TIM); b.rect(20, 15, 1, 9, TIM); b.rect(13, 23, 8, 1, MBD);
  b.rect(5, 13, 6, 1, TIML); b.rect(6, 14, 4, 4, DARK); b.rect(5, 14, 1, 4, TIM); b.rect(10, 14, 1, 4, TIM);
  b.rect(8, 14, 1, 4, TIM); b.rect(5, 18, 6, 1, MBL);
  b.rect(23, 14, 4, 1, TIML); b.rect(24, 15, 2, 3, DARK); b.rect(23, 18, 4, 1, MBL);
}
// The site, 24x12: the low walls of a house half raised round a timber door frame.
function mudsite(b) {
  bricks(b, 3, 3, 18, 3, MB); b.rect(3, 3, 18, 1, MBL);
  bricks(b, 1, 6, 9, 6, MB); b.rect(1, 6, 9, 1, MBL);
  bricks(b, 15, 9, 8, 3, MB); b.rect(15, 9, 8, 1, MBL);
  b.rect(10, 2, 1, 10, TIM); b.rect(14, 2, 1, 10, TIM); b.rect(10, 2, 5, 1, TIML);
  b.rect(11, 8, 3, 4, '#7a5a3a');
  b.px(22, 6, EMBER); b.rect(22, 7, 1, 4, TIM);
}

// ---- boats (the Settled boats' slots in the river's far lane) -------------------------------------
// A planked boat, 26x11: a curved hull of strakes with copper bands at prow and stern, a mast stub
// and two oars.
function plankboat(b) {
  var y, hw = [12.5, 12.5, 11.5, 10, 8, 5.5, 3], cs = [WOODL, WOOD, '#7a4c28', WOOD, '#7a4c28', WOOD, TIM], x;
  for (y = 0; y < 7; y++) for (x = 0; x < 26; x++) if (Math.abs(x - 12.5) <= hw[y]) b.px(x, 2 + y, cs[y]);
  b.rect(0, 0, 2, 3, WOODL); b.px(0, 0, CUL); b.px(1, 0, CU); b.rect(24, 0, 2, 3, WOODL); b.px(25, 0, CUL); b.px(24, 0, CU);
  b.px(0, 2, WOOD); b.px(25, 2, WOOD);
  b.rect(3, 2, 1, 2, CU); b.rect(22, 2, 1, 2, CU);
  for (x = 7; x < 20; x += 4) b.px(x, 2, CUH);
  b.rect(12, 0, 1, 2, TIML); b.px(12, 0, CU);
  b.line(7, 3, 1, 8, '#e2b878', 1); b.rect(0, 8, 3, 2, CU); b.px(0, 8, CUL); b.px(7, 2, CU);
  b.line(19, 3, 25, 8, '#e2b878', 1); b.rect(23, 8, 3, 2, CU); b.px(25, 8, CUL); b.px(19, 2, CU);
  b.rect(0, 10, 26, 1, WATERL); b.rect(5, 9, 17, 1, WATER);
}
// A reed ship, 26x11: bundles of reed lashed in a curved hull with raised tips and a small square sail.
function reedship(b) {
  var x, y, cs = ['#d9c868', '#c9b24a', '#a8923a'];
  for (y = 0; y < 4; y++) for (x = 1; x < 25; x++) {
    if (y == 3 && (x < 4 || x > 21)) continue;
    if (y == 2 && (x < 2 || x > 23)) continue;
    b.px(x, 6 + y, cs[y == 0 ? 0 : (y == 1 ? 1 : 2)]);
  }
  b.rect(1, 6, 24, 1, '#e6d878');
  for (x = 4; x < 22; x += 4) b.rect(x, 6, 1, 4, '#8a5a36');
  b.rect(0, 4, 2, 3, '#c9b24a'); b.px(0, 3, '#d9c868'); b.px(1, 3, '#a8923a');
  b.rect(24, 3, 2, 4, '#c9b24a'); b.px(25, 2, '#d9c868'); b.px(24, 2, '#a8923a'); b.px(25, 1, '#a8923a');
  b.rect(12, 0, 1, 7, WOOD); b.rect(7, 0, 11, 1, WOODL);
  b.rect(8, 1, 9, 5, CLOTH); b.rect(8, 3, 9, 1, RED); b.rect(14, 1, 3, 5, CLOTHD); b.px(14, 3, REDD); b.px(15, 3, REDD); b.px(16, 3, REDD);
  b.rect(12, 1, 1, 5, WOOD);
  b.rect(0, 10, 26, 1, WATERL); b.rect(4, 9, 18, 1, WATER);
}

// ---- west page: small houses, the potters' yard, the weavers' row, the wall -------------------------
// A small mud-brick house, 26x19, with a flat roof, a jar on it, a door and a window.
function smallhouse(b) {
  var x;
  b.rect(2, 4, 22, 1, MBL); b.rect(2, 5, 22, 2, MB[0]); b.rect(2, 7, 22, 1, MBM);
  bricks(b, 3, 8, 20, 11, MB);
  for (x = 5; x < 22; x += 6) { b.rect(x, 8, 2, 2, TIMD); b.px(x, 8, TIM); }
  b.rect(9, 11, 7, 1, TIM); b.rect(10, 12, 5, 7, TIMD); b.rect(11, 13, 3, 6, TIML); b.px(13, 16, CUH);
  b.rect(9, 12, 1, 7, TIM); b.rect(15, 12, 1, 7, TIM);
  b.rect(17, 12, 3, 1, TIML); b.rect(17, 13, 3, 3, DARK); b.rect(17, 16, 3, 1, MBL);
  b.rect(4, 15, 4, 4, PLAS); b.px(7, 15, MB[1]); b.rect(4, 16, 4, 1, '#d8c394');
  b.rect(15, 0, 7, 1, MBL); bricks(b, 15, 1, 7, 3, MB); b.rect(17, 2, 3, 2, DARK);
}

// The potters' yard, 44x28: a dome kiln with smoke, a row of fired pots on a low shelf, a tray of
// clay pots drying under it and a heap of wet clay.
function potteryard(b) {
  var x, y, dx, dy, inside;
  for (y = 9; y < 27; y++) for (x = 24; x < 44; x++) {
    dx = (x - 33.5) / 9.5; dy = (y - 19) / 8;
    inside = y >= 19 ? Math.abs(dx) <= 1 : (dx * dx + dy * dy <= 1);
    if (!inside) continue;
    if (y % 3 == 0) b.px(x, y, CLAYD);
    else if ((x + (y % 2) * 3) % 6 == 0) b.px(x, y, CLAYD);
    else b.px(x, y, (dx < -0.25 && dy < -0.1) ? CLAYL : (dx > 0.6 ? '#b06a45' : CLAY));
  }
  b.rect(24, 26, 20, 1, CLAYD);
  b.rect(30, 8, 7, 3, CLAYD); b.rect(30, 8, 7, 1, CLAYL); b.rect(31, 8, 5, 1, DARK);
  b.ell(34, 21.5, 3.5, 2.5, DARK); b.rect(30.5, 22, 7, 5, DARK);
  b.rect(32, 24, 4, 3, EMBER); b.rect(33, 25, 2, 2, GLOW); b.px(33, 26, GLOWL); b.px(34, 26, GLOWL);
  b.ell(33, 5.5, 1.8, 1.4, SMOKE); b.ell(34.5, 3.2, 2, 1.5, SMOKEL); b.ell(33.5, 1, 1.6, 1.1, '#eef0f3');
  // the shelf, the pots, the tray
  b.rect(2, 17, 2, 10, TIM); b.rect(19, 17, 2, 10, TIM); b.rect(1, 17, 21, 2, TIML); b.rect(1, 17, 21, 1, '#a6703f'); b.rect(1, 19, 21, 1, TIMD);
  b.ell(3.5, 13.5, 2.9, 3.3, POT); b.rect(2, 9, 3, 2, POT); b.rect(2, 9, 3, 1, POTL); b.px(3, 10, DARK); b.px(2, 13, POTL); b.rect(1, 14, 6, 1, POTD);
  b.rect(8, 14, 5, 1, '#7fd8bd'); b.rect(8, 15, 5, 2, PAT); b.rect(9, 16, 3, 1, PATD); b.px(8, 15, '#7fd8bd');
  b.ell(15.5, 13.5, 2, 3, POT); b.rect(15, 10, 2, 2, POT); b.rect(14, 9, 4, 1, POTL); b.px(14, 13, POTL); b.px(16, 15, POTD);
  b.rect(19, 14, 3, 3, '#d9a070'); b.rect(19, 14, 3, 1, '#ecc090'); b.px(20, 15, DARK); b.px(21, 16, '#b88050');
  b.rect(4, 26, 14, 1, TIML); b.rect(4, 27, 14, 1, TIMD); b.rect(4, 25, 1, 1, TIM); b.rect(17, 25, 1, 1, TIM);
  b.rect(6, 23, 3, 2, '#d9a070'); b.rect(6, 23, 3, 1, '#ecc090'); b.rect(11, 22, 2, 3, '#d9a070'); b.rect(11, 22, 2, 1, '#ecc090'); b.rect(14, 24, 3, 1, '#d9a070');
  b.px(8, 24, '#b88050'); b.px(12, 24, '#b88050'); b.px(16, 24, '#b88050');
  // the heap of wet clay and a spade
  b.ell(25, 25, 3.8, 2.6, '#a8623f'); b.ell(24, 24, 2.6, 1.4, '#c98660'); b.px(27, 26, '#7a3f28'); b.px(23, 26, '#7a3f28'); b.  px(26, 24, '#7a3f28');
  }

// Cloth pieces' place on the line (x of the left edge); the dyed overlay uses the middle one
var CLOTHX = [24, 33, 42];
function cordy(x) { return x <= 38 ? 5 + Math.round((x - 23) / 15 * 2) : 7 - Math.round((x - 38) / 15 * 2); }
// The weavers' row, 64x23: an upright loom, a line of undyed cloth between two posts and a sheaf of flax.
function weavers(b, dyed) {
  var i, x, k, top, hgt, band, fill, shade, fr;
  if (!dyed) {
    b.rect(1, 5, 2, 17, WOOD); b.rect(14, 5, 2, 17, WOOD); b.rect(1, 6, 15, 2, WOODL); b.rect(1, 18, 15, 2, WOODL);
    for (x = 4; x < 14; x += 2) b.rect(x, 8, 1, 10, CLOTH);
    b.rect(3, 13, 11, 2, RED); b.rect(3, 15, 11, 1, '#e8c24a'); b.rect(3, 12, 11, 1, REDD);
    for (x = 4; x < 14; x += 2) { b.px(x, 20, '#8a8792'); b.px(x, 21, '#6f6c78'); }
    b.rect(21, 4, 2, 18, WOOD); b.rect(50, 4, 2, 18, WOOD); b.rect(21, 4, 1, 18, WOODL); b.rect(50, 4, 1, 18, WOODL);
    b.line(23, 5, 38, 7, CORD, 1); b.line(38, 7, 49, 5, CORD, 1);
    for (k = 0; k < 9; k++) {
      b.line(55 + k, 22, 59 + Math.round((k - 4) * 0.6), 11 + Math.abs(k - 4), k % 3 == 0 ? '#ecd878' : (k % 3 == 1 ? '#d9c050' : '#c9b24a'), 1);
    }
    b.rect(56, 17, 7, 1, '#8a5a36'); b.px(57, 18, '#8a5a36'); b.px(61, 18, '#8a5a36');
    b.px(58, 11, '#6f9fd8'); b.px(60, 12, '#6f9fd8'); b.px(59, 10, '#9fc0ea');
  }
  for (i = 0; i < 3; i++) {
    if (dyed && i != 1) continue;
    x = CLOTHX[i]; top = cordy(x + 3) + 1; hgt = [10, 9, 10][i];
    fill = dyed ? RED : CLOTH; shade = dyed ? REDD : CLOTHD; band = dyed ? '#e8c24a' : (i == 0 ? '#a8763e' : '#c9b08a');
    b.rect(x, top, 7, hgt, fill); b.rect(x + 5, top, 2, hgt, shade);
    b.rect(x, top + 3, 7, 1, band);
    if (i == 2) b.rect(x, top + 6, 7, 1, band);
    for (k = 0; k < 7; k++) b.px(x + k, top + hgt, k % 2 ? fill : shade);
  }
}
function weaversrow(b) { weavers(b, false); }
function weaversdyed(b) { weavers(b, true); }

// The town wall, 325x24 (page-local x 59..383, y 40..63): a crenellated mud-brick wall along the back lane
// from the forest's edge (a stout end pier on the left) to the cave's flank (a squat corner tower on the
// right), with buttresses, and a gate tower at x 203..231 rising to y 40 over an open timber-framed arch you
// can see through. Drawn with page coordinates through a shifted view of the buffer.
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
function townwall(b) {
  var T = shifted(b, 59, 40), x, i, c, segs = [[59, 202], [232, 383]], bt = [75, 107, 139, 171, 249, 281, 313, 345];
  segs.forEach(function (s) {
    var w = s[1] - s[0] + 1, mx;
    bricks(T, s[0], 54, w, 10, MB);
    T.rect(s[0], 54, w, 1, MBL); T.rect(s[0], 63, w, 1, MBD);
    for (mx = 61; mx <= 379; mx += 8) if (mx >= s[0] && mx + 3 <= s[1]) { T.rect(mx, 52, 4, 2, MB[mx % 3 == 0 ? 0 : 2]); T.rect(mx, 52, 4, 1, MBL); }
  });
  for (i = 0; i < bt.length; i++) {
    c = bt[i];
    T.rect(c - 2, 51, 5, 13, MB[0]); bricks(T, c - 2, 53, 5, 10, MB); T.rect(c - 2, 52, 1, 11, MBL); T.rect(c + 2, 52, 1, 11, MBD);
    T.rect(c - 3, 51, 7, 1, MBL); T.rect(c - 3, 52, 7, 1, MBM); T.rect(c - 3, 63, 7, 1, MBD);
  }
  // the end pier against the forest
  bricks(T, 59, 47, 8, 17, MB); T.rect(59, 46, 8, 1, MBL); T.rect(59, 47, 8, 1, MBM); T.rect(59, 63, 8, 1, MBD);
  T.rect(59, 48, 1, 15, MBL); T.rect(65, 48, 2, 15, MBD); T.rect(60, 44, 2, 2, MB[2]); T.rect(63, 44, 3, 2, MB[0]); T.rect(60, 44, 2, 1, MBL); T.rect(63, 44, 3, 1, MBL);
  // the squat corner tower against the cliff
  bricks(T, 372, 47, 12, 17, MB); T.rect(372, 46, 12, 1, MBL); T.rect(372, 47, 12, 1, MBM); T.rect(372, 63, 12, 1, MBD);
  for (x = 373; x < 383; x += 5) { T.rect(x, 44, 3, 2, MB[1]); T.rect(x, 44, 3, 1, MBL); }
  T.rect(372, 48, 2, 15, MBL); T.rect(380, 48, 4, 15, MBD); T.rect(377, 52, 1, 3, DARK); T.rect(377, 52, 1, 1, TIM);
  T.rect(381, 58, 3, 6, MBM); T.rect(382, 60, 2, 4, MBD);
  // the gate tower
  bricks(T, 203, 42, 29, 22, MB); T.rect(203, 42, 29, 1, MBM); T.rect(203, 63, 29, 1, MBD);
  for (x = 203; x <= 227; x += 6) { T.rect(x, 40, 4, 2, MB[1]); T.rect(x, 40, 4, 1, MBL); }
  T.rect(203, 43, 2, 20, MBL); T.rect(229, 43, 3, 20, MBD);
  T.rect(203, 47, 29, 1, MBL); T.rect(203, 48, 29, 1, MBM);
  for (x = 206; x < 230; x += 6) { T.rect(x, 48, 2, 2, TIMD); T.rect(x, 48, 1, 1, TIM); }
  T.rect(216, 43, 2, 4, DARK); T.rect(215, 42, 4, 1, TIML); T.rect(207, 44, 1, 3, DARK); T.rect(227, 44, 1, 3, DARK);
  // the open arch: cleared so the lane shows through, framed in timber with bronze studs
  T.clear(212, 52, 11, 12);
  T.rect(209, 50, 17, 1, TIML); T.rect(209, 51, 17, 1, TIM);
  T.rect(210, 52, 2, 12, TIML); T.rect(223, 52, 2, 12, TIM); T.rect(210, 52, 1, 12, '#a6703f');
  T.rect(212, 52, 2, 1, TIM); T.rect(221, 52, 2, 1, TIM); T.rect(212, 53, 1, 1, TIM); T.rect(222, 53, 1, 1, TIM);
  T.rect(211, 56, 1, 1, CUH); T.rect(211, 60, 1, 1, CUH); T.rect(223, 56, 1, 1, CU); T.rect(223, 60, 1, 1, CU);
  T.rect(210, 62, 2, 1, CU); T.rect(223, 62, 2, 1, CU);
}
// ---- east page: a ship on the horizon -----------------------------------------------------------
// A trading ship, 18x16: dark hull with a copper rim and one square sail, to sit over the sea.
function sailship(b) {
  var x;
  b.rect(9, 1, 1, 11, TIMD);
  b.rect(4, 1, 11, 8, CLOTH); b.rect(13, 1, 2, 8, CLOTHD); b.rect(4, 4, 11, 2, RED); b.rect(13, 4, 2, 2, REDD);
  b.rect(3, 0, 13, 1, WOOD); b.rect(3, 9, 13, 1, WOOD); b.rect(9, 1, 1, 8, TIM);
  b.rect(1, 11, 16, 1, CU); b.rect(1, 12, 16, 1, WOOD); b.rect(2, 13, 14, 1, '#7a4c28'); b.rect(4, 14, 10, 1, TIM); b.rect(6, 15, 6, 1, TIMD);
  b.rect(0, 10, 1, 3, WOOD); b.px(0, 10, CUL); b.rect(17, 9, 1, 4, WOOD); b.px(17, 9, CUL);
  for (x = 4; x < 15; x += 4) b.px(x, 12, CUH);
}

// ---- the market (west page, 38x17) ----------------------------------------------------------------
// Two timber stalls under striped awnings (red and cream, ochre and cream) with crates, baskets,
// pots and a hanging balance, and a crate and a basket on the ground between them.
function awning(b, x, w, ca, cb, cad, cbd) {
  var r, xx, ins, c;
  b.rect(x + 1, 0, w - 2, 1, TIMD);
  for (r = 0; r < 5; r++) {
    ins = r < 2 ? 2 : (r < 4 ? 1 : 0);
    for (xx = x + ins; xx < x + w - ins; xx++) { c = Math.floor((xx - x) / 2) % 2 == 0; b.px(xx, 1 + r, c ? ca : cb); }
  }
  for (xx = x; xx < x + w; xx++) if ((xx - x) % 2 == 0) b.px(xx, 6, Math.floor((xx - x) / 2) % 2 == 0 ? cad : cbd);
}
function stall(b, sx, which) {
  var x;
  b.rect(sx + 2, 7, 13, 6, '#4a3a30');
  b.rect(sx, 1, 2, 16, TIM); b.rect(sx, 1, 1, 16, TIML); b.rect(sx + 15, 1, 2, 16, TIM); b.rect(sx + 15, 1, 1, 16, TIML);
  b.rect(sx, 13, 17, 1, '#a6703f'); b.rect(sx, 14, 17, 3, TIM); b.rect(sx, 16, 17, 1, TIMD);
  for (x = 4; x < 16; x += 4) b.rect(sx + x, 14, 1, 2, TIMD);
  if (which == 0) {
    awning(b, sx, 17, RED, CLOTH, REDD, CLOTHD);
    b.rect(sx + 2, 9, 4, 4, TIML); b.rect(sx + 2, 9, 4, 1, '#a6703f'); b.line(sx + 2, 10, sx + 5, 12, TIMD, 1); b.line(sx + 5, 10, sx + 2, 12, TIMD, 1);
    b.ell(sx + 8.5, 11.3, 2.2, 1.6, STRAW); b.rect(sx + 7, 10, 4, 1, STRAWL); b.px(sx + 8, 9, RED); b.px(sx + 9, 9, '#8fb843'); b.px(sx + 10, 12, STRAWD);
    b.px(sx + 12, 7, CORD); b.px(sx + 12, 8, CORD); b.rect(sx + 10, 9, 5, 1, CU); b.px(sx + 12, 9, CUH);
    b.px(sx + 10, 10, CORD); b.px(sx + 14, 10, CORD); b.rect(sx + 9, 11, 3, 1, CU); b.rect(sx + 13, 11, 3, 1, CU); b.px(sx + 14, 12, CLOTH);
  } else {
    awning(b, sx, 17, '#d99a3a', CLOTH, '#a8672a', CLOTHD);
    b.ell(sx + 4, 10.7, 2, 2.2, POT); b.rect(sx + 3, 8, 3, 1, POTL); b.px(sx + 3, 10, POTL); b.px(sx + 5, 12, POTD);
    b.ell(sx + 8.5, 11.4, 1.8, 1.5, POTL); b.rect(sx + 7, 10, 3, 1, '#f0a070'); b.px(sx + 9, 12, POTD);
    b.ell(sx + 12.5, 10.7, 2, 2.2, POT); b.rect(sx + 11, 8, 3, 1, POTL); b.px(sx + 14, 11, POTD); b.px(sx + 12, 12, POTD);
    b.px(sx + 3, 7, CORD); b.rect(sx + 3, 8, 1, 1, STRAWL); b.px(sx + 8, 7, CORD); b.px(sx + 8, 8, PAT); b.px(sx + 8, 9, PATD);
  }
}
function market(b) {
  stall(b, 0, 0); stall(b, 21, 1);
  b.rect(17, 13, 4, 4, TIML); b.rect(17, 13, 4, 1, '#a6703f'); b.line(17, 14, 20, 16, TIMD, 1); b.line(20, 14, 17, 16, TIMD, 1);
  b.ell(18.8, 11.6, 1.9, 1.3, STRAW); b.rect(17, 11, 4, 1, STRAWL); b.px(19, 10, RED);
}

// ---- the cart (west page, 24x15) --------------------------------------------------------------------
// A two-wheeled cart, the far wheel peeking out, with three sacks on the bed and the shafts resting on the ground.
function wheel(b, cx, cy, rim, fill, spoke, hub) {
  var x, y, d, k, a;
  for (y = cy - 5; y <= cy + 5; y++) for (x = cx - 5; x <= cx + 5; x++) {
    d = Math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
    if (d <= 4.6) b.px(x, y, d > 3.4 ? rim : fill);
  }
  for (k = 0; k < 4; k++) { a = k * Math.PI / 4; b.line(Math.round(cx - Math.cos(a) * 3), Math.round(cy - Math.sin(a) * 3), Math.round(cx + Math.cos(a) * 3), Math.round(cy + Math.sin(a) * 3), spoke, 1); }
  b.px(cx, cy, hub);
}
function cart(b) {
  b.line(15, 4, 22, 11, TIM, 1);
  wheel(b, 11, 10, TIM, '#32211a', TIM, CUD);
  b.rect(0, 3, 16, 1, '#a6703f'); b.rect(0, 4, 16, 2, TIML); b.rect(0, 6, 16, 1, TIMD);
  b.rect(0, 3, 1, 4, TIM); b.rect(5, 4, 1, 2, TIMD); b.rect(10, 4, 1, 2, TIMD); b.rect(15, 3, 1, 4, TIM);
  b.line(15, 6, 23, 14, WOODL, 1); b.line(15, 5, 22, 12, WOODL, 1); b.px(23, 14, TIMD);
  b.rect(1, 1, 5, 2, '#d8c8a0'); b.rect(2, 0, 3, 1, '#d8c8a0'); b.px(3, 0, TIMD); b.rect(1, 2, 5, 1, '#bda982'); b.px(4, 1, RED);
  b.rect(7, 1, 4, 2, '#bda982'); b.rect(8, 0, 2, 1, '#bda982'); b.px(9, 0, TIMD); b.rect(7, 2, 4, 1, '#a39070'); b.px(8, 1, STRAWL);
  b.rect(12, 1, 3, 2, '#e6d9b8'); b.rect(12, 0, 2, 1, '#e6d9b8'); b.px(13, 0, TIMD); b.rect(12, 2, 3, 1, '#c9b890'); b.px(14, 1, RED);
  wheel(b, 7, 10, WOODL, '#32211a', '#c58f50', CUH);
}

// ---- the donkeys (west page, 22x12) ------------------------------------------------------------------
// Two pack donkeys side by side facing right: grey, a red blanket and a sack on the back, a basket at the
// flank, a bell at the neck. Each is outlined on its own so the pair reads as two animals.
function donkey(b, body, light, dark) {
  var D = '#4a4150';
  b.px(8, 0, dark); b.px(10, 0, dark);
  b.rect(8, 1, 3, 3, body); b.rect(9, 3, 2, 2, '#d8c8b4'); b.px(9, 2, D); b.px(10, 4, D);
  b.rect(7, 2, 2, 3, body); b.px(7, 2, dark); b.px(7, 3, dark);
  b.rect(1, 3, 6, 4, body); b.rect(2, 6, 5, 1, light);
  b.rect(2, 1, 4, 2, CLOTH); b.rect(2, 2, 4, 1, CLOTHD); b.px(3, 1, TIMD);
  b.rect(2, 3, 4, 1, RED); b.rect(2, 4, 4, 1, REDD);
  b.rect(1, 5, 2, 2, STRAW); b.px(1, 6, STRAWD);
  b.rect(1, 7, 2, 3, body); b.rect(6, 7, 2, 3, body); b.px(1, 7, dark); b.px(7, 7, dark);
  b.rect(3, 7, 1, 2, dark); b.rect(5, 7, 1, 2, dark);
  b.rect(1, 9, 2, 1, D); b.rect(6, 9, 2, 1, D);
  b.px(0, 3, dark); b.px(0, 4, dark); b.px(0, 5, dark);
  b.px(7, 5, CUH); b.px(7, 4, REDD);
}
function donkeypair(b) {
  var rear = new Buf(11, 10), front = new Buf(11, 10);
  donkey(rear, '#857870', '#a79a8f', '#5f534d'); donkey(front, '#a39589', '#c4b8ac', '#74675f');
  blit(b, outlined(rear, OUT), 9, 0); blit(b, outlined(front, OUT), 0, 0);
}

// ---- the road (a flat backdrop strip, 4 rows, one piece per place it crosses) ---------------------------
// The road runs from the west edge to the bridge like the Classical street that replaces it (five
// pieces: road_market and road_west on the west page, road_hall, road_camp and road_bank on the
// camp page). A laid stone road: a pale curb along the top, two courses of flat paving stones with dark joints (the
// lower course offset), worn wheel ruts and a dark gutter along the bottom. The game draws it behind
// everything, so it runs under the buildings; it is pale against the grass and flat, with no outline.
function roadstrip(x0, x1) {
  var B = new Buf(W, H), x, y, st, len, k, c, rut, tones = { 77: ['#d6cfb9', '#e0d9c3', '#cdc6b0'], 78: ['#bdb6a0', '#c6bfa9', '#b3ac96'] };
  function inRut(px) { return (px % 96) >= 16 && (px % 96) < 62; }
  for (x = x0; x < x1; x++) {
    B.px(x, 76, (x % 9 == 4) ? '#bdb59d' : '#ebe5d0');
    B.px(x, 79, ((x * 5) % 11 < 2 ? '#8e9ea4' : '#6f6c60'));
  }
  for (y = 77; y <= 78; y++) {
    st = 0; x = x0 + (y == 78 ? 3 : 0);
    while (x < x1) {
      len = 5 + ((x * 7 + y * 3) % 3); k = ((x + y * 5) % 3);
      for (c = 0; c < len && x + c < x1; c++) {
        rut = y == 78 ? inRut(x + c) : ((x + c) % 96 >= 20 && (x + c) % 96 < 40) || ((x + c) % 96 >= 72 && (x + c) % 96 < 92);
        B.px(x + c, y, c == len - 1 ? (y == 77 ? '#7d7868' : '#6e6a5c') : (rut ? (y == 78 ? '#9d968c' : '#c2bba6') : tones[y][k]));
      }
      x += len;
    }
  }
  return B;
}
// ---- the farmers' steading (west page, 60x22) ---------------------------------------------------------
// One tidy piece for the farmers: a low timber-fenced plot of green rows with a scarecrow in a straw hat,
// a swung gate with three hens pecking beside it, a trough of water and a small haystack.
var EARTH = '#8a5a36', EARTHD = '#6f4528', LEAF = '#6fbf4a', LEAFL = '#9bdf6a', LEAFD = '#3f9a52', RAIL = '#8c5f31';
function bhen(b, x, y, col, shade) {
  b.ell(x + 3, y + 2, 2.8, 2.2, col); b.rect(x, y + 1, 2, 2, shade); b.px(x, y, shade);
  b.rect(x + 5, y + 2, 2, 2, col); b.px(x + 5, y + 1, '#d8483a'); b.px(x + 7, y + 3, '#e8b53a'); b.px(x + 6, y + 2, '#1c1917');
  b.px(x + 2, y + 5, '#e8b53a'); b.px(x + 4, y + 5, '#e8b53a');
}
function bscarecrow(b, ox) {
  b.rect(ox + 5, 5, 2, 13, WOOD); b.rect(ox, 7, 12, 2, WOOD);
  b.rect(ox + 3, 6, 6, 7, '#a8703f'); b.rect(ox + 3, 6, 6, 1, '#c58f50'); b.rect(ox + 3, 12, 6, 1, '#7a4c28');
  b.ell(ox + 6, 4, 2.6, 2.6, '#e8d5a8'); b.px(ox + 5, 4, '#1c1917'); b.px(ox + 7, 4, '#1c1917');
  b.rect(ox + 2, 2, 8, 1, STRAW); b.rect(ox + 4, 0, 4, 2, STRAW);
  b.px(ox, 9, STRAWL); b.px(ox + 11, 9, STRAWL); b.px(ox + 1, 10, STRAW); b.px(ox + 10, 10, STRAW);
}
function haystack(b, x, top, w, bottom) {
  var r, hw, cx = x + w / 2, xx;
  for (r = top; r <= bottom; r++) {
    hw = Math.min(w / 2, 1.5 + (r - top) * 0.62);
    for (xx = Math.ceil(cx - hw); xx < cx + hw; xx++) b.px(xx, r, xx < cx - hw * 0.35 ? STRAWL : (xx > cx + hw * 0.45 ? STRAWD : STRAW));
  }
  for (r = top + 3; r < bottom; r += 3) for (xx = x + 1; xx < x + w - 1; xx += 4) if (b.a(xx + (r % 2), r)) b.px(xx + (r % 2), r, STRAWD);
  b.px(Math.floor(cx), top - 1, STRAW); b.px(Math.floor(cx) + 1, top - 1, STRAWL);
}
function farmstead(b) {
  var x, r;
  b.rect(2, 9, 25, 10, EARTH);
  for (r = 0; r < 4; r++) {
    b.rect(2, 11 + r * 2, 25, 1, EARTHD);
    for (x = 3; x < 26; x += 3) { b.rect(x, 10 + r * 2, 2, 1, LEAF); b.px(x, 10 + r * 2, LEAFL); b.px(x + 1, 10 + r * 2, LEAFD); }
  }
  for (x = 1; x < 28; x += 6) b.rect(x, 7, 1, 5, WOOD);
  b.rect(1, 8, 26, 1, RAIL); b.rect(1, 7, 26, 1, WOODL);
  b.rect(1, 7, 1, 14, WOOD); b.px(1, 7, WOODL);
  for (x = 1; x < 26; x += 6) b.rect(x, 17, 1, 4, WOOD);
  b.rect(1, 18, 25, 1, '#a6703f'); b.rect(1, 20, 25, 1, EARTHD);
  bscarecrow(b, 8);
  b.rect(26, 11, 2, 10, WOOD); b.rect(26, 11, 2, 1, WOODL);
  b.line(28, 19, 31, 14, WOODL, 1); b.line(28, 16, 31, 12, WOODL, 1); b.line(31, 12, 31, 14, WOOD, 1);
  bhen(b, 30, 15, CLOTH, CLOTHD); bhen(b, 35, 16, '#c9803a', '#a05830'); bhen(b, 40, 15, '#8a5a36', '#6a4326');
  haystack(b, 49, 6, 11, 17);
  b.rect(46, 18, 11, 4, TIM); b.rect(46, 18, 11, 1, TIML); b.rect(47, 19, 9, 1, WATER); b.px(49, 19, WATERL); b.px(53, 19, WATERL);
  b.rect(46, 21, 11, 1, TIMD); b.rect(46, 18, 1, 4, TIML); b.rect(56, 18, 1, 4, TIMD);
}

// ---- the herders' steading (west page, 62x22) ---------------------------------------------------------
// One tidy piece for the herders: a woven-hurdle pen with three goats, a hay rick, a small fenced vegetable
// patch and a bucket.
function bgoat(b, x0, y0, fur, shade) {
  b.rect(x0 + 2, y0 + 2, 7, 3, fur); b.rect(x0 + 2, y0 + 4, 7, 1, shade);
  b.rect(x0 + 8, y0, 3, 3, fur); b.px(x0 + 10, y0 + 2, shade); b.px(x0 + 8, y0 - 1, '#6f6a60'); b.px(x0 + 9, y0 - 1, '#6f6a60');
  b.px(x0 + 9, y0 + 1, '#1c1917');
  b.rect(x0 + 2, y0 + 5, 1, 3, '#5a4a3a'); b.rect(x0 + 4, y0 + 5, 1, 3, '#5a4a3a');
  b.rect(x0 + 7, y0 + 5, 1, 3, '#5a4a3a'); b.rect(x0 + 8, y0 + 5, 1, 2, '#5a4a3a');
  b.px(x0 + 1, y0 + 2, shade);
}
function herdstead(b) {
  var x, y, r;
  b.ell(19, 15, 19.5, 5.6, '#b89a6a'); b.ell(19, 15, 16.5, 4.2, '#c9ad7d');
  for (y = 3; y < 9; y++) for (x = 0; x < 38; x++) b.px(x, y, ((x + (y % 2) * 2) % 4 < 2) ? '#d9a566' : '#8c5f31');
  for (x = 0; x < 38; x += 6) { b.rect(x, 2, 1, 8, WOOD); b.px(x, 2, WOODL); }
  b.rect(0, 9, 38, 1, EARTHD);
  bgoat(b, 3, 9, '#efe6cf', '#cdc0a0'); bgoat(b, 15, 11, '#8a5a36', '#6a4326'); bgoat(b, 26, 9, '#b4b1b9', '#8a8792');
  for (x = 0; x < 38; x += 9) b.rect(x, 17, 1, 4, WOOD);
  b.rect(0, 19, 38, 1, '#a6703f');
  // hay rick
  b.rect(41, 11, 10, 9, STRAW); b.ell(46, 11.5, 5, 3, STRAWL); b.rect(41, 14, 10, 1, STRAWD); b.rect(41, 17, 10, 1, STRAWD);
  b.rect(49, 12, 2, 8, STRAWD); b.rect(41, 12, 1, 8, STRAWL); b.px(44, 15, STRAWL); b.px(47, 18, STRAWL); b.px(45, 9, STRAWL); b.px(48, 10, STRAWL);
  b.rect(41, 20, 10, 1, STRAWD);
  // bucket
  b.rect(35, 19, 4, 3, TIML); b.rect(35, 19, 4, 1, WATERL); b.rect(36, 19, 2, 1, WATER); b.rect(35, 20, 4, 1, CU); b.rect(38, 19, 1, 3, TIMD); b.px(35, 18, CORD); b.px(38, 18, CORD);
  // vegetable patch
  b.rect(52, 13, 10, 8, EARTH);
  for (r = 0; r < 2; r++) for (x = 0; x < 3; x++) { b.ell(54 + x * 3 + r * 1.5, 15.5 + r * 3, 1.5, 1.3, LEAF); b.px(53 + x * 3 + r * 1.5, 15 + r * 3, LEAFL); b.px(55 + x * 3 + r * 1.5, 16 + r * 3, LEAFD); }
  b.rect(52, 13, 1, 9, WOOD); b.rect(61, 13, 1, 9, WOOD); b.rect(52, 12, 10, 1, WOODL); b.rect(52, 13, 10, 1, RAIL);
  b.rect(56, 13, 1, 3, WOOD); b.rect(52, 19, 10, 1, '#a6703f'); b.rect(52, 21, 10, 1, EARTHD);
}

// ---- the council ring and the tally post (west page, 44x16 and 44x19; the market's place, never together) ------
// The council ring, 44x16: a shallow oval of six seats (stone and log, the back ones higher and smaller, the
// front ones low and big, some with cream sheepskins), a bronze-bound round table in the middle, a tall pole
// with a red pennant behind it and a staff leaning on a seat.
function seat(b, x, y, w, stone, cushion) {
  if (stone) { b.rect(x, y, w, 3, '#a9a6b6'); b.rect(x, y, w, 1, '#dcd9e4'); b.rect(x, y + 2, w, 1, '#6f6c7c'); b.px(x + (w >> 1), y + 1, '#7f7c8c'); b.px(x + 1, y + 1, '#c4c1d0'); }
  else { b.rect(x, y, w, 3, '#b8742f'); b.rect(x, y, w, 1, '#e0a85a'); b.rect(x, y + 2, w, 1, '#7a4a22'); b.rect(x + w - 1, y, 1, 3, '#f0c878'); b.px(x + w - 1, y + 1, '#b8742f'); b.px(x + 2, y + 1, '#8a5428'); }
  if (cushion) { b.rect(x + 1, y - 1, w - 2, 1, '#f6ecd2'); b.px(x + 1, y - 1, '#d8c9a0'); b.px(x + w - 2, y - 1, '#d8c9a0'); }
  b.rect(x + 1, y + 3, w - 2, 1, '#6a4a22');
}
function councilring(b) {
  var x, y, d;
  for (y = 5; y < 16; y++) for (x = 0; x < 44; x++) {
    d = Math.pow((x - 21.5) / 21.5, 2) + Math.pow((y - 10.5) / 5.3, 2);
    if (d <= 1) b.px(x, y, d > 0.72 ? '#9a6a3a' : '#c9965a');
  }
  seat(b, 10, 5, 6, true, true); seat(b, 28, 5, 6, false, false);
  seat(b, 0, 8, 7, false, true); seat(b, 37, 8, 7, true, false);
  // the pole and its pennant, then the table
  b.rect(21, 1, 2, 9, '#a6703f'); b.rect(21, 1, 1, 9, '#e0a85a'); b.px(21, 0, CUH); b.px(22, 0, CU);
  b.rect(23, 0, 9, 1, '#e03a30'); b.rect(23, 1, 7, 1, '#e03a30'); b.rect(23, 2, 6, 1, '#f6ecd2'); b.rect(23, 3, 4, 1, '#e03a30'); b.rect(23, 4, 2, 1, '#b02a24');
  b.px(31, 1, '#b02a24'); b.px(29, 3, '#b02a24');
  b.rect(18, 10, 9, 3, '#a6703f'); b.rect(18, 10, 9, 1, '#c58f50'); b.rect(18, 12, 9, 1, CU); b.rect(19, 13, 7, 1, TIMD); b.px(20, 11, '#7a4c28'); b.px(24, 11, '#7a4c28');
  b.ell(22.5, 9.5, 5, 2.1, '#e0a85a'); b.ell(22, 9, 3.4, 1.2, '#f0c878'); b.rect(18, 10, 1, 1, CU); b.rect(26, 10, 1, 1, CU); b.px(21, 8, CUH); b.px(24, 9, CUH);
  seat(b, 9, 11, 9, false, true); seat(b, 27, 11, 9, true, true);
  // a staff with a bronze head leaning on the right-hand seat
  b.line(38, 14, 41, 3, '#e0a85a', 1); b.line(39, 14, 42, 3, '#b8742f', 1); b.rect(40, 1, 3, 2, CU); b.px(40, 1, CUH); b.px(41, 3, CORD); b.px(40, 7, CORD);
}
function tallypost(b) {
  var x, r, c, len = [7, 10, 5, 9, 8];
  b.rect(3, 1, 3, 17, TIM); b.rect(3, 1, 1, 17, TIML); b.rect(0, 3, 9, 2, TIML); b.rect(0, 3, 9, 1, '#a6703f'); b.px(0, 4, TIMD); b.px(8, 4, TIMD);
  b.rect(2, 16, 5, 2, ROCK); b.rect(2, 16, 5, 1, ROCKL);
  for (c = 0; c < 5; c++) {
    x = 1 + c * 2; b.rect(x, 5, 1, len[c], CORD);
    for (r = 7; r < 5 + len[c]; r += 3) b.px(x, r, '#a8763e');
    b.px(x, 5 + len[c], '#a8763e');
  }
  // a bench under a small thatched cover
  b.rect(12, 12, 28, 2, TIML); b.rect(12, 12, 28, 1, '#a6703f'); b.rect(14, 14, 2, 4, TIM); b.rect(36, 14, 2, 4, TIM); b.rect(12, 14, 28, 1, TIMD);
  b.rect(14, 5, 1, 7, TIM); b.rect(38, 5, 1, 7, TIM);
  for (r = 0; r < 4; r++) for (x = 12 - Math.round((3 - r) * 0.7); x < 41 + Math.round((3 - r) * 0.7); x++) b.px(x, 1 + r, (x + r) % 4 < 2 ? STRAW : STRAWD);
  b.rect(11, 5, 30, 1, STRAWL); for (x = 11; x < 41; x += 2) b.px(x, 6, STRAWD);
  b.rect(12, 0, 28, 1, STRAWL);
  // baked clay slabs in two neat stacks, and a basket of counting stones
  for (r = 0; r < 3; r++) { b.rect(17, 10 - r * 2, 9, 2, r % 2 ? '#d99466' : '#c96a42'); b.rect(17, 10 - r * 2, 9, 1, r % 2 ? '#e8a878' : POTL); b.px(19 + r, 11 - r * 2, POTD); b.px(23 - r, 11 - r * 2, POTD); }
  for (r = 0; r < 2; r++) { b.rect(27, 10 - r * 2, 7, 2, r % 2 ? '#c96a42' : '#d99466'); b.rect(27, 10 - r * 2, 7, 1, POTL); b.px(29 + r, 11 - r * 2, POTD); }
  b.ell(37, 9.6, 3, 2.2, STRAW); b.rect(34, 8, 6, 1, STRAWL); b.px(35, 7, ROCKL); b.px(37, 7, '#ffffff'); b.px(36, 6, ROCK); b.px(38, 7, ROCKL); b.px(39, 8, ROCK);
}
// ---- the quay (camp page, 40x13) --------------------------------------------------------------------
// A timber pier on piles running out into the river: a plank deck, two mooring posts, a coil of rope
// and a lantern post at the end.
function quay(b) {
  var x, i, pil = [3, 11, 19, 27, 35];
  b.ell(1.5, 10.8, 2.6, 2.1, ROCK); b.px(1, 10, ROCKL); b.px(2, 9, ROCKL); b.px(3, 12, ROCKD);
  for (i = 0; i < pil.length; i++) { x = pil[i]; b.rect(x, 9, 2, 4, TIM); b.rect(x, 9, 1, 4, TIML); b.px(x - 1, 12, WATERL); b.px(x + 2, 12, WATERL); }
  b.rect(3, 10, 34, 1, TIMD);
  b.rect(0, 6, 40, 1, '#c58f50'); b.rect(0, 7, 40, 1, '#a6703f'); b.rect(0, 8, 40, 1, WOOD); b.rect(0, 9, 40, 1, TIM);
  for (x = 5; x < 40; x += 6) { b.px(x, 6, TIMD); b.px(x, 7, TIMD); }
  for (x = 2; x < 40; x += 6) b.px(x, 6, TIML);
  b.rect(8, 3, 3, 4, TIM); b.rect(8, 3, 1, 4, TIML); b.rect(8, 3, 3, 1, TIML); b.rect(8, 4, 3, 1, CORD); b.px(10, 5, CORD);
  b.rect(28, 3, 3, 4, TIM); b.rect(28, 3, 1, 4, TIML); b.rect(28, 3, 3, 1, TIML); b.rect(28, 4, 3, 1, CORD); b.px(28, 5, CORD); b.px(27, 6, CORD);
  b.ell(16.5, 5, 2.7, 1.5, CORD); b.px(16, 5, TIMD); b.px(17, 5, TIMD); b.rect(14, 6, 6, 1, '#c9b890'); b.px(19, 4, '#c9b890');
  b.rect(37, 3, 1, 3, TIM); b.px(36, 3, TIML);
  b.rect(36, 0, 3, 1, CUD); b.rect(36, 1, 3, 2, GLOW); b.px(37, 1, GLOWL); b.px(37, 2, GLOWL);
}
// The site, 26x12: driven piles, the first planks laid, a few waiting to be nailed down.
function quaysite(b) {
  var x, i, pil = [1, 6, 11, 16, 21], tops = [6, 6, 6, 4, 3];
  for (i = 0; i < pil.length; i++) { x = pil[i]; b.rect(x, tops[i], 2, 12 - tops[i], TIM); b.rect(x, tops[i], 1, 12 - tops[i], TIML); b.px(x, tops[i], '#d9a566'); b.px(x - 1, 11, WATERL); b.px(x + 2, 11, WATERL); }
  b.rect(0, 5, 14, 1, '#c58f50'); b.rect(0, 6, 14, 1, '#a6703f'); b.rect(0, 7, 14, 1, WOOD); b.rect(0, 8, 14, 1, TIM);
  b.px(4, 5, TIMD); b.px(4, 6, TIMD); b.px(9, 5, TIMD); b.px(9, 6, TIMD);
  b.rect(0, 9, 14, 1, TIMD);
  b.rect(16, 4, 7, 1, TIML); b.rect(16, 5, 7, 1, TIMD);
  b.rect(7, 3, 5, 1, '#c58f50'); b.rect(8, 4, 5, 1, '#a6703f');
}
// ---- the quay's boats (camp page, 17x13 and 11x8) ---------------------------------------------------
// A planked boat with a small square sail furled on its yard, and a reed boat beside it, both tied up.
function quayplank(b) {
  var y, x, hw = [8, 8, 7, 5.5, 3.5], cs = [WOODL, WOOD, '#7a4c28', WOOD, TIM];
  for (y = 0; y < 5; y++) for (x = 0; x < 17; x++) if (Math.abs(x - 8) <= hw[y]) b.px(x, 7 + y, cs[y]);
  b.rect(0, 5, 2, 3, WOODL); b.px(0, 5, CUL); b.px(1, 5, CU); b.rect(15, 5, 2, 3, WOODL); b.px(16, 5, CUL); b.px(15, 5, CU);
  b.rect(3, 7, 1, 2, CU); b.rect(13, 7, 1, 2, CU); b.px(7, 7, CUH); b.px(10, 7, CUH);
  b.rect(6, 1, 1, 6, TIML); b.px(6, 0, CU);
  b.rect(2, 1, 9, 1, WOODL); b.rect(3, 2, 7, 2, CLOTH); b.rect(3, 3, 7, 1, CLOTHD); b.px(4, 2, RED); b.px(8, 2, RED); b.px(4, 3, REDD); b.px(8, 3, REDD);
  b.rect(0, 12, 17, 1, WATERL);
}
function quayreed(b) {
  var x, y, cs = ['#d9c868', '#c9b24a', '#a8923a'];
  for (y = 0; y < 3; y++) for (x = 1; x < 10; x++) { if (y == 2 && (x < 3 || x > 7)) continue; b.px(x, 3 + y, cs[y]); }
  b.rect(1, 3, 9, 1, '#e6d878');
  for (x = 3; x < 9; x += 3) b.rect(x, 3, 1, 3, '#8a5a36');
  b.rect(0, 2, 2, 2, '#c9b24a'); b.px(0, 1, '#d9c868'); b.px(1, 0, '#a8923a'); b.px(0, 0, '#a8923a');
  b.rect(9, 1, 2, 3, '#c9b24a'); b.px(10, 0, '#d9c868'); b.px(9, 0, '#a8923a');
  b.rect(1, 6, 9, 1, WATERL); b.rect(3, 7, 5, 1, WATER);
}
function quayboats(B) {
  var ob = [obj(11, 8, 376, 67, quayreed, { sh: 0, z: 70 }), obj(17, 13, 367, 72, quayplank, { sh: 0, z: 71 })];
  ob.forEach(function (o) { drawObj(B, o); });
}
// ---- the plank bridge (camp page and east page) -----------------------------------------------------
// A timber deck over the three gravel bars and the water between them, on the same span as the Cave
// Age crossing (x 302..476 in world x), with a low rope rail on the far side. One drawing, cut into
// the two pages so they meet at the seam.
var X0 = 302, X1 = 476, TOP = 70;
var BARS = [336, 388, 438];
function bar(b, cx) {
  var x = cx - X0;
  b.ell(x, 6.5, 11, 2.6, '#cdbd92'); b.ell(x - 1, 5.5, 8, 1.6, '#e2d3a6');
  b.px(x - 6, 7, '#a69773'); b.px(x + 2, 8, '#a69773'); b.px(x + 7, 7, '#a69773');
  b.px(x - 3, 6, ROCK); b.px(x + 4, 5, ROCKD); b.px(x + 8, 6, ROCK);
}
function plankdeck(b) {
  var g, x, xs, rx;
  for (g = 0; g < BARS.length; g++) bar(b, BARS[g]);
  for (x = 4; x < 172; x += 8) { // piles under the deck, every 8 px
    b.rect(x, 7, 2, 3, TIM); b.rect(x, 7, 1, 3, TIML); b.px(x - 1, 9, WATERL); b.px(x + 2, 9, WATERL);
  }
  for (x = 2; x <= 172; x++) {
    xs = Math.floor((x - 2) / 6);
    b.px(x, 4, xs % 2 ? '#a6703f' : '#b27b45'); b.px(x, 5, xs % 2 ? WOOD : '#94603a'); b.px(x, 6, TIM); b.px(x, 7, TIMD);
    if ((x - 2) % 6 == 0 && x > 2) { b.px(x, 4, TIMD); b.px(x, 5, TIMD); }
  }
  for (rx = 8; rx <= 168; rx += 20) { b.rect(rx, 1, 1, 3, TIML); b.px(rx, 1, '#d9a566'); }
  for (rx = 8; rx < 168; rx += 20) for (x = rx + 1; x < rx + 20 && x < 169; x++) b.px(x, 2 + ((x - rx) % 20 > 3 && (x - rx) % 20 < 17 ? 1 : 0), '#c9b890');
}
function plankbridge(pageX) {
  var tb = new Buf(X1 - X0 + 1, 10), B = new Buf(W, H);
  plankdeck(tb);
  blit(B, outlined(tb, OUT), X0 - 1 - pageX, TOP);
  return B;
}

// ---- the gate tower (camp page, replaces the Lookout in place; 28x31) --------------------------------
// A squat mud-brick tower in the town wall's brick and timber: merlons, a timber watch platform with a
// pennant on top, a timber gate arch with a bronze-shod door, and arrow slits.
function gatetower(b) {
  var x, i;
  bricks(b, 2, 14, 24, 17, MB);
  b.rect(2, 14, 2, 17, MBL); b.rect(24, 14, 2, 17, MBD); b.rect(2, 14, 1, 17, '#f0d9a8');
  b.rect(1, 11, 26, 1, MBL); b.rect(1, 12, 26, 2, MB[0]); b.rect(1, 14, 26, 1, MBM);
  for (x = 4; x < 26; x += 6) { b.rect(x, 12, 2, 2, TIMD); b.px(x, 12, TIM); }
  for (i = 0; i < 4; i++) { x = 2 + i * 6; b.rect(x, 9, 4, 2, MB[i % 2 ? 2 : 0]); b.rect(x, 9, 4, 1, MBL); }
  b.rect(3, 10, 22, 1, MBM);
  // a timber watch platform on the merlons: floor, open sides, a gabled roof, flagpole and pennant
  b.rect(8, 8, 12, 1, '#a6703f'); b.rect(9, 5, 10, 3, DARK); b.px(13, 7, '#4a3a30'); b.px(14, 6, '#4a3a30');
  b.rect(9, 5, 1, 3, TIM); b.rect(18, 5, 1, 3, TIM); b.rect(9, 7, 10, 1, TIML);
  b.rect(7, 4, 14, 1, TIML); b.rect(8, 3, 12, 1, TIM); b.rect(7, 4, 14, 1, '#a6703f');
  b.rect(14, 0, 1, 3, TIML); b.px(14, 0, CUH);
  b.rect(15, 0, 6, 1, RED); b.rect(15, 1, 4, 1, RED); b.rect(15, 2, 2, 1, REDD); b.px(19, 1, REDD); b.px(20, 0, REDD);
  // arrow slits and small windows
  b.rect(13, 16, 2, 4, DARK); b.rect(12, 15, 4, 1, TIML); b.rect(12, 20, 4, 1, MBL);
  b.rect(5, 18, 2, 3, DARK); b.rect(4, 17, 4, 1, TIML); b.rect(4, 21, 4, 1, MBL);
  b.rect(21, 18, 2, 3, DARK); b.rect(20, 17, 4, 1, TIML); b.rect(20, 21, 4, 1, MBL);
  // plinth, timber gate arch and a bronze-shod door
  b.rect(2, 29, 6, 2, MBD); b.rect(20, 29, 6, 2, MBD); b.rect(2, 30, 24, 1, MBD);
  b.rect(8, 22, 12, 9, DARK);
  b.rect(8, 21, 12, 1, TIML); b.rect(9, 20, 10, 1, TIM);
  b.rect(8, 22, 2, 9, TIM); b.rect(18, 22, 2, 9, TIM); b.rect(8, 22, 1, 9, TIML); b.px(10, 22, TIM); b.px(17, 22, TIM);
  b.rect(10, 23, 8, 7, TIML); b.rect(10, 23, 8, 1, '#a6703f');
  for (x = 12; x < 18; x += 2) b.rect(x, 24, 1, 6, TIMD);
  b.rect(10, 25, 8, 1, CU); b.rect(10, 28, 8, 1, CU);
  b.px(11, 25, CUH); b.px(16, 25, CUH); b.px(11, 28, CUH); b.px(16, 28, CUH); b.px(13, 26, CUL); b.px(14, 26, CUL); b.px(14, 27, CUD);
  b.rect(8, 30, 12, 1, MBD);
}// The site, 20x11: the low ring of the tower half laid, a timber door frame, a scaffold pole and bricks stacked.
function towersite(b) {
  bricks(b, 3, 6, 14, 5, MB); b.rect(3, 6, 14, 1, MBL);
  bricks(b, 3, 4, 5, 2, MB); b.rect(3, 4, 5, 1, MBL);
  bricks(b, 13, 5, 4, 1, MB);
  b.rect(8, 3, 1, 8, TIM); b.rect(12, 3, 1, 8, TIM); b.rect(8, 3, 5, 1, TIML); b.rect(9, 7, 3, 4, DARK);
  b.rect(1, 1, 1, 10, TIM); b.rect(1, 1, 1, 1, TIML); b.line(1, 4, 3, 4, CORD, 1);
  b.rect(18, 2, 1, 9, TIM); b.rect(18, 2, 1, 1, TIML); b.rect(16, 5, 3, 1, TIML);
  bricks(b, 14, 8, 4, 3, MB); b.rect(14, 8, 4, 1, MBL);
  b.px(18, 1, EMBER);
}

var layers = {};
layers.building_smithy = layerOf([obj(34, 24, 184, 79, smithy, { sh: 14 })]);
layers.site_smithy = layerOf([obj(24, 12, 184, 79, smithsite, { sh: 11 })]);
layers.building_trading_post = layerOf([obj(30, 22, 108, 79, tradingpost, { sh: 12 })]);
layers.site_trading_post = layerOf([obj(24, 12, 108, 79, tradesite, { sh: 10 })]);
layers.building_hut = layerOf([obj(34, 24, 268, 71, mudhouse, { sh: 14 })]);
layers.site_hut = layerOf([obj(24, 12, 268, 71, mudsite, { sh: 9 })]);
layers.boat_dugout = layerOf([obj(26, 11, 370, 70, plankboat, { sh: 0 })]);
layers.boat_raft = layerOf([obj(26, 11, 370, 70, reedship, { sh: 0 })]);
layers.west_roof_a = layerOf([obj(26, 19, 172, 72, smallhouse, { sh: 11 })]);
layers.west_roof_b = layerOf([obj(26, 19, 148, 71, smallhouse, { sh: 11, flip: 1 })]);
layers.potters_yard = layerOf([obj(44, 28, 226, 79, potteryard, { sh: 19 })]);
layers.weavers_row = layerOf([obj(64, 23, 100, 79, weaversrow, { sh: 0 })]);
layers.weavers_row_dyed = layerOf([obj(64, 23, 100, 79, weaversdyed, { sh: 0, raw: true, z: 80 })]);
layers.town_wall = layerOf([obj(325, 24, 221, 64, townwall, { sh: 0 })]);
layers.east_sail = layerOf([obj(18, 16, 305, 61, sailship, { sh: 0 })]);
layers.market_stalls = layerOf([obj(38, 17, 36, 70, market, { sh: 0, z: 72 })]);
layers.cart = layerOf([obj(24, 15, 15, 79, cart, { sh: 0 })]);
layers.donkeys = layerOf([obj(22, 12, 41, 80, donkeypair, { sh: 0, raw: true, z: 79 })]);
layers.road_market = roadstrip(0, 56);
layers.road_west = roadstrip(56, 384);
layers.road_hall = roadstrip(0, 88);
layers.road_camp = roadstrip(88, 264);
layers.road_bank = roadstrip(264, 304);
layers.farmstead_herd = layerOf([obj(62, 22, 280, 79, herdstead, { sh: 0, z: 78 })]);
layers.council_ring = layerOf([obj(44, 16, 32, 69, councilring, { sh: 0, z: 72 })]);
layers.tally_post = layerOf([obj(44, 19, 32, 72, tallypost, { sh: 0, z: 72 })]);
layers.building_quay = layerOf([obj(40, 13, 338, 72, quay, { sh: 0 })]);
layers.site_quay = layerOf([obj(26, 12, 338, 72, quaysite, { sh: 0 })]);
layers.quay_boats = new Buf(W, H); quayboats(layers.quay_boats);
layers.crossing_planks = plankbridge(0);
layers.east_crossing_planks = plankbridge(384);
layers.building_lookout = layerOf([obj(28, 31, 300, 68, gatetower, { sh: 0, z: 66 })]);
layers.site_lookout = layerOf([obj(20, 11, 300, 68, towersite, { sh: 0, z: 66 })]);

// previews: the camp pieces on a plain meadow and river, the west ones and the east one apart
var groups = [
  ['bronze_camp', ['town_wall', 'building_smithy', 'site_smithy', 'building_trading_post', 'site_trading_post', 'building_hut', 'site_hut', 'potters_yard', 'weavers_row', 'weavers_row_dyed', 'boat_dugout', 'boat_raft']],
  ['bronze_west', ['west_roof_a', 'west_roof_b']],
  ['bronze_east', ['east_sail']],
  ['bronze_trade_camp', ['road_camp', 'building_smithy', 'building_trading_post', 'town_wall', 'building_lookout', 'building_quay', 'crossing_planks', 'quay_boats'], 'river'],
  ['bronze_trade_sites', ['site_lookout', 'site_quay'], 'river'],
  ['bronze_trade_west', ['market_stalls', 'cart', 'donkeys', 'weavers_row', 'west_roof_b']],
  ['bronze_trade_east', ['east_crossing_planks'], 'eastriver'],
  ['bronze_farmsteads', ['town_wall', 'potters_yard', 'farmstead_herd']],
  ['bronze_council', ['council_ring']],
  ['bronze_tally', ['tally_post']]
], gi, gj, P, name, x, y;
for (gi = 0; gi < groups.length; gi++) {
  P = new Buf(W, H);
  for (y = 0; y < G; y++) for (x = 0; x < W; x++) P.px(x, y, '#9cc4de');
  for (y = G; y < H; y++) for (x = 0; x < W; x++) P.px(x, y, y < G + 13 ? '#86a94c' : '#789a43');
  if (gi == 0) for (y = 56; y < H; y++) for (x = 357; x < W; x++) P.px(x, y, y < 58 ? WATERL : WATER);
  if (groups[gi][2] == 'river') for (y = 62; y < H; y++) for (x = 302; x < W; x++) P.px(x, y, y < 64 ? WATERL : WATER);
  if (groups[gi][2] == 'eastriver') for (y = 62; y < H; y++) for (x = 0; x < 92; x++) P.px(x, y, y < 64 ? WATERL : WATER);
  if (gi == 2) for (y = 57; y < H; y++) for (x = 0; x < W; x++) P.px(x, y, y < 60 ? '#3b79ad' : '#2f6890');
  for (gj = 0; gj < groups[gi][1].length; gj++) blit(P, layers[groups[gi][1][gj]], 0, 0);
  IMG.putImageData(P.d); if (gi == 0) SPR.save(); else SPR.saveAs(DIR + 'art/reference/' + groups[gi][0] + '.png');
}
var count = 0;
for (name in layers) { IMG.putImageData(layers[name].d); SPR.saveAs(GAME + name + '.png'); count++; }
console.log('bronze camp done, ' + count + ' game layers');
