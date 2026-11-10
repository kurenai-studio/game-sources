// @open art/reference/ui_skin_bronze.png
// @canvas 384x192
// The Bronze Age panel skin (docs: ages V8), one atlas -> game/assets/ui/skin_bronze.png, laid out
// exactly like the Cave and Settled skins (ui_skin_hide.js, ui_skin_clay.js):
//   (0,0,384,160)            the panel: a hammered-bronze frame (riveted beams top and bottom, a
//                            post each side, a verdigris fleck) round a sun-baked mud-brick wall,
//                            a Greek-key band under the title and a bronze ingot
//   y=164: four 16x16 bronze-plate button states (normal, hover, pressed, disabled)
//          at x = 0, 16, 32, 48 (a 9-patch with 4 px margins)
//   y=164: the bronze rivet close button, 14x14, normal at x=64 and hover at x=78
//   y=164: 10x10 resource icons: wood (a log and a plank) at x=96, food (a haunch) at x=106
// The regions are mirrored in game/scripts/ui/panel_skin.gd. Keep the panel at the size of
// PanelHost (WIDTH x HEIGHT).
seed = 29;
var IMG = SPR.layer(0).cel(0).image;
var PW = 384, PH = 160;
var A = new Buf(384, 192);
var P = new Buf(PW, PH);
var x, y, i;

// ---- the mud-brick wall ---------------------------------------------------------------------
var BRICKS = ['#d9b27a', '#d3aa70', '#dfba84', '#d6ae76'], MORTAR = '#cca46c', MORTARD = '#b38a54';
var BR = '#c8832a', BRL = '#f0b94a', BRD = '#8f5a1c', BRG = '#e0a03a', BRK = '#6e4414';
var VERD = '#6aa890', VERDD = '#3f8470';
P.rect(0, 0, PW, PH, MORTAR);
var BW = 14, BH = 6, row = 0;
for (y = 0; y < PH; y += BH, row++) {
  for (x = -(row % 2) * (BW / 2); x < PW; x += BW) {
    P.rect(x + 1, y + 1, BW - 1, BH - 1, BRICKS[Math.floor(rnd() * BRICKS.length)]);
    if (rnd() < 0.18) { // a chip knocked out of a corner
      var cx = x + (rnd() < 0.5 ? 1 : BW - 2);
      P.px(cx, y + 1, MORTAR); P.px(cx, y + 2, MORTARD);
    }
  }
}
for (i = 0; i < 700; i++) P.px(Math.floor(rnd() * PW), Math.floor(rnd() * PH), rnd() < 0.5 ? '#c99f68' : '#e8c48e');
for (i = 0; i < 70; i++) { // chaff in the brick
  x = Math.floor(rnd() * PW); y = Math.floor(rnd() * PH);
  P.px(x, y, '#b88a50'); P.px(x + 1, y + (rnd() < 0.3 ? 1 : 0), '#b88a50');
}

// ---- the hammered-bronze frame --------------------------------------------------------------
function hammer(x0, y0, w, h) { // dimples from the hammer
  for (var k = 0; k < w * h / 14; k++) {
    var hx = x0 + Math.floor(rnd() * w), hy = y0 + Math.floor(rnd() * h);
    P.px(hx, hy, rnd() < 0.5 ? BRL : BRD);
  }
}
function rivet(cx, cy) {
  P.rect(cx - 1, cy - 1, 3, 3, BRD); P.rect(cx - 1, cy - 1, 2, 2, BRL); P.px(cx - 1, cy - 1, '#fff0b0');
}
function beam(y0) {
  P.rect(0, y0, PW, 7, BR);
  P.rect(0, y0 + 1, PW, 1, BRL); P.rect(0, y0 + 5, PW, 1, BRD);
  hammer(0, y0 + 2, PW, 3);
  P.rect(0, y0, PW, 1, OUT); P.rect(0, y0 + 6, PW, 1, OUT);
  for (var wx = 10; wx < PW - 10; wx++) { // a stamped wave between the rivets
    var wy = [0, 0, 1, 2, 2, 1][wx % 6];
    P.px(wx, y0 + 2 + wy, BRK);
  }
}
function post(x0) {
  P.rect(x0, 0, 6, PH, BR);
  P.rect(x0 + 1, 0, 1, PH, BRL); P.rect(x0 + 4, 0, 1, PH, BRD);
  hammer(x0 + 2, 0, 2, PH);
  P.rect(x0, 0, 1, PH, OUT); P.rect(x0 + 5, 0, 1, PH, OUT);
}
post(0); post(PW - 6);
beam(0); beam(PH - 7);
for (var rx = 2; rx < 4; rx++) for (var ry = 0; ry < 2; ry++) { // rivets at the corners and along the rails
  var rxs = [3, PW - 4], rys = [3, PH - 4];
  rivet(rxs[rx - 2], rys[ry]);
}
for (x = 64; x < PW - 40; x += 64) { rivet(x, 3); rivet(x, PH - 4); }
for (y = 40; y < PH - 20; y += 40) { rivet(3, y); rivet(PW - 4, y); }
// a verdigris bloom where the bronze has gone green
function verdigris(vx, vy, w, h) {
  for (var k = 0; k < w * h; k++) {
    var gx = vx + Math.floor(rnd() * w), gy = vy + Math.floor(rnd() * h);
    P.px(gx, gy, rnd() < 0.6 ? VERD : VERDD);
  }
}
verdigris(PW - 60, PH - 6, 6, 3); verdigris(2, 100, 3, 5); verdigris(150, 2, 5, 3);
// shadow where the wall meets the frame
for (x = 6; x < PW - 6; x++) { P.px(x, 7, MORTARD); P.px(x, PH - 8, '#c99f68'); }
for (y = 8; y < PH - 8; y++) { P.px(6, y, '#c99f68'); P.px(PW - 7, y, '#c99f68'); }
// the corners of the whole panel are cut, so it does not look like a screen
var corners = [[0, 0], [PW - 1, 0], [0, PH - 1], [PW - 1, PH - 1]];
for (i = 0; i < corners.length; i++) P.d[(corners[i][1] * PW + corners[i][0]) * 4 + 3] = 0;

// ---- an oxhide ingot near the close button ---------------------------------------------------
function ingot(hx, hy) {
  var g = new Buf(14, 9);
  g.rect(2, 1, 10, 7, BR); g.rect(0, 0, 3, 3, BR); g.rect(11, 0, 3, 3, BR);
  g.rect(0, 6, 3, 3, BR); g.rect(11, 6, 3, 3, BR);
  g.rect(3, 1, 8, 1, BRL); g.rect(0, 0, 3, 1, BRL); g.rect(11, 0, 3, 1, BRL);
  g.rect(3, 7, 8, 1, BRD); g.rect(0, 8, 3, 1, BRD); g.rect(11, 8, 3, 1, BRD);
  g.px(4, 3, '#fff0b0'); g.px(5, 3, BRL); g.px(5, 4, BRL);
  g.line(7, 4, 10, 4, BRD, 1); g.px(9, 5, BRD);
  g.px(2, 8, VERD); g.px(3, 8, VERDD); g.px(12, 0, VERD);
  blit(P, outlined(g, OUT), hx, hy);
}
ingot(PW - 55, 16);
// a Greek key under where the title sits
var KEY = ['#####.', '#...#.', '#.#.#.', '#.###.'];
for (x = 12; x < 108; x++) for (y = 0; y < 4; y++) {
  if (KEY[y].charAt(x % 6) == '#') P.px(x, 25 + y, x < 100 ? BRK : '#8f5a1c');
}
blit(A, P, 0, 0);

// ---- bronze-plate buttons -------------------------------------------------------------------
function plate(fill, hi, lo, stud, edge) {
  var b = new Buf(16, 16);
  b.rect(0, 0, 16, 16, edge); b.rect(1, 1, 14, 14, fill);
  b.rect(1, 1, 14, 1, hi); b.rect(1, 14, 14, 1, lo);
  b.px(1, 1, edge); b.px(14, 1, edge); b.px(1, 14, edge); b.px(14, 14, edge);
  b.px(3, 3, stud); b.px(12, 3, stud); b.px(3, 12, stud); b.px(12, 12, stud);
  b.px(2, 2, hi); b.px(13, 2, hi); b.px(2, 11, hi); b.px(13, 11, hi);
  return b;
}
blit(A, plate('#d9a23a', '#f5cf70', '#b07a24', '#8f5a1c', OUT), 0, 164);        // normal
blit(A, plate('#e8b64c', '#fbe08e', '#c58f32', '#8f5a1c', OUT), 16, 164);       // hover
blit(A, plate('#c48a2e', '#9a6a1f', '#d9a23a', '#6e4414', OUT), 32, 164);       // pressed
blit(A, plate('#b5ae94', '#c6c0a8', '#9d977e', '#8a8470', '#6a6f60'), 48, 164); // disabled

// ---- bronze rivet close button --------------------------------------------------------------
function closeBtn(hot) {
  var b = new Buf(12, 12);
  b.ell(6, 6, 5.5, 5.5, hot ? '#f2c455' : '#c98a2e');
  b.px(3, 3, hot ? '#fff0b0' : '#f0b94a'); b.px(4, 2, hot ? '#fff0b0' : '#f0b94a');
  b.line(3, 3, 8, 8, hot ? '#4a2a0a' : '#3a2418', 1); b.line(8, 3, 3, 8, hot ? '#4a2a0a' : '#3a2418', 1);
  return outlined(b, OUT);
}
blit(A, closeBtn(false), 64, 164); blit(A, closeBtn(true), 78, 164);

// ---- resource icons -------------------------------------------------------------------------
var wood = new Buf(8, 8);
wood.rect(0, 1, 7, 3, '#8a5a36'); wood.rect(0, 1, 7, 1, '#a6703f'); wood.rect(0, 3, 7, 1, '#6a4326');
wood.ell(6.5, 2.5, 1.5, 1.5, '#d9a566'); wood.px(6, 2, '#a6703f');
wood.rect(0, 5, 8, 2, '#c58f50'); wood.rect(0, 5, 8, 1, '#e0b070'); wood.px(2, 6, '#8a5a36'); wood.px(5, 6, '#8a5a36');
blit(A, outlined(wood, OUT), 96, 164);
var haunch = new Buf(8, 8);
haunch.rect(5, 4, 3, 1, '#efe6cf'); haunch.px(7, 3, '#efe6cf'); haunch.px(7, 5, '#efe6cf');
haunch.ell(3.5, 3.5, 3.4, 2.8, '#b4482e'); haunch.ell(3, 2.5, 1.8, 1.2, '#d9684a');
haunch.px(2, 5, '#8a3220'); haunch.px(4, 5, '#8a3220'); haunch.px(5, 3, '#8a3220');
blit(A, outlined(haunch, OUT), 106, 164);

IMG.putImageData(A.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/skin_bronze.png');
console.log('bronze skin done');
