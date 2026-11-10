// @open art/reference/ui_skin_clay.png
// @canvas 384x192
// The Settled Age panel skin (docs: ages V8), one atlas -> game/assets/ui/skin_clay.png, laid out
// exactly like the Cave skin's (ui_skin_hide.js):
//   (0,0,384,160)            the panel: a timber frame (pegged beams top and bottom, a post each
//                            side) round a plastered clay wall with flecks of straw, a woven
//                            zig-zag under the title and an ear of wheat
//   y=164: four 16x16 fired-clay tile button states (normal, hover, pressed, disabled)
//          at x = 0, 16, 32, 48 (a 9-patch with 4 px margins)
//   y=164: the wooden peg close button, 14x14, normal at x=64 and hover at x=78
//   y=164: 10x10 resource icons: wood (planks) at x=96, food (a loaf) at x=106
// The regions are mirrored in game/scripts/ui/panel_skin.gd. Keep the panel at the size of
// PanelHost (WIDTH x HEIGHT).
seed = 23;
var IMG = SPR.layer(0).cel(0).image;
var PW = 384, PH = 160;
var A = new Buf(384, 192);
var P = new Buf(PW, PH);
var x, y, i;

// ---- the plastered wall ---------------------------------------------------------------------
var CLAY = '#dcb48a', TIMB = '#8a5a36', TIMBL = '#a6703f', TIMBD = '#6a4326', GRAIN = '#7a4e2e';
var PEG = '#d9a566', RED = '#8a3a22', GOLD = '#d9a43a', STEM = '#6a7a3a';
P.rect(0, 0, PW, PH, CLAY);
for (i = 0; i < 80; i++) P.ell(Math.floor(rnd() * PW), Math.floor(rnd() * PH), 4 + rnd() * 10, 2 + rnd() * 4, rnd() < 0.5 ? '#d6ab80' : '#e2bb92');
for (i = 0; i < 640; i++) P.px(Math.floor(rnd() * PW), Math.floor(rnd() * PH), rnd() < 0.5 ? '#c99f74' : '#ecc9a2');
for (i = 0; i < 90; i++) { // straw in the daub
  x = Math.floor(rnd() * PW); y = Math.floor(rnd() * PH);
  var len = 2 + Math.floor(rnd() * 3);
  for (var s = 0; s < len; s++) P.px(x + s, y + (rnd() < 0.2 ? 1 : 0), rnd() < 0.5 ? '#c4975a' : '#b88a4c');
}
// ---- the timber frame -----------------------------------------------------------------------
function beam(y0) {
  P.rect(0, y0, PW, 7, TIMB);
  P.rect(0, y0 + 1, PW, 1, TIMBL); P.rect(0, y0 + 5, PW, 1, TIMBD);
  P.rect(0, y0, PW, 1, OUT); P.rect(0, y0 + 6, PW, 1, OUT);
  for (var gx = 8; gx < PW - 8; gx += 11 + Math.floor(rnd() * 16)) P.rect(gx, y0 + 3, 3 + Math.floor(rnd() * 4), 1, GRAIN);
  for (var side = 0; side < 2; side++) { // a wooden peg through each end
    var px0 = side == 0 ? 12 : PW - 13;
    P.rect(px0 - 1, y0 + 2, 3, 3, TIMBD); P.px(px0, y0 + 3, PEG);
  }
}
function post(x0) {
  P.rect(x0, 0, 6, PH, TIMB);
  P.rect(x0 + 1, 0, 1, PH, TIMBL); P.rect(x0 + 4, 0, 1, PH, TIMBD);
  P.rect(x0, 0, 1, PH, OUT); P.rect(x0 + 5, 0, 1, PH, OUT);
  for (var gy = 10; gy < PH - 10; gy += 13 + Math.floor(rnd() * 14)) P.rect(x0 + 2, gy, 1, 3 + Math.floor(rnd() * 4), GRAIN);
}
post(0); post(PW - 6);
beam(0); beam(PH - 7);
// shadow where the wall meets the beams and posts
for (x = 6; x < PW - 6; x++) { P.px(x, 7, '#b88c62'); P.px(x, PH - 8, '#c99f74'); }
for (y = 8; y < PH - 8; y++) { P.px(6, y, '#c99f74'); P.px(PW - 7, y, '#c99f74'); }
// the corners of the whole panel are cut, so it does not look like a screen
var corners = [[0, 0], [PW - 1, 0], [0, PH - 1], [PW - 1, PH - 1]];
for (i = 0; i < corners.length; i++) P.d[(corners[i][1] * PW + corners[i][0]) * 4 + 3] = 0;

// ---- an ear of wheat near the close button ---------------------------------------------------
function wheat(hx, hy) {
  P.line(hx + 4, hy + 8, hx + 4, hy + 20, STEM, 1);
  P.line(hx + 4, hy + 16, hx + 1, hy + 13, STEM, 1); P.line(hx + 4, hy + 18, hx + 7, hy + 15, STEM, 1);
  for (var k = 0; k < 5; k++) {
    var gy = hy + 2 + k * 2;
    P.ell(hx + 2.5, gy + 1, 1.6, 1.3, k % 2 ? '#c4902a' : GOLD);
    P.ell(hx + 5.5, gy + 1, 1.6, 1.3, k % 2 ? GOLD : '#c4902a');
  }
  P.ell(hx + 4, hy, 1.3, 1.8, GOLD);
  P.line(hx + 3, hy - 1, hx + 1, hy - 5, '#b88a4c', 1); P.line(hx + 5, hy - 1, hx + 7, hy - 5, '#b88a4c', 1);
}
wheat(PW - 52, 16);
// a woven zig-zag under where the title sits
for (x = 12; x < 110; x++) P.px(x, 24 + (Math.floor(x / 3) % 2), x < 100 ? RED : '#b05a3a');
blit(A, P, 0, 0);

// ---- fired-clay tile buttons ----------------------------------------------------------------
function tile(fill, hi, lo, incised, edge) {
  var b = new Buf(16, 16);
  b.rect(0, 0, 16, 16, edge); b.rect(1, 1, 14, 14, fill);
  b.rect(1, 1, 14, 1, hi); b.rect(1, 14, 14, 1, lo);
  for (var s = 4; s < 12; s += 2) { b.px(s, 3, incised); b.px(s, 12, incised); b.px(3, s, incised); b.px(12, s, incised); }
  b.px(3, 3, incised); b.px(12, 3, incised); b.px(3, 12, incised); b.px(12, 12, incised);
  return b;
}
blit(A, tile('#d98a5c', '#e8a678', '#b8683c', '#a85a34', OUT), 0, 164);        // normal
blit(A, tile('#ea9c6c', '#f7bc8c', '#c97a4c', '#a85a34', OUT), 16, 164);       // hover
blit(A, tile('#c4764a', '#a85a34', '#d98a5c', '#7a3a20', OUT), 32, 164);       // pressed
blit(A, tile('#d6c3a6', '#e0d0b6', '#c0ac8e', '#b4a084', '#8a7f6a'), 48, 164); // disabled

// ---- wooden peg close button ----------------------------------------------------------------
function closeBtn(hot) {
  var b = new Buf(12, 12);
  b.ell(6, 6, 5.5, 5.5, hot ? '#d9a566' : '#b07a46'); b.px(3, 3, hot ? '#f0c890' : '#d09a60');
  b.line(3, 3, 8, 8, hot ? '#fff3dc' : '#3a2418', 1); b.line(8, 3, 3, 8, hot ? '#fff3dc' : '#3a2418', 1);
  return outlined(b, OUT);
}
blit(A, closeBtn(false), 64, 164); blit(A, closeBtn(true), 78, 164);

// ---- resource icons -------------------------------------------------------------------------
var planks = new Buf(8, 8);
planks.rect(0, 1, 8, 2, '#a6703f'); planks.rect(0, 1, 8, 1, '#c58f50');
planks.rect(0, 3, 8, 2, '#8a5a36'); planks.rect(0, 3, 8, 1, '#a6703f');
planks.rect(0, 5, 8, 2, '#a6703f'); planks.rect(0, 5, 8, 1, '#c58f50');
planks.px(2, 2, '#6a4326'); planks.px(5, 4, '#6a4326'); planks.px(3, 6, '#6a4326');
blit(A, outlined(planks, OUT), 96, 164);
var loaf = new Buf(8, 8);
loaf.ell(4, 4.5, 3.8, 2.6, '#d9a45a'); loaf.rect(1, 5, 6, 1, '#b87a3a');
loaf.line(2, 3, 3, 2, '#f0cf8a', 1); loaf.px(4, 3, '#b87a3a'); loaf.px(5, 4, '#b87a3a');
blit(A, outlined(loaf, OUT), 106, 164);

IMG.putImageData(A.d); SPR.save();
SPR.saveAs(DIR + 'game/assets/ui/skin_clay.png');
console.log('clay skin done');
